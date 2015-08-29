module std.experimental.vfs.providers.os;
import std.experimental.vfs.defs;
import std.uri;
import std.datetime : SysTime;
import std.experimental.allocator : theAllocator, IAllocator, makeArray, expandArray, shrinkArray, make, dispose;

final class OSFileSystemProvider : IFileSystemProvider {
    private {
        URIAddress homeAddress;
        URIAddress cwdAddress;
        IAllocator alloc;
    }

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

    this(URIAddress homeDirectory, URIAddress cwd, IAllocator allocator=theAllocator) {
        homeAddress = homeDirectory;
        cwdAddress = cwd;
        alloc = allocator;
    }

    IFileSystemEntry mount(URIAddress path, IFileSystemEntry from=null) {
        import std.file : exists, isFile, isDir;
        
        path = path.expand(homeAddress, cwdAddress);
        
        if (!exists(path))
            return null;
        else if (isFile(path))
            return alloc.make!OSFileEntry(this, path);
        else if (isDir(path))
            return alloc.make!OSDirectoryEntry(this, path);
        else
            return null;
    }

    IFileEntry createFile(URIAddress path) {
        import std.file : FileException, write, exists;
        path = path.expand(homeAddress, cwdAddress);

        IFileEntry ret;

        if (exists(path))
            return null;
        else {
            try {
                write(path, null);
                return alloc.make!OSFileEntry(this, path);
            } catch(FileException) {
                return null;
            }
        }
    }

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

    void remove(URIAddress baseDir, string glob, bool caseSensitive=true) {
        import std.file : dirEntries, SpanMode, isFile, isDir;
        import std.file : remove;

        baseDir = baseDir.expand(homeAddress, cwdAddress);

        foreach(file; dirEntries(baseDir, glob, SpanMode.depth)) {
			remove(file.name);
        }
    }

    @property {
        IAllocator allocator() { return alloc; }
        URIAddress currentWorkingDirectory() { return cwdAddress; }
        URIAddress homeDirectory() { return homeAddress; }
    }
}

final class OSFileEntry : IFileEntry {
    private {
        URIAddress path;
        OSFileSystemProvider provider_;

        string[] nameParts;
    }

    this(OSFileSystemProvider provider, URIAddress path) {
        this.provider_ = provider;
        this.path = path;
        nameParts = cast(string[])path.parts;
    }

    @property {
        string name() {
            return nameParts[$-1];
        }

        void name(URIAddress to) {
            import std.file : rename;

            to = path.sibling(to);
            path.rename(to);

            nameParts = cast(string[])to.parts;
            path.__dtor;
            path = to;
        }

        URIAddress absolutePath() { return path; }

        ubyte permissions() {
            import std.file : append, read;

            bool readable, writable;
            try {
                auto got = read(path, 0);
                readable = true;
            } catch (Exception) {
                readable = false;
            }

            try {
                append(path, null);
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

        void permissions(ubyte) {
            // does nothing which is ok, atleast for now
        }

        IFileSystemProvider provider() { return provider_; }

        SysTime lastModified() {
            import std.file : timeLastModified;
            return timeLastModified(path);
        }

        bool remove() {
            import std.file : remove;

            try {
                remove(path);
                return true;
            } catch(Exception) {
                return false;
            }
        }

        ByteArray bytes() {
            import std.file : getSize;
            import std.stdio : File;

            File f = File(path, "rb");

			ulong theSize = getSize(path);
			assert(theSize < size_t.max);

            ubyte[] buff = provider.allocator.makeArray!ubyte(cast(size_t)theSize);
            buff = f.rawRead(buff);

            f.close;
            return ByteArray(buff, provider.allocator);
        }
    }

    void write(ubyte[] buff) {
        import std.file : write;
        write(path, buff);
    }

    void append(ubyte[] buff) {
        import std.file : append;
        append(path, buff);
    }
}

final class OSDirectoryEntry : IDirectoryEntry {
    private {
        URIAddress path;
        OSFileSystemProvider provider_;
        
        string[] nameParts;
    }
    
    this(OSFileSystemProvider provider, URIAddress path) {
        this.provider_ = provider;
        this.path = path;
        nameParts = cast(string[])path.parts;
    }
    
    @property {
        string name() {
            return nameParts[$-1];
        }
        
        void name(URIAddress to) {
            import std.file : rename;
            
            to = path.sibling(to);
			to = to.expand(provider.homeDirectory, provider.currentWorkingDirectory);
            path.rename(to);
            
            path.__dtor;
            path = to;
        }
        
        URIAddress absolutePath() { return path; }
        
        ubyte permissions() {
            import std.file : append, read;
            
            bool readable, writable;
            try {
                auto got = read(path, 0);
                readable = true;
            } catch (Exception) {
                readable = false;
            }
            
            try {
                append(path, null);
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
        
        void permissions(ubyte) {
            // does nothing which is ok, atleast for now
        }
        
        IFileSystemProvider provider() { return provider_; }
        
        SysTime lastModified() {
            import std.file : timeLastModified;
            return timeLastModified(path);
        }
        
        bool remove() {
            import std.file : remove;
            
            try {
                remove(path);
                return true;
            } catch(Exception) {
                return false;
            }
        }

        IAllocator allocator() { return allocator; }
        URIAddress currentWorkingDirectory() { return provider.currentWorkingDirectory; }
        URIAddress homeDirectory() { return provider.homeDirectory; }
    }

    IFileSystemEntry opIndex(URIAddress path) {
        return provider_.mount(this.path.subPath(path));
    }
    
    IFileSystemEntry mount(URIAddress path, IFileSystemEntry from=null) {
        return provider_.mount(this.path.subPath(path), from);
    }

    IFileEntry createFile(URIAddress path) {
        return provider_.createFile(this.path.subPath(path));
    }

    IDirectoryEntry createDirectory(URIAddress path) {
        return provider_.createDirectory(this.path.subPath(path));
    }

    void find(URIAddress baseDir, string glob, void delegate(IFileSystemEntry) del, bool caseSensitive=true) {
        provider_.find(path.subPath(baseDir), glob, del, caseSensitive);
    }

    void remove(URIAddress baseDir, string glob, bool caseSensitive=true) {
        provider_.remove(path.subPath(baseDir), glob, caseSensitive);
    }
}