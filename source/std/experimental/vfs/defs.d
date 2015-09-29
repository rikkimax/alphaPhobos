/**
 * The definitions of file system interfaces
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.vfs.defs;
import std.uri;
import std.range.interfaces : InputRange;
import std.range.primitives : isOutputRange, ElementType;
import std.datetime : SysTime;
import std.experimental.allocator : IAllocator;
import std.experimental.internal.dummyRefCount;

/**
 * The VFS central interface.
 * Provides the general interfacing to a group of file system providers.
 */
interface IFileSystem {
    /**
     * Adds a file system provider that the file system can look at for files/directories.
     *
     * Params:
     *        provider    =    The provider to add
     */
    void attachProvider(IFileSystemProvider provider);

    /**
     * Removes a file system provider that the file system can look at for files/directories.
     *
     * Params:
     *        provider    =    The provider to remove
     */
    void detachProvider(IFileSystemProvider);

    @property {
        /**
         * All the file system providers currently attached.
         *
         * Some entries may be null. Should not be modified directly.
         * Do not keep it around for long.
         *
         * Returns:
         *        An array of all the providers currently supported.
         */
        immutable(IFileSystemProvider[]) providers();

        /**
         * All currently attached locations
         *
         * Some entries may be null. Should not be modified directly.
         * Do not keep it around for long.
         *
         * Returns:
         *        An array of all the current mounted locations.
         */
        immutable(URIAddress[]) mountedPaths();
    }

    /**
     * Gets a file system entry
     *
     * Params:
     *         path    =    The path that the entry is at
     *
     * Returns:
     *        The file system entry or null if none
     */
    IFileSystemEntry opIndex(URIAddress path);

    /// May leak memory.
    final IFileSystemEntry opIndex(string path) {
        return opIndex(URIAddress(path, allocator));
    }

    /**
     * Gets a file system entry and will mount if possible
     *
     * Params:
     *        mountTo    =    The path to mount to
     *         path    =    The path that the entry is at
     *
     * Returns:
     *        The file system entry or null if none
     */
    IFileSystemEntry opSlice(URIAddress mountTo, URIAddress path);

    /// May leak memory.
    final IFileSystemEntry opSlice(string mountTo, string path) {
        return opSlice(URIAddress(mountTo, allocator), URIAddress(path, allocator));
    }

    /// May leak memory.
    final IFileSystemEntry opSlice(URIAddress mountTo, string path) {
        return opSlice(mountTo, URIAddress(path, allocator));
    }

    /// May leak memory.
    final IFileSystemEntry opSlice(string mountTo, URIAddress path) {
        return opSlice(URIAddress(mountTo, allocator), path);
    }

    /**
     * Unmounts an existing mount if possible
     *
     * If unknown for the full path, it will not do it.
     * Will not perform a glob
     *
     * Params:
     *         path    =    The path that the mount is at
     */
    void unmount(URIAddress path);

    /**
     * Creates a file in the file system
     *
     * It should be created either at the first available provider or at the preferred one
     *
     * Params:
     *         path    =    The path that the entry is at
     *
     * Returns:
     *        The file system entry or null if failed
     */
    IFileEntry createFile(URIAddress path);

    /// May leak memory.
    final IFileEntry createFile(string path) {
        return createFile(URIAddress(path, allocator));
    }
    
    /**
     * Creates a directory in the file system
     *
     * It should be created either at the first available provider or at the preferred one
     *
     * Params:
     *         path    =    The path that the entry is at
     *
     * Returns:
     *        The file system entry or null if failed
     */
    IDirectoryEntry createDirectory(URIAddress path);

    /// May leak memory.
    final IDirectoryEntry createDirectory(string path) {
        return createDirectory(URIAddress(path, allocator));
    }

    /**
     * Finds files and directories that match a glob pattern
     *
     * Params:
     *      baseDir =   Base location for glob to operate on
     *         glob    =    The glob pattern
     *        del     =    Delegate to call with the entry
     */
    void find(URIAddress baseDir, string glob, void delegate(IFileSystemEntry) del, bool caseSensitive=true);

    /// May leak memory.
    final void find(string baseDir, string glob, void delegate(IFileSystemEntry) del, bool caseSensitive=true) {
        find(URIAddress(baseDir, allocator), glob, del, caseSensitive);
    }

    /**
     * Removes files and directories that match a glob pattern
     *
     * Params:
     *      baseDir =   Base location for glob to operate on
     *         glob    =    The glob pattern
     *        del     =    Delegate to call with the entry
     */
    void remove(URIAddress baseDir, string glob, bool caseSensitive=true);

    /// May leak memory.
    final void remove(string baseDir, string glob, bool caseSensitive=true) {
        remove(URIAddress(baseDir, allocator), glob, caseSensitive);
    }

    /**
     * The allocator that this file system is using
     *
     * Returns:
     *         The allocator this file system manager is using
     */
    @property IAllocator allocator();
}

/**
 * Finds files and directories that match a glob pattern
 * Uses an output range instead of a delegate to output to
 *
 * Params:
 *        fs        =    The file system to search in
 *         glob    =    The glob pattern
 *        output     =    Output range to call with the entry
 */
void find(FS, OR)(FS fs, string glob, OR output, bool caseSensitive=true) if (
        (is(FS : IFileSystem) || is(FS : IFileSystemProvider) || is(FS : IDirectoryEntry)) &&
        isOutputRange!OR && is(ElementType!OR : IFileSystemProvider)) {
    fs.find(glob, &output.put, caseSensitive);
}

