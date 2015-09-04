/**
 * Additions for std.uri
 */
module std.experimental.uri;
import std.experimental.allocator : IAllocator, makeArray, theAllocator, expandArray, shrinkArray, dispose, make;
import std.typecons : Nullable;

private static {
    // santisization uses this
    char[1024] charBuffer;
    size_t[128] charIndexBuffer;
    char[1024] tCopyBuffer;
}

/**
 * Does not handle the encoding/decoding
 */
struct URIAddress {
    string value;
    alias value this;

    private {
        IAllocator alloc;
        char[][] arrbuffDirectories;
    }

    ~this() {
        alloc.dispose(cast(char[])value);
        alloc.dispose(arrbuffDirectories);
    }

    /**
     * Takes a string that represents a URI path
     * 
     * Rerpresents a URI in the form of "$(LT)protName://$(GT)[user[:pass]]@[host/ip[:port]][/]$(LT)$(LT)drive$(GT):\$(GT)][<dir/>...][file[.ext]]".
     * Will automatically sanitise the input after duplicating it. If not specified file will be set as the protocol.
     * 
     * Can be used to represent a file system entry (such as a Windows drive).
     * 
     * Params:
     *      value   =   The path value, defaults to current working directory.
     *      alloc   =   The allocator to allocate return values as necssary.
     */
    this(string value=".", IAllocator alloc=theAllocator()) {
        this.alloc = alloc;

        // duplicate the value
        this.value = cast(immutable)alloc.makeArray!char(value.length);
        (cast(char[])this.value[]) = cast(char[])value[];

        // sanitise the value
        sanitise();
    }

