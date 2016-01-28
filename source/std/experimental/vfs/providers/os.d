/**
 * OS file system provider implementation
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.vfs.providers.os;
import std.experimental.vfs.defs;
import std.experimental.uri;
import std.datetime : SysTime;
import std.experimental.allocator : theAllocator, IAllocator, makeArray, expandArray, shrinkArray, make, dispose;
import std.experimental.memory.managed;

///
final class OSFileSystemProvider : IFileSystemProvider {
    private {
        URIAddress homeAddress;
        URIAddress cwdAddress;
        IAllocator alloc;
    }

    ///
    this(IAllocator allocator=theAllocator, string homeDirectory=null, string cwd=null) {
        import std.process : environment;
        import std.file : getcwd;

        if (homeDirectory is null)
            homeDirectory = environment.get("HOME");
        if (homeDirectory is null)
            assert(0);

        if (cwd is null)
            cwd = getcwd();
        if (cwd is null)
            assert(0);

        homeAddress = URIAddress(homeDirectory, allocator);
        cwdAddress = URIAddress(cwd, allocator);
        alloc = allocator;
    }

    ///
    this(URIAddress homeDirectory, URIAddress cwd, IAllocator allocator=theAllocator) {
        homeAddress = homeDirectory;
        cwdAddress = cwd;
        alloc = allocator;
    }

    ///
    IFileSystemEntry mount(URIAddress path, IFileSystemEntry from=null) {
        import std.file : exists, isFile, isDir;
        
        path = path.expand(homeAddress, cwdAddress);
        string pathS = path.rawPathSegments;

        if (!exists(pathS))
            return null;
        else if (isFile(pathS))
            return alloc.make!OSFileEntry(this, path);
        else if (isDir(pathS))
            return alloc.make!OSDirectoryEntry(this, path);
        else
            return null;
    }

    ///
    IFileEntry createFile(URIAddress path) {
        import std.file : FileException, write, exists;
        path = path.expand(homeAddress, cwdAddress);
        string pathS = path.rawPathSegments;

        if (exists(pathS))
            return null;
        else {
            try {
                IFileEntry ret = alloc.make!OSFileEntry(this, path);
                ret.write(null);
                return ret;
            } catch(FileException) {
                return null;
            }
        }
    }

    ///
    IDirectoryEntry createDirectory(URIAddress path) {
        import std.file : FileException, mkdirRecurse, exists;
        path = path.expand(homeAddress, cwdAddress);
        
        IDirectoryEntry ret;
        
        if (exists(path.value))
            return null;
        else {
            try {
                mkdirRecurse(path.value);
                return alloc.make!OSDirectoryEntry(this, path);
            } catch(FileException) {
                return null;
            }
        }
    }

    ///
    void find(URIAddress baseDir, string glob, void delegate(IFileSystemEntry) del, bool caseSensitive=true) {
        import std.file : dirEntries, SpanMode;
        baseDir = baseDir.expand(homeAddress, cwdAddress);

        foreach(file; dirEntries(baseDir, glob, SpanMode.depth)) {
            URIAddress path = URIAddress(file.name, allocator);

            if (file.isFile)
                del(alloc.make!OSFileEntry(this, path));
            else if (file.isDir)
                del(alloc.make!OSDirectoryEntry(this, path));
        }
    }

    ///
    void remove(URIAddress baseDir, string glob, bool caseSensitive=true) {
        import std.file : dirEntries, SpanMode, isFile, isDir;
        import std.file : remove;

        baseDir = baseDir.expand(homeAddress, cwdAddress);

        foreach(file; dirEntries(baseDir, glob, SpanMode.depth)) {
            remove(file.name);
        }
    }

    @property {
        ///
        IAllocator allocator() { return alloc; }
        ///
        URIAddress currentWorkingDirectory() { return cwdAddress; }
        ///
        URIAddress homeDirectory() { return homeAddress; }
    }
}

///
final class OSFileEntry : IFileEntry {
    private {
        import std.mmfile;

        URIAddress path;
        OSFileSystemProvider provider_;

        string[] namepathSegments;
        IAllocator alloc;
        MmFile mmfile;
    }

    // emplace requires access to constructor, so package not private grrr
    package(std) this(OSFileSystemProvider provider, URIAddress path) {
        this.provider_ = provider;
        this.path = path;
        this.alloc = provider.alloc;
        namepathSegments = cast(string[])path.pathSegments;
    }

    ~this() {
        if (mmfile !is null)
            alloc.dispose(mmfile);
    }

    @property {
        ///
        string name() {
            return namepathSegments[$-1];
        }

        ///
        void name(URIAddress to) {
            import std.file : rename;

            to = path.sibling(to);
            string toS = to.rawPathSegments;
            path.value.rename(toS);

            namepathSegments = cast(string[])to.pathSegments;
            path.__dtor;
            path = to;

            createMemoryMapped();
        }

        ///
        URIAddress absolutePath() { return path; }

        ///
        ubyte permissions() {
            import std.file : append, read;
            string pathS = path.rawPathSegments;

            bool readable, writable;
            try {
                auto got = read(pathS, 0);
                readable = true;
            } catch (Exception) {
                readable = false;
            }

            try {
                append(pathS, null);
                writable = true;
            } catch (Exception) {
                writable = false;
            }

            if (readable && writable)
                return FileSystemPermissions.Read | FileSystemPermissions.Write | FileSystemPermissions.Unknown;
            else if (readable)
                return FileSystemPermissions.Read | FileSystemPermissions.Unknown;
            else if (writable)
                return FileSystemPermissions.Write | FileSystemPermissions.Unknown;
            else
                return FileSystemPermissions.Unknown;
        }

        /// Not supported
        void permissions(ubyte) {
            // does nothing which is ok, atleast for now
        }

        ///
        IFileSystemProvider provider() { return provider_; }

        ///
        SysTime lastModified() {
            import std.file : timeLastModified;
            return timeLastModified(path.value);
        }

        ///
        bool remove() {
            import std.file : remove;
            string pathS = path.rawPathSegments;

            if (mmfile !is null)
                alloc.dispose(mmfile);

            try {
                remove(pathS);
                return true;
            } catch(Exception) {
                return false;
            }
        }

        ///
        managed!(ubyte[]) bytes() {
            if (mmfile !is null)
                return opSlice();

            import std.file : getSize;
            import std.stdio : File;

            string pathS = path.rawPathSegments;
            File f = File(pathS, "rb");

            ulong theSize = getSize(pathS);
            assert(theSize < size_t.max);

            ubyte[] buff = provider.allocator.makeArray!ubyte(cast(size_t)theSize);
            buff = f.rawRead(buff);

            f.close;
            return managed!(ubyte[])(buff, managers(), Ownership.Primary, provider.allocator);
        }

        ///
        size_t size() {
            if (mmfile !is null)
                return cast(size_t)mmfile.length;

            import std.file : getSize;
            string pathS = path.rawPathSegments;

            ulong v = getSize(pathS);
            assert(v < size_t.max);

            return cast(size_t)v;
        }
    }

    void write(ubyte[] buff) {
        import std.file : write;
        string pathS = path.rawPathSegments;

        if (mmfile !is null)
            alloc.dispose(mmfile);

        write(pathS, buff);
    }

    void append(ubyte[] buff) {
        import std.file : append;
        string pathS = path.rawPathSegments;

        if (mmfile !is null)
            alloc.dispose(mmfile);

        append(pathS, buff);
    }

    // memory mapping

    managed!(ubyte[]) opSlice() {
        if (mmfile is null)
            createMemoryMapped();
        return managed!(ubyte[])(cast(ubyte[])mmfile.opSlice(), managers!(ubyte[], ManagedNoDeallocation), Ownership.Secondary, alloc);
    }
    
    managed!(ubyte[]) opSlice(size_t i1, size_t i2) {
        if (mmfile is null)
            createMemoryMapped();
        return managed!(ubyte[])(cast(ubyte[])mmfile.opSlice(i1, i2), managers!(ubyte[], ManagedNoDeallocation), Ownership.Secondary, alloc);
    }
    
    ubyte opIndex(size_t i) {
        if (mmfile is null)
            createMemoryMapped();
        return mmfile.opIndex(i);
    }
    
    ubyte opIndexAssign(ubyte value, size_t i) {
        if (mmfile is null)
            createMemoryMapped();
        return mmfile.opIndexAssign(value, i);
    }

    private {
        void createMemoryMapped() {
            if (mmfile !is null)
                alloc.dispose(mmfile);
            string pathS = path.rawPathSegments;
            mmfile = alloc.make!MmFile(pathS, MmFile.Mode.readWrite, 0, null);
        }
    }
}

///
final class OSDirectoryEntry : IDirectoryEntry {
    private {
        URIAddress path;
        OSFileSystemProvider provider_;
        
        string[] nameParts;
    }

    // emplace requires access to constructor, so package not private grrr
    package(std) this(OSFileSystemProvider provider, URIAddress path) {
        this.provider_ = provider;
        this.path = path;
        nameParts = cast(string[])path.pathSegments;
    }
    
    @property {
        ///
        string name() {
            return nameParts[$-1];
        }

        ///
        void name(URIAddress to) {
            import std.file : rename;
            
            to = path.sibling(to);
            to = to.expand(provider.homeDirectory, provider.currentWorkingDirectory);

            string toS = to.rawPathSegments;
            path.value.rename(toS);
            
            path.__dtor;
            path = to;
        }

        ///
        URIAddress absolutePath() { return path; }

        /// Not supported
        ubyte permissions() {
            return FileSystemPermissions.Unknown;
        }

        /// Not supported
        void permissions(ubyte) {
            // does nothing which is ok, atleast for now
        }

        ///
        IFileSystemProvider provider() { return provider_; }

        ///
        SysTime lastModified() {
            import std.file : timeLastModified;
            return timeLastModified(path.value);
        }

        ///
        bool remove() {
            import std.file : remove;
            string pathS = path.rawPathSegments;

            try {
                remove(pathS);
                return true;
            } catch(Exception) {
                return false;
            }
        }

        ///
        IAllocator allocator() { return allocator; }

        ///
        URIAddress currentWorkingDirectory() { return provider.currentWorkingDirectory; }

        ///
        URIAddress homeDirectory() { return provider.homeDirectory; }
    }

    ///
    IFileSystemEntry opIndex(URIAddress path) {
        return provider_.mount(this.path.subPath(path));
    }

    ///
    IFileSystemEntry mount(URIAddress path, IFileSystemEntry from=null) {
        return provider_.mount(this.path.subPath(path), from);
    }

    ///
    IFileEntry createFile(URIAddress path) {
        return provider_.createFile(this.path.subPath(path));
    }

    ///
    IDirectoryEntry createDirectory(URIAddress path) {
        return provider_.createDirectory(this.path.subPath(path));
    }

    ///
    void find(URIAddress baseDir, string glob, void delegate(IFileSystemEntry) del, bool caseSensitive=true) {
        provider_.find(path.subPath(baseDir), glob, del, caseSensitive);
    }

    ///
    void remove(URIAddress baseDir, string glob, bool caseSensitive=true) {
        provider_.remove(path.subPath(baseDir), glob, caseSensitive);
    }
}
