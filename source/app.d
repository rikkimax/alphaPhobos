import std.stdio;
import std.experimental.allocator;

void main() {
	VFSTest();
	//WindowTest();
}

void VFSTest() {
	import std.experimental.vfs;
	import std.experimental.allocator;
	import std.experimental.allocator.gc_allocator;

	auto alloc = allocatorObject(GCAllocator.instance);
	
	IFileSystem fs = alloc.make!FileSystem(alloc);
	fs.attachProvider(alloc.make!OSFileSystemProvider(alloc));
	//fs.attachProvider(alloc.make!ZipFilter(alloc));
	//fs.attachProvider(alloc.make!SFTP(alloc));
	
	//IFileSystemEntry entry = fs["/path/test.txt"];
	/+entry = fs["/path" .. "user:pass@server/path2"];

	// fs["/dir1/file.zip/dir2/file.zip"]

	if (entry !is null) {
		entry.forceUnload();
		fs.unloadMount(entry);
	}

	foreach(mount; fs.mounted()) {
		URIPath path = mount.key;
		Ientry entry = mount.value;
	}

	foreach(entry; fs.find("/connections/irc/*")) {
		URIPath path = mount.key;
		IEntry entry = mount.value;
	}+/

    IFileSystemEntry theEntry = fs["./mytestfile.txt"];

    if (theEntry is null) {
        theEntry = fs.createFile("./mytestfile.txt");
        if (IFileEntry theFile = cast(IFileEntry)theEntry)
            theFile.write(cast(ubyte[])"Some awesome text here!");
    }

    if (IFileEntry theFile = cast(IFileEntry)theEntry) {
        import std.process : thisProcessID;
        import std.conv : text;
        import std.datetime;

        theFile.append(cast(ubyte[])("\nHi from process " ~ thisProcessID.text ~ " @" ~ Clock.currTime.toSimpleString));

        writeln(cast(string)theFile.bytes);

        if (theFile.size > 150) {
            theFile.remove();
        }
    }
}

void WindowTest() {
	import std.experimental.ui.window;
}