    @property {
        ///
        IAllocator allocator() { return alloc; }

        /**
         * Gets the connection information with protocol from the given string.
         * 
         * May commonly be just "file://".
         * Is of the format "$(LT)protName://$(GT)[user[:pass]]@[host/ip[:port]]"
         * 
         * Returns:
         *         The connection string
         */
        string connectionInfo() {
            import std.string : indexOf;

            // $(LT)protName://$(GT)
            string prot = URIProtocolPrefix(value);
            string value2 = value[prot.length + 3 .. $];
            // [user[:pass]]@[host/ip[:port]][/][$(LT)dir/$(GT)...][file[.ext]]

            if (prot == "file")
                return value[0 .. 7];

            ptrdiff_t i;
            if ((i = value2.indexOf("/")) >= 0) {
                return value[0 .. i + prot.length + 3];
            } else {
                return value;
            }
        }

        ///
        unittest {
            assert(URIAddress("").connectionInfo == "file://");
            assert(URIAddress("/abc").connectionInfo == "file://");
            assert(URIAddress("/abc/def").connectionInfo == "file://");
            assert(URIAddress("c:\\test.txt").connectionInfo == "file://");
            
            assert(URIAddress("smb://test").connectionInfo == "smb://test");
            assert(URIAddress("smb://test/what").connectionInfo == "smb://test");
            
            assert(URIAddress("smb://user@test").connectionInfo == "smb://user@test");
            assert(URIAddress("smb://user:pass@test").connectionInfo == "smb://user:pass@test");
            assert(URIAddress("smb://user:pass@test/dir1/dir2").connectionInfo == "smb://user:pass@test");
        }

        /**
         * The protocol prefix
         * 
         * Otherwise known as being "$(LT)protName://$(GT)"
         * Forwards call to URIProtocolPrefix.
         * 
         * See_Also:
         *      URIProtocolPrefix
         * 
         * Returns:
         *      Returns the protocol prefix without "://".
         */
        string protocol() {
            return URIProtocolPrefix(value);
        }

        /**
         * The drive letter assigned as part of the directory entries.
         * 
         * Returns:
         *      The drive letter. Null otherwise.
         */
        Nullable!char driveLetter() {
            string addr = URIEntries(value);
            if (addr.length > 2 && addr[1] == ':' && addr[2] == '\\')
                return Nullable!char(addr[0]);
            else {
                Nullable!char ret;
                ret.nullify();
                return ret;
            }
        }

        ///
        unittest {
            assert(URIAddress("C:\\test").driveLetter == 'C');
            assert(URIAddress("/etc/dir").driveLetter.isNull);
            assert(URIAddress("smb://server/etc/dir").driveLetter.isNull);
            assert(URIAddress("smb://server/C:\\test").driveLetter == 'C');
        }

        /**
         * The username as part of connection string.
         * 
         * Returns:
         *      The username specified in the connection string, without password or null if not provided.
         */
        string username() {
            import std.string : indexOf;
            string prefix = URIAuthentication(value);

            ptrdiff_t i;
            if ((i = prefix.indexOf(":")) > 0) {
                return prefix[0 .. i];
            } else if (i == 0) {
                return null;
            } else {
                return prefix;
            }
        }

        ///
        unittest {
            assert(URIAddress("smb://:mypass@server").username is null);
            assert(URIAddress("smb://test@server").username == "test");
            assert(URIAddress("smb://test:mypass@server").username == "test");
            assert(URIAddress("smb://test:@server").username == "test");
        }

        /**
         * The password as part of the connection string.
         * 
         * Returns:
         *      The password specified in the connection string or null if not provided.
         */
        string password() {
            import std.string : indexOf;
            string prefix = URIAuthentication(value);

            ptrdiff_t i;
            if ((i = prefix.indexOf(":")) >= 0)
                if (prefix.length - (i + 1) != 0)
                    return prefix[i + 1 .. $];

            return null;
        }

        ///
        unittest {
            assert(URIAddress("smb://:mypass@server").password == "mypass");
            assert(URIAddress("smb://test@server").password is null);
            assert(URIAddress("smb://test:mypass@server").password == "mypass");
            assert(URIAddress("smb://test:@server").password is null);
        }

        /**
         * The port provided as part of the connections tring.
         * 
         * Returns:
         *      The port specified in the connection string or null if not provided.
         */
        Nullable!ushort port() {
            import std.string : indexOf;
            import std.conv : to;
            string prefix = URIConnection(value);

            ptrdiff_t i;
            if ((i = prefix.indexOf(":")) > 0 && prefix.length - i > 1)
                return Nullable!ushort(to!ushort(prefix[i + 1 .. $]));
            else {
                Nullable!ushort ret;
                ret.nullify();
                return ret;
            }
        }

        ///
        unittest {
            assert(URIAddress("smb://server:89").port == 89);
            assert(URIAddress("smb://server:").port.isNull);
            assert(URIAddress("smb://server").port.isNull);
        }

        /**
         * The seperate parts of the directory entries.
         * 
         * Returns:
         *      An array containing each of the different entries.
         *      Without path seperators. Except after drive letters.
         */
        immutable(string[]) parts() {
            size_t numDir;
            string addr = URIEntries(value);

            bool haveDrive;
            string driveText;

            if (addr.length > 2 && addr[1] == ':' && addr[2] == '\\') {
                haveDrive = true;
                driveText = addr[0 .. 3];
                addr = addr[3 .. $];
                numDir++;
            }

            if (addr.length > 0) {
                foreach(i, c; addr) {
                    if (i > 0 && i < addr.length-1 && c == '/') {
                        numDir++;
                    }
                }

                if (addr[$-1] != '/')
                    numDir++;
            }
            
            if (arrbuffDirectories.length < numDir)
                alloc.expandArray(arrbuffDirectories, numDir - arrbuffDirectories.length);

            string t;
            size_t numDirI;
            size_t lastI;

            if (addr.length > 0 && addr[0] == '/')
                lastI = 1;

            if (haveDrive) {
                numDirI = 1;
                arrbuffDirectories[0] = cast(char[])driveText;
            }

            foreach(i, c; addr) {
                if (c == '/' && i > 0) {
                    arrbuffDirectories[numDirI] = cast(char[])t;
                    numDirI++;
                    t = null;
                    lastI = i + 1;
                } else {
                    t = addr[lastI .. i + 1];
                }
            }

            if (t !is null)
                arrbuffDirectories[numDirI] = cast(char[])t;

            return cast(immutable(string[]))arrbuffDirectories[0 .. numDir];
        }

        ///
        unittest {
            URIAddress addr = URIAddress("/dir1/file.txt");
            
            assert(addr.parts.length == 2);
            assert(addr.parts[0] == "dir1");
            assert(addr.parts[1] == "file.txt");
            
            addr.value = "/dir1/dir2/file.txt";
            addr.sanitise();
            
            assert(addr.parts.length == 3);
            assert(addr.parts[0] == "dir1");
            assert(addr.parts[1] == "dir2");
            assert(addr.parts[2] == "file.txt");
            
            addr.value = "/dir1/file.txt";
            addr.sanitise();
            
            assert(addr.parts.length == 2);
            assert(addr.parts[0] == "dir1");
            assert(addr.parts[1] == "file.txt");
            
            assert(addr.arrbuffDirectories.length == 3);
            
            addr = URIAddress("smb://server/dir1/file.txt");
            immutable(string[]) parts = addr.parts;
            
            assert(parts.length == 2);
            assert(parts[0] == "dir1");
            assert(parts[1] == "file.txt");
        }

        /**
         * Produces parts conjoined together in a stair case format.
         * So that a 3 directory structure results in 3 different values with 1 to 3 being included.
         * 
         * Params:
         *      reverse =   Should the result be reversed? Only effects the order in the output array, not the indevidual values.
         * 
         * Returns:
         *      The stair cased version of the URI directory entries.
         */
        immutable(string[]) partsStairCase(bool reverse=false) {
            import std.string : indexOf;

            size_t startI;
            string addr = URIEntries(value);

            string[] ret = cast(string[])parts();

            foreach(i, part; ret) {
                startI += addr[startI .. $].indexOf(part) + part.length;
                ret[i] = addr[0 .. startI];
            }

            if (reverse) {
                foreach(i1; 0 .. ret.length / 2) {
                    size_t i2 = ret.length - (i1 + 1);

                    if (i2 != i1) {
                        string v1 = ret[i1];
                        string v2 = ret[i2];
                        ret[i2] = v1;
                        ret[i1] = v2;
                    }
                }
            }

            return cast(immutable)ret;
        }

        ///
        unittest {
            URIAddress addr = URIAddress("/dir1/dir2/file.ext");
            immutable(string[]) parts = addr.partsStairCase;
            
            assert(parts.length == 3);
            assert(parts[0] == "/dir1");
            assert(parts[1] == "/dir1/dir2");
            assert(parts[2] == "/dir1/dir2/file.ext");
            
            addr = URIAddress("/dir1/dir2/file.ext");
            immutable(string[]) parts2 = addr.partsStairCase(true);
            
            assert(parts2.length == 3);
            assert(parts2[0] == "/dir1/dir2/file.ext");
            assert(parts2[1] == "/dir1/dir2");
            assert(parts2[2] == "/dir1");
        }
    }

