import std.stdio : writeln, stdout;
import std.experimental.allocator;
import std.experimental.memory.managed;

void main() {
	import std.experimental.allocator.mallocator;
	import std.experimental.allocator.mmap_allocator;

	theAllocator = Mallocator.instance.allocatorObject;
	//theAllocator = MmapAllocator.instance.allocatorObject;

    managedMemoryTest();

	/+ubyte[] data = theAllocator.makeArray!ubyte(1000000000/100);
	data[] = 1;
	theAllocator.dispose(data);
	data = theAllocator.makeArray!ubyte(1000000000/1000);
	data[] = 2;
	theAllocator.dispose(data);+/
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
		theFile[theFile.size-1] = cast(ubyte)'Z';
		
		writeln(cast(managed!string)theFile.bytes);
		
		if (theFile.size > 150) {
			theFile.remove();
		}
	}
}

interface ManagedIFoo {
    void doit();
}

class ManagedFoo : ManagedIFoo {
    void doit() {
        writeln("Hello from Foo.doit!");
    }
    
    ~this() {
        writeln("I have been deallocated!");
    }
}

void managedMemoryTest() {
    import std.experimental.allocator : IAllocator, theAllocator;

	managed!ManagedFoo create(IAllocator alloc=theAllocator()) {
        return managed!ManagedFoo(alloc.make!ManagedFoo, managers(), alloc);
    }

    void func() {
        writeln("START2");
        
        auto value = create();
        value.doit();

        auto value2 = cast(managed!ManagedIFoo)value;
		value2.doit();

        writeln("END2");
    }

    void func2() {
        writeln("START3");

		auto func2_1(IAllocator alloc=theAllocator()) {
            return cast(managed!ManagedIFoo)managed!ManagedFoo(alloc.make!ManagedFoo, managers(ReferenceCountedManager()), alloc);
        }

        managed!ManagedIFoo value = func2_1();
        value.doit();

        writeln("END3");
    }

    writeln("START1");
    func();
    func2();
    writeln("END1");
}