/**
 * OS file system provider implementation
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.vfs.providers.os;
import std.experimental.vfs.defs;
import std.uri;
import std.datetime : SysTime;
import std.experimental.allocator : theAllocator, IAllocator, makeArray, expandArray, shrinkArray, make, dispose;
import std.experimental.internal.dummyRefCount;

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
        string pathS = URIEntries(path);

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
        string pathS = URIEntries(path);

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
        
        if (exists(path))
            return null;
        else {
            try {
                mkdirRecurse(path);
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
        URIAddress path;
        OSFileSystemProvider provider_;

        string[] nameParts;
    }

    // emplace requires access to constructor, so package not private grrr
    package(std) this(OSFileSystemProvider provider, URIAddress path) {
        this.provider_ = provider;
        this.path = path;
        nameParts = cast(string[])path.parts;
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
            string toS = URIEntries(to);
            path.rename(toS);

            nameParts = cast(string[])to.parts;
            path.__dtor;
            path = to;
        }

        ///
        URIAddress absolutePath() { return path; }

        ///
        ubyte permissions() {
            import std.file : append, read;
            string pathS = URIEntries(path);

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
            return timeLastModified(path);
        }

        ///
        bool remove() {
            import std.file : remove;
            string pathS = URIEntries(path);

            try {
                remove(pathS);
                return true;
            } catch(Exception) {
                return false;
            }
        }

        ///
        DummyRefCount!(ubyte[]) bytes() {
            import std.file : getSize;
            import std.stdio : File;

            string pathS = URIEntries(path);
            File f = File(pathS, "rb");

			ulong theSize = getSize(pathS);
			assert(theSize < size_t.max);

            ubyte[] buff = provider.allocator.makeArray!ubyte(cast(size_t)theSize);
            buff = f.rawRead(buff);

            f.close;
            return DummyRefCount!(ubyte[])(buff, provider.allocator);
        }

        ///
        size_t size() {
            import std.file : getSize;
            string pathS = URIEntries(path);
            return getSize(pathS);
        }
    }

    ///
    void write(ubyte[] buff) {
        import std.file : write;
        string pathS = URIEntries(path);
        write(pathS, buff);
    }

    ///
    void append(ubyte[] buff) {
        import std.file : append;
        string pathS = URIEntries(path);
        append(pathS, buff);
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
        nameParts = cast(string[])path.parts;
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

            string toS = URIEntries(to);
            path.rename(toS);
            
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
            return timeLastModified(path);
        }

        ///
        bool remove() {
            import std.file : remove;
            string pathS = URIEntries(path);

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