    /**
     * Sanitises the input so it meets a predefined formula.
     * 
     * Modifies the given input so that all URI strings contain a protocol and are using forward slashes except after drive letters.
     * Defaulting protocol is "file".
     * It will allocate the final output and use buffers for manipulating where possible.
     */
    void sanitise() {
        import std.uni : toUpper;
        char[] temp = cast(char[])value;

        if (temp.length == 0 || (temp.length == 1 && (temp[0] == '/' || temp[0] == '\\'))) {
            // no value explicit so set value
            
            alloc.expandArray(temp, 8 - temp.length);
            temp[0 .. 8] = "file:///"[];
            value = cast(string)temp;
            return;
        }

        // make sure first directory entry starts with either a drive, root(/), . if not a protocol/drive or ~
        if (URIConnection(value) is null) {
            if (temp.length > 0 && temp[0] == '~') {
                if (temp.length > 1 && !(temp[1] == '/' || temp[1] == '\\')) {
                    char[] temp2 = alloc.makeArray!char(temp.length + 1);
                    temp2[0] = temp[0];
                    temp2[1] = '/';
                    temp2[2 .. $] = temp[1 .. $];

                    alloc.dispose(temp);
                    temp = temp2;
                    value = cast(immutable)temp;
                }
            }
        }

        if (URIProtocolPrefix(value) is null) {
            // add file://
            value = cast(string)temp;

            if (value.length > 0 && (value[0] == '/' && value[0] == '\\')) {
                temp = alloc.makeArray!char(temp.length + 6);
                temp[7 .. $] = value[1 .. $];
            } else {
                temp = alloc.makeArray!char(temp.length + 7);
                temp[7 .. $] = value[0 .. $];
            }

            temp[0 .. 7] = "file://"[];

            alloc.dispose(cast(char[])value);
        } else {
            // ensure forward slashes after protocol
            size_t offset = URIProtocolPrefix(cast(string)temp).length;
            temp[offset + 1] = '/';
            temp[offset + 2] = '/';
        }

        value = cast(string)temp;

        // make directory seperator only /
        bool preColon;
        foreach(ref c; cast(char[])URIEntries(value)) {
            if (c == ':')
                preColon = true;
            else if (c == '\\' && !preColon)
                c = '/';
            else
                preColon = false;
        }

        size_t i = URIProtocolPrefix(value).length;

        // remove last / if added
        if (temp[$-1] == '/' && temp.length > 1 && temp.length > i + 3)
            alloc.shrinkArray(temp, 1);

        // work around, should not be needed
        value = cast(immutable)temp;
        size_t dashes;

        if (i == 1 && temp.length > 4 && temp[4] == '/') {
            char[] temp2 = charBuffer[0 .. temp.length - 5];
            temp2[] = temp[5 .. $];
            temp[4 .. temp2.length+4] = temp2[];
            temp = temp[0 .. temp2.length+4];
        }

        if (i > 0)
            i += 3; // <prot>://

        bool alreadyHitColon;

        for(;;) {
            if (i >= temp.length)
                break;

            if (temp[i] == '/') {
                i++;
                dashes++;
            } else if (dashes > 1) {
                char[] temp2 = charBuffer[0 .. temp.length - (dashes-1)];
                temp2[0 .. i - dashes] = temp[0 .. i - dashes];
                temp2[i-dashes .. $] = temp[i-(dashes-1) .. $];

                temp[0 .. temp2.length] = temp2[];
                temp = temp[0 .. temp2.length];

                i -= (dashes-1);
                //i++;
                dashes = 0;
            } else {
                if (temp[i] == ':' && !alreadyHitColon) {
                    alreadyHitColon = true;

                    if (i > 0 && i + 1 < temp.length) {
                        if (temp[i + 1] == '/' || temp[i + 1] == '\\') {
                            temp[i + 1] = '\\';
                            temp[i-1] = cast(char)toUpper(temp[i-1]);

                            if (temp[0 .. i-1] == "file:///") {
                                char[] temp2 = charBuffer[0 .. temp.length - 1];
                                temp2[0 .. 7] = "file://";
                                temp2[7 .. $] = temp[i - 1 .. $];
                                
                                temp[0 .. temp2.length] = temp2[];
                                temp = temp[0 .. temp2.length];

                                i--;
                            }

                            if (i + 3 < temp.length && temp[i + 2] == '/') {
                                char[] temp2 = charBuffer[0 .. temp.length - 1];
                                temp2[0 .. i + 2] = temp[0 .. i + 2];
                                temp2[i + 2 .. $] = temp[i + 3 .. $];

                                temp[0 .. temp2.length] = temp2[];
                                temp = temp[0 .. temp2.length];

                                i--;
                            }
                        }
                    }
                }

                dashes = 0;
                i++;
            }
        }

        // work around, should not be needed
        value = cast(immutable)temp;
    }