///
interface IFileSystemProvider {
    //this(string homeDirectory=null, string cwd=null, IAllocator allocator=theAllocator)

    /**
     * Retrives a mount
     *
     * May create connections so can be quite expensive in nature
     *
     * Params:
     *         path    =    The path that the entry is at
     *
     * Returns:
     *        The file system entry or null if failed
     */
    IFileSystemEntry mount(URIAddress path, IFileSystemEntry from=null);

    /// May leak memory.
    final IFileSystemEntry mount(string path, IFileSystemEntry from=null) {
        return mount(URIAddress(path, allocator), from);
    }

    /**
     * Creates a file in the file system
     *
     * Params:
     *         path    =    The path that the entry is at
     *
     * Returns:
     *        The file system entry or null if failed
     */
    IFileEntry createFile(URIAddress path);

    /// May leak memory.
    final IFileEntry createFile(string path) {
        return createFile(URIAddress(path, allocator));
    }

    /**
     * Creates a directory in the file system
     *
     * Params:
     *         path    =    The path that the entry is at
     *
     * Returns:
     *        The file system entry or null if failed
     */
    IDirectoryEntry createDirectory(URIAddress path);

    /// May leak memory.
    final IDirectoryEntry createDirectory(string path) {
        return createDirectory(URIAddress(path, allocator));
    }

    /**
     * Finds files and directories that match a glob pattern
     *
     * Params:
     *      baseDir =   Base location for glob to operate on
     *      glob    =   The glob pattern
     *      del     =   Delegate to call with the entry
     */
    void find(URIAddress baseDir, string glob, void delegate(IFileSystemEntry) del, bool caseSensitive=true);
    
    /// May leak memory.
    final void find(string baseDir, string glob, void delegate(IFileSystemEntry) del, bool caseSensitive=true) {
        find(URIAddress(baseDir, allocator), glob, del, caseSensitive);
    }
    
    /**
     * Removes files and directories that match a glob pattern
     *
     * Params:
     *      baseDir =   Base location for glob to operate on
     *      glob    =   The glob pattern
     *      del     =   Delegate to call with the entry
     */
    void remove(URIAddress baseDir, string glob, bool caseSensitive=true);
    
    /// May leak memory.
    final void remove(string baseDir, string glob, bool caseSensitive=true) {
        remove(URIAddress(baseDir, allocator), glob, caseSensitive);
    }

    /**
     * The allocator that this file system provider is using along with its child objects
     *
     * Returns:
     *         The allocator this file system provider is using
     */
    @property {
        ///
        IAllocator allocator();
        ///
        URIAddress currentWorkingDirectory();
        ///
        URIAddress homeDirectory();
    }
}

///
enum FileSystemPermissions : ubyte {
    ///
    Unknown = 0,

    ///
    Read = 1 << 1,

    ///
    Write = 1 << 2,

    ///
    Execute = 1 << 4
}

///
interface IFileSystemEntry {
    @property {
        ///
        string name();

        /**
         * Performs an implicit rename.
         * May support moving based upon location
         */
        void name(URIAddress);

        /// May leak memory.
        final void name(string addr) {
            name(URIAddress(addr, provider.allocator));
        }

        ///
        URIAddress absolutePath();

        /// May not be supported
        ubyte permissions();

        /// May not be supported
        void permissions(ubyte);

        ///
        IFileSystemProvider provider();

        ///
        SysTime lastModified();

        ///
        bool remove();
    }
}

///
interface IFileEntry : IFileSystemEntry {
    @property {
        ///
        DummyRefCount!(ubyte[]) bytes();

        ///
        size_t size();
    }

    ///
    void write(ubyte[]);

    ///
    void append(ubyte[]);

    // TODO: memory mapped writing
}

///
interface IDirectoryEntry : IFileSystemEntry, IFileSystemProvider {
    /**
     * Finds files and directories that match a glob pattern
     *
     * Params:
     *      baseDir =   Base location for glob to operate on
     *      glob    =   The glob pattern
     *      del     =   Delegate to call with the entry
     */
    void find(URIAddress baseDir, string glob, void delegate(IFileSystemEntry) del, bool caseSensitive=true);
    
    /// May leak memory.
    final void find(string baseDir, string glob, void delegate(IFileSystemEntry) del, bool caseSensitive=true) {
        find(URIAddress(baseDir, allocator), glob, del, caseSensitive);
    }
    
    /**
     * Removes files and directories that match a glob pattern
     *
     * Params:
     *      baseDir =   Base location for glob to operate on
     *      glob    =   The glob pattern
     *      del     =   Delegate to call with the entry
     */
    void remove(URIAddress baseDir, string glob, bool caseSensitive=true);
    
    /// May leak memory.
    final void remove(string baseDir, string glob, bool caseSensitive=true) {
        remove(URIAddress(baseDir, allocator), glob, caseSensitive);
    }

    /**
     * Gets a file system entry
     *
     * Params:
     *         path    =    The path that the entry is at
     *
     * Returns:
     *        The file system entry or null if none
     */
    IFileSystemEntry opIndex(URIAddress path);

    ///
    final IFileSystemEntry opIndex(string path) {
        return opIndex(URIAddress(path, allocator));
    }
}