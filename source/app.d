import std.stdio;
import std.experimental.allocator;

void main() {
	//VFSTest();
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
}

void WindowTest() {
	import std.experimental.ui.window;
}