    ///
    unittest {
        assert(URIAddress("./file.ext") == "file://./file.ext");
        assert(URIAddress(".file.ext") == "file://.file.ext");
        assert(URIAddress("~/file.ext") == "file://~/file.ext");
        assert(URIAddress("~file.ext") == "file://~/file.ext");

        assert(URIAddress("/dir1//dir2/file.ext") == "file:///dir1/dir2/file.ext");
        assert(URIAddress("C:\\dir1//dir2/file.ext") == "file://C:\\dir1/dir2/file.ext");
    }

    /**
     * Expands out an address so that parent and current working directories are no longer part of it.
     * Also replaces the home directory and current working directory at the start as needed.
     * 
     * Params:
     *      homeDirectory   =   The home directory of the "running" user.
     *      cwd             =   The current working directory of the "running" application.
     * 
     * Returns:
     *      The expanded form of the current address.
     */
    URIAddress expand(URIAddress homeDirectory, URIAddress cwd) {
        import std.string : indexOf;
        string prot = URIProtocolPrefix(value);
        string temp = value;

        char[] retbuf;
        size_t offsetDirs;

        // grabs $(LT)protName://$(GT)
        if (prot.length > 1) {
            ptrdiff_t offseti;

            retbuf = charBuffer[0 .. prot.length + 3];
            retbuf[0 .. prot.length] = prot[];
            retbuf[prot.length .. $] = "://";
            temp = temp[prot.length + 3 .. $];

            if (prot != "file")
                offseti = temp.indexOf("/");

            // assuming sanitised correctly then this will /always/ exist
            assert(offseti >= 0);
            
            // grabs [user[:pass]]@[host/ip[:port]]
            retbuf = charBuffer[0 .. retbuf.length + offseti];
            retbuf[$-offseti .. $] = temp[0 .. offseti];
            temp = temp[offseti .. $];

            offsetDirs = retbuf.length;
        }

        if (temp[0] == '/')
            temp = temp[1 .. $];

        if (temp[0] == '.' || temp[0] == '~') {
            string replaceTo;

            // perform expansion
            if (temp[0] == '.') {
                string protPref = URIProtocolPrefix(cwd);
                if (protPref !is null && protPref != "file")
                    throw new Exception("Protocol as directory cannot be used in expansion");
                replaceTo = URIEntries(cwd);
            } else if (temp[0] == '~') {
                string protPref = URIProtocolPrefix(homeDirectory);
                if (protPref !is null && protPref != "file")
                    throw new Exception("Protocol as directory cannot be used in expansion");

                replaceTo = URIEntries(homeDirectory);
            }

            if ((replaceTo.length > 0 && replaceTo[0] == '/') || (retbuf == "file://" || retbuf.length == 0)) {
                retbuf = charBuffer[0 .. retbuf.length + replaceTo.length];
            } else {
                retbuf = charBuffer[0 .. retbuf.length + replaceTo.length + 1];
                retbuf[$-(replaceTo.length+1)] = '/';
            }
            retbuf[$-replaceTo.length .. $] = replaceTo[];

            temp = temp[1 .. $];
        }

        bool haveDrive;
        if (retbuf.length > 9 && retbuf[8] == ':' && retbuf[9] == '\\') {
            haveDrive = true;
            if (temp.length > 0 && temp[0] == '/') {
                retbuf = charBuffer[0 .. retbuf.length + (temp.length-1)];
                retbuf[$-(temp.length-1) .. $] = temp[1 .. $];
                offsetDirs += 3;
            } else {
                retbuf = charBuffer[0 .. retbuf.length + temp.length];
                retbuf[$-temp.length .. $] = temp[];
            }
        } else if (temp.length > 0 && temp[0] == '/') {
            retbuf = charBuffer[0 .. retbuf.length + temp.length];
            retbuf[$-temp.length .. $] = temp[];
        } else {
            retbuf = charBuffer[0 .. retbuf.length + (temp.length + 1)];
            retbuf[$-(temp.length + 1)] = '/';
            retbuf[$-temp.length .. $] = temp[];
        }

        // expansion of parent and current directory is simple.
        //  current directory gets removed out right.
        //  parent directory removes it and its parent node if it should exist.
        // C://dir1/dir2/../../dir3 C://dir3

        URIAddress* addrt = alloc.make!URIAddress(cast(string)retbuf, alloc);
        retbuf = charBuffer[0 .. addrt.value.length];
        retbuf[] = addrt.value[];

        size_t skipDirs;
        auto parts = addrt.parts;
        size_t[] ibuffers;

        if (haveDrive && parts !is null) {
            (cast()parts) = parts[1 .. $];
        }

        foreach_reverse(i, p; parts) {
            if (p == ".") continue;
            else if (p == "..") {
                skipDirs++;
                continue;
            } else if (skipDirs > 0) {
                skipDirs--;
                continue;
            }

            ibuffers = charIndexBuffer[0 .. ibuffers.length + 1];
            ibuffers[$-1] = i;
        }
        retbuf = retbuf[0 .. offsetDirs];

        // prot://user:pass@server:port/

        foreach_reverse(i; ibuffers) {
            size_t len = parts[i].length;
            retbuf = charBuffer[0 .. retbuf.length + len + 1];
            retbuf[$-(len + 1)] = '/';
            retbuf[$-len .. $] = parts[i];
        }

        alloc.dispose(addrt);

        try {
            return URIAddress(cast(string)retbuf, alloc);
        } catch(Error e) {
            assert(0, retbuf);
        }
    }

