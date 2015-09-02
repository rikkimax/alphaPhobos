/**
 * Default implementation of a file system manager
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.vfs.filesystem;
import std.experimental.vfs.defs;
import std.uri;
import std.experimental.allocator : theAllocator, IAllocator, makeArray, expandArray;

alias FileSystem = final FileSystemImpl;

/**
 * Implements a commonly used file system manager
 */
class FileSystemImpl : IFileSystem {
	private {
		import std.experimental.internal.containers.map;
        import std.experimental.vfs.providers.os;

		IAllocator alloc;
		IFileSystemProvider[] providers_;
		AAMap!(URIAddress, IFileSystemEntry) mounted_;
	}

    ///
	this(IAllocator alloc = theAllocator()) {
		this.alloc = alloc;
		providers_ = alloc.makeArray!IFileSystemProvider(0);
		mounted_ = AAMap!(URIAddress, IFileSystemEntry)(alloc);
	}

    ///
	void attachProvider(IFileSystemProvider provider) {
		if (providers_.length > 0) {
			foreach(ref p; providers_) {
				if (p is null) {
					p = provider;
					return;
				}
			}
		}

		alloc.expandArray(providers_, 1);
		providers_[$-1] = provider;
	}

    ///
	void detachProvider(IFileSystemProvider provider) {
		foreach(ref p; providers_) {
			if (p == provider) {
				p = null;
				return;
			}
		}
	}

	@property {
        ///
		immutable(IFileSystemProvider[]) providers() {
			return cast(immutable)providers_;
		}

        ///
		immutable(URIAddress[]) mountedPaths() {
			return mounted_.__internalKeys();
		}
	}

    ///
	IFileSystemEntry opIndex(URIAddress path) {
        URIAddress childPath;
        path = URIAddress(URIEntries(path), alloc);
		IDirectoryEntry parent = locateTopMostDirectory(path, childPath, null);

        if (childPath == "/") {
            return parent;
        } else if (parent !is null) {
            return parent[childPath.parts[0]];
        } else {
            return null;
        }
	}

    ///
	IFileSystemEntry opSlice(URIAddress mountTo, URIAddress path) {
		IFileSystemEntry entry = opIndex(path);

		if (entry !is null) {
			mounted_[mountTo] = entry;
		}

		return entry;
	}

    ///
	void unmount(URIAddress path) {
		mounted_.remove(path);
	}

    ///
	IFileEntry createFile(URIAddress path) {
		URIAddress childPath = URIAddress("/", alloc);
		IDirectoryEntry parent = locateTopMostDirectory(path, childPath, null);

		if (parent is null) {
			if (childPath == "/") {
				assert(0);
			} else {
				foreach(provider; providers_) {
					IFileEntry entry = provider.createFile(path);
					if (entry !is null)
						return entry;
				}
			}
		} else {
			if (childPath == "/") {
				return null; // dir name == file name
			} else {
				return parent.createFile(childPath);
			}
		}

		return null;
	}

    ///
	IDirectoryEntry createDirectory(URIAddress path) {
		URIAddress childPath = URIAddress("/", alloc);
		IDirectoryEntry parent = locateTopMostDirectory(path, childPath, null);

		if (parent is null) {
			if (childPath == "/") {
				assert(0);
			} else {
				foreach(provider; providers_) {
					IDirectoryEntry entry = provider.createDirectory(path);
					if (entry !is null)
						return entry;
				}
			}
		} else {
			if (childPath == "/") {
				return null; // dir name == file name
			} else {
				return parent.createDirectory(childPath);
			}
		}

		return null;
	}