    ///
    unittest {
        assert(URIAddress("./test/file.ext").expand(URIAddress("/"), URIAddress("C:\\")) == "file://C:\\test/file.ext");
        assert(URIAddress("./test/file.ext").expand(URIAddress("/"), URIAddress("/etc")) == "file:///etc/test/file.ext");
        
        assert(URIAddress("~/test/file.ext").expand(URIAddress("C:\\"), URIAddress("/")) == "file://C:\\test/file.ext");
        assert(URIAddress("~/test/file.ext").expand(URIAddress("/etc"), URIAddress("/")) == "file:///etc/test/file.ext");
        
        assert(URIAddress("./test/file.ext").expand(URIAddress("C:\\"), URIAddress("/")) == "file:///test/file.ext");
        assert(URIAddress("./test/file.ext").expand(URIAddress("/etc"), URIAddress("/")) == "file:///test/file.ext");
        
        assert(URIAddress("~/test/file.ext").expand(URIAddress("/"), URIAddress("C:\\")) == "file:///test/file.ext");
        assert(URIAddress("~/test/file.ext").expand(URIAddress("/"), URIAddress("/etc")) == "file:///test/file.ext");
        
        assert(URIAddress("./dir1/dir2/../../dir3").expand(URIAddress("/"), URIAddress("C:\\")) == "file://C:\\dir3");
        assert(URIAddress("./dir1/dir2/../../dir3").expand(URIAddress("C:\\"), URIAddress("/")) == "file:///dir3");
        assert(URIAddress("~/dir1/dir2/../../dir3").expand(URIAddress("C:\\"), URIAddress("/")) == "file://C:\\dir3");
        assert(URIAddress("~/dir1/dir2/../../dir3").expand(URIAddress("/"), URIAddress("C:\\")) == "file:///dir3");
        
        assert(URIAddress("smb://server/./test").expand(URIAddress("/"), URIAddress("/")) == "smb://server/test");
        assert(URIAddress("smb://server/test").expand(URIAddress("/"), URIAddress("/")) == "smb://server/test");
        assert(URIAddress("smb://server/~/test").expand(URIAddress("/etc"), URIAddress("/")) == "smb://server/etc/test");
        assert(URIAddress("smb://server/./test").expand(URIAddress("/"), URIAddress("/etc")) == "smb://server/etc/test");
        
        assert(URIAddress("smb://server/dir1/dir2/../../dir3").expand(URIAddress("/"), URIAddress("/")) == "smb://server/dir3");
        
        assert(URIAddress("smb://server/~").expand(URIAddress("C:\\"), URIAddress("/")) ==  "smb://server/C:\\");
        assert(URIAddress("smb://server/.").expand(URIAddress("/"), URIAddress("C:\\")) == "smb://server/C:\\");
    }

    /**
     * The parent directory entry of the current URI address.
     * 
     * Returns:
     *      The parent directories URI address.
     */
    URIAddress parent() {
        import std.string : indexOf;
        string current = URIEntries(value);

        size_t start;
        foreach_reverse(i, c; current) {
            if (c == '/') {
                start = i;
                break;
            }
        }

        return URIAddress(value[0 .. value.indexOf(current) + start], alloc);
    }

    ///
    unittest {
        assert(URIAddress(".").parent == "file://");
        assert(URIAddress("./dir1/dir2").parent == "file://./dir1");
        assert(URIAddress("~/dir1/dir2").parent == "file://~/dir1");
        assert(URIAddress("C:\\dir1/dir2").parent == "file://C:\\dir1");
        assert(URIAddress("smb://server/dir1/dir2").parent == "smb://server/dir1");
        assert(URIAddress("smb://server/dir1").parent == "smb://server");
    }

    /**
     * Gets a child path based upon the child entries
     * 
     * Returns:
     *      A string containing a child path of the current one.
     */
    URIAddress subPath(URIAddress sub) {
        string suff = URIEntries(sub);
        char[] buff = tCopyBuffer[0 .. value.length + 1];

        buff[0 .. $-1] = value[];
        buff[$-1] = '/';

        buff = tCopyBuffer[0 .. buff.length + suff.length];
        buff[$-suff.length .. $] = suff[];

        return URIAddress(cast(string)buff, alloc);
    }

    ///
    unittest {
        assert(URIAddress("/etc/dir1/").subPath(URIAddress("dir2")) == "file:///etc/dir1/dir2");
        assert(URIAddress("/etc/dir1/").subPath(URIAddress("../dir2")) == "file:///etc/dir1/../dir2");
    }

    /**
     * Gets the parent entry and returns the child sub path of it.
     * 
     * Params:
     *      subling =   The child path to add to the parent directory.
     * 
     * Returns:
     *      A URI address of the parent of the current one with child entries of the specified.
     */
    URIAddress sibling(URIAddress subling) {
        import std.string : indexOf;
        string current = URIEntries(value);
        string suff = URIEntries(subling);

        size_t start;
        foreach_reverse(i, c; current) {
            if (c == '/') {
                start = i;
                break;
            }
        }

        string value2 = value[0 .. value.indexOf(current) + start];
        char[] buff = tCopyBuffer[0 .. value2.length + 1];
        
        buff[0 .. $-1] = value2[];
        buff[$-1] = '/';

        buff = tCopyBuffer[0 .. buff.length + suff.length];
        buff[$-suff.length .. $] = suff[];
        
        return URIAddress(cast(string)buff, alloc);
    }

    ///
    unittest {
        assert(URIAddress("/etc/dir1/").sibling(URIAddress("dir2")) == "file:///etc/dir2");
        assert(URIAddress("/etc/dir1/").sibling(URIAddress("../dir2")) == "file:///etc/../dir2");
        assert(URIAddress("/etc/dir1/").sibling(URIAddress("dir2/file.ext")) == "file:///etc/dir2/file.ext");
    }