    ///
    void find(URIAddress baseDir, string glob, void delegate(IFileSystemEntry) del, bool caseSensitive=true) {
		// evaluate for mounts
		URIAddress dircon = baseDir.connectionInfo;
        string baseDirPath = URIEntries(dircon);

		foreach(addr, mount; mounted_) {
			import std.path : globMatch, CaseSensitive;
            string addrpath = URIEntries(addr);

            if (addr.connectionInfo == dircon) {


				// smb://anon@server/*
                /+if ((caseSensitive && globMatch!(CaseSensitive.yes)(addrpath, baseDirPath)) || (!caseSensitive && globMatch!(CaseSensitive.no)(addrpath, baseDirPath))) {
					del(mount);
				}+/

				// smb://anon@server/dir1
				// 		/dir2/*
				/+IDirectoryEntry dir;
				if ((dir = cast(IDirectoryEntry)mount) !is null) {
                    if (addrpath.length + 1 < baseDirPath.length && baseDirPath[0 .. addrpath.length] == addrpath && baseDirPath[addrpath.length] == '/') {
						dir.find(URIAddress(baseDirPath[addrpath.length + 1 .. $], alloc), glob, del, caseSensitive);
					}
				}+/
                // FIXME: sub glob paths, not supported right now
			}
		}

		foreach(provider; providers_) {
			provider.find(baseDir, glob, del);
		}
	}

    ///
    void remove(URIAddress baseDir, string glob, bool caseSensitive=true) {
        // evaluate for mounts
        URIAddress dircon = baseDir.connectionInfo;
        string baseDirPath = URIEntries(dircon);
        
        /+foreach(addr, mount; mounted_) {
            import std.path : globMatch, CaseSensitive;
            string addrpath = URIEntries(addr);

            if (addr.connectionInfo == dircon) {
                // smb://anon@server/*
                if ((caseSensitive && globMatch!(CaseSensitive.yes)(addrpath, baseDirPath)) || (!caseSensitive && globMatch!(CaseSensitive.no)(addrpath, baseDirPath))) {
                    mount.remove(); // FIXME: assert? if false
                }

                // smb://anon@server/dir1
                //      /dir2/*
                /+IDirectoryEntry dir;
                if ((dir = cast(IDirectoryEntry)mount) !is null) {
                    if (addrpath.length + 1 < baseDirPath.length && baseDirPath[0 .. addrpath.length] == addrpath && baseDirPath[addrpath.length] == '/') {
                        dir.remove(URIAddress(baseDirPath[addrpath.length + 1 .. $], alloc), glob, caseSensitive);
                    }
                }+/
                // FIXME: sub glob paths, not supported right now
            }
        }+/

		foreach(provider; providers_) {
			provider.remove(baseDir, glob, caseSensitive);
		}
	}
    
    ///
	@property IAllocator allocator() {
		return alloc;
	}

	private {
		IDirectoryEntry locateTopMostDirectory(URIAddress path, out URIAddress childPath, IDirectoryEntry parent=null) {
			IFileSystemEntry entry;
			IDirectoryEntry entryd;

			if (parent is null) {
				// 1. I don't have a parent (specified atleast), now check the mount points

				if ((entryd = cast(IDirectoryEntry)mounted_[path]) !is null) {
					childPath = URIAddress("/");
					return entryd;
				} else {
					immutable(string[]) parts = path.partsStairCase(true);

					foreach(i, p; parts) {
						if (i == 0) {
							childPath = URIAddress("/", alloc);
						} else {
							childPath = URIAddress(path[p.length + 1 .. $], alloc);
						}

						entryd = locateTopMostDirectory(childPath, childPath, null);
						if (entryd !is null)
							return entryd;
					}
				}
			} else {
				// 2. we have a parent, so lets ask

				// path = /dir1/file.zip/dir2
				//			/dir1
				//			/file.zip
				//			/dir2
				// path = /file.zip/dir2
				//			/file.zip
				// 			/dir2
				// path = /dir2
				//			/dir2

				immutable(string[]) parts = path.partsStairCase(true);

				foreach(i, p; parts) {
					if ((entry = parent[URIAddress(p, alloc)]) !is null) {
						if ((entryd = cast(IDirectoryEntry)entry) !is null) {
							if (i == 0) {
								childPath = URIAddress("/", alloc);
								return entryd;
							}
						}

						if (i == 0)
							childPath = URIAddress("/", alloc);
						else
							childPath = URIAddress(path[p.length + 1 .. $], alloc);
						
						foreach(provider; providers_) {
							if ((entryd = cast(IDirectoryEntry)provider.mount(childPath, entry)) !is null) {
								if (childPath == "/") {
									return entryd;
								} else {
									return locateTopMostDirectory(childPath, childPath, entryd);
								}
							}
						}
					}
				}
			}

			return null;
		}
	}
}