	/**
	 * Wraps a string up with an allocator.
	 * 
	 * Does not sanitise.
	 * May perform weirdly or make bugs visible if the string is not already sanitised.
	 * 
	 * Params:
	 * 		from		=	The string to wrap
	 * 		allocator	=	The allocator to allocate using
     * 
     * Returns:
     *      The URIAddress based upon a given string. Without sanitising.
	 */
	static URIAddress using(string from, IAllocator allocator=theAllocator()) {
		URIAddress ret;
		ret.alloc = allocator;
		ret.value = from;
		return ret;
	}
}

///
unittest {
    assert(URIAddress("").value == "file:///");

    assert(URIAddress("smb:\\\\test/what") == "smb://test/what");
    assert(URIAddress("smb://test/what") == "smb://test/what");

    assert(URIAddress("~/test.txt") == "file://~/test.txt");
    assert(URIAddress("~\\test.txt") == "file://~/test.txt");
    assert(URIAddress("~test.txt") == "file://~/test.txt");

    assert(URIAddress("c:\\test.txt") == "file://C:\\test.txt");

    assert(URIAddress("/test\\abc") == "file:///test/abc");
    assert(URIAddress("/") == "file:///");
    assert(URIAddress("/test/") == "file:///test");
    assert(URIAddress("test/") == "file://test");

    assert(URIAddress("C:\\") == "file://C:\\");
}

// FIXME: requires std.string : indexOf be @nogc
@safe /+@nogc+/:

///
string URIProtocolPrefix(string value) {
    bool melformed;

    scope(exit)
        assert(!melformed);

    return URIProtocolPrefix(value, melformed);
}

///
string URIProtocolPrefix(string value, out bool melformed) {
    import std.string : indexOf;
    melformed = false;

    ptrdiff_t i;
    if ((i = value.indexOf("://")) > 1) {
        return value[0 .. i];
    } else if ((i = value.indexOf(":\\\\")) > 0) {
        if (i > 1)
            return value[0 .. i];
        else {
            melformed = true;
            return null;
        }
    } else if ((i = value.indexOf(":/")) > 0) {
        melformed = true;
        return null;
    } else if ((i = value.indexOf(":\\")) > 1) { // drive letter *grumbles*
        melformed = true;
        return null;
    } else
        return null;
}

///
unittest {
    bool melformed;

    assert(URIProtocolPrefix("smb://a/b/c.d", melformed) == "smb");
    assert(!melformed);
    assert(URIProtocolPrefix("smb:\\\\a/b/c.d", melformed) == "smb");
    assert(!melformed);
    assert(URIProtocolPrefix("d:\\a/b/c/.d", melformed) is null);
    assert(!melformed);
    assert(URIProtocolPrefix("smb:/a/b/c.d", melformed) is null);
    assert(melformed);
    assert(URIProtocolPrefix("s://a/b/c.d", melformed) is null);
    assert(melformed);


    assert(URIProtocolPrefix("abc", melformed) is null);
    assert(!melformed);
    assert(URIProtocolPrefix("ab", melformed) is null);
    assert(!melformed);
    

    assert(URIProtocolPrefix("a/b/c.d", melformed) is null);
    assert(!melformed);
    assert(URIProtocolPrefix("d:/", melformed) is null);
    assert(melformed);
    assert(URIProtocolPrefix("d://", melformed) is null);
    assert(melformed);
    assert(URIProtocolPrefix("d://a/b.c", melformed) is null);
    assert(melformed);
    assert(URIProtocolPrefix("D://a/b.c", melformed) is null);
    assert(melformed);
    

    assert(URIProtocolPrefix("a\\b\\c.d", melformed) is null);
    assert(!melformed);
    assert(URIProtocolPrefix("d:\\", melformed) is null);
    assert(!melformed);
    assert(URIProtocolPrefix("d:\\\\", melformed) is null);
    assert(melformed);
    assert(URIProtocolPrefix("d:\\\\a\\b.c", melformed) is null);
    assert(melformed);
    assert(URIProtocolPrefix("D:\\\\a\\b.c", melformed) is null);
    assert(melformed);
}

///
string URIProtocolSuffix(string value) {
    import std.string : indexOf;
    if (value.length < 3)
        return null;

    ptrdiff_t i;
    if ((i = value.indexOf("://")) > 1) {
        if (value.length > i + 3)
            return value[i + 3 .. $];
        else
            return null;
    } else if ((i = value.indexOf(":\\\\")) > 0) {
        if (value.length > i + 3)
            return value[i + 3 .. $];
        else
            return null;
    } else
        return value;
}

///
unittest {
    assert(URIProtocolSuffix("a/b/c") == "a/b/c");
    assert(URIProtocolSuffix("a\\b\\c") == "a\\b\\c");

    assert(URIProtocolSuffix("a://b/c") == "a://b/c");
    assert(URIProtocolSuffix("a:\\b\\c") == "a:\\b\\c");
}

///
string URIAuthentication(string value) {
    import std.string : indexOf;
    string input = URIProtocolSuffix(value);

    ptrdiff_t i;
    if ((i = input.indexOf("@")) > 0) {
        return input[0 .. i];
    } else {
        return null;
    }
}

///
unittest {
    assert(URIAuthentication("a/b/c") is null);
    assert(URIAuthentication("a@b/c") == "a");
    assert(URIAuthentication("a:b@c/d") == "a:b");
}

///
string URIAuthenticationSuffix(string value) {
    import std.string : indexOf;
    string input = URIProtocolSuffix(value);

    ptrdiff_t i;
    if ((i = input.indexOf("@")) > 0 && input.length - i > 1) {
        return input[i + 1 .. $];
    } else {
        return input;
    }
}

///
unittest {
    assert(URIAuthenticationSuffix("a/b/c") == "a/b/c");
    assert(URIAuthenticationSuffix("a@b/c") == "b/c");
    assert(URIAuthenticationSuffix("a:b@c/d") == "c/d");
}

///
string URIConnection(string value) {
    import std.string : indexOf;
    bool melformed;
    string prot = URIProtocolPrefix(value, melformed);
    string auth = URIAuthentication(value);

    if ((prot.length == 1 && auth is null) || prot == "file" || (prot is null && melformed))
        return null;
    else if (prot.length > 1) {
        ptrdiff_t i;
        string input = URIAuthenticationSuffix(value);
        if ((i = input.indexOf("/")) > 0) {
            return input[0 .. i];
        } else if ((i = input.indexOf("\\")) > 0) {
            return input[0 .. i];
        } else {
            return input;
        }
    } else {
        return null;
    }
}

///
unittest {
    assert(URIConnection("") is null);

    assert(URIConnection("file://d:\\abc") is null);
    assert(URIConnection("d:\\abc") is null);
    assert(URIConnection("/etc/something.txt") is null);

    assert(URIConnection("smb://abc/d/f") == "abc");
    assert(URIConnection("smb:\\\\abc\\d\\f") == "abc");
    assert(URIConnection("smb://abc") == "abc");
}

///
string URIQuery(string value) {
    import std.string : indexOf;
    string input = URIAuthenticationSuffix(value);
    
    ptrdiff_t i;
    if ((i = input.indexOf("?")) > 0 && input.length - i > 1) {
        return input[i + 1 .. $];
    } else {
        return null;
    }
}

///
unittest {
    assert(URIQuery("abc/d?b=e&z=y") == "b=e&z=y");
    assert(URIQuery("smb://abc/d?b=e&z=y") == "b=e&z=y");
    assert(URIQuery("/") is null);
    assert(URIQuery("/?") is null);
}

///
string URIEntries(string value) {
    import std.string : indexOf;
    string input = URIAuthenticationSuffix(value);
    string prot = URIProtocolPrefix(value);

    string query = URIQuery(input);
    if (query !is null)
        input = input[0 .. $-(query.length + 1)];

    ptrdiff_t i;
    if (prot == "file") {
        return input;
    } else if (prot.length > 1 && (i = input.indexOf("/")) > 0 && input.length - i > 1) {
        return input[i + 1 .. $];
    } else if (prot.length > 1 && (i = input.indexOf("\\")) > 0 && input.length - i > 1) {
        return input[i + 1 .. $];
    } else if (prot.length > 1) {
        return null;
    } else {
        return input;
    }
}

///
unittest {
    assert(URIEntries("file://d://abc") == "d://abc");
    assert(URIEntries("file://d:\\\\abc") == "d:\\\\abc");
    assert(URIEntries("file://d:\\abc") == "d:\\abc");

    assert(URIEntries("file:///abc") == "/abc");

    assert(URIEntries("/etc/something.txt") == "/etc/something.txt");

    assert(URIEntries("smb://abc/d/f") == "d/f");
    assert(URIEntries("smb:\\\\abc\\d\\f") == "d\\f");

    assert(URIEntries("smb://abc") is null);

    assert(URIEntries("abc/d?b=e&z=y") == "abc/d");
    assert(URIEntries("smb://abc/d?b=e&z=y") == "d");
    assert(URIEntries("/") is null);
    assert(URIEntries("/?") is null);

    assert(URIEntries("smb://abc/c:\\d/e/f.g") == "c:\\d/e/f.g");
}