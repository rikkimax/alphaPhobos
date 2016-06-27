import std.stdio : writeln, stdout;
import std.experimental.allocator;
import std.experimental.memory.managed;

void main() {
	import std.experimental.allocator.mallocator;
	import std.experimental.allocator.mmap_allocator;

	theAllocator = Mallocator.instance.allocatorObject;
	//theAllocator = MmapAllocator.instance.allocatorObject;

    //VFSTest();
    //windowTest();
    //displaysTest();
    //notifyTest();
    //managedMemoryTest();

	/+ubyte[] data = theAllocator.makeArray!ubyte(1000000000/100);
	data[] = 1;
	theAllocator.dispose(data);
	data = theAllocator.makeArray!ubyte(1000000000/1000);
	data[] = 2;
	theAllocator.dispose(data);+/

	displaysTest();
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

void notifyTest() {
    import std.experimental.platform;
    import std.experimental.ui.notifications;
    import std.experimental.graphic.image.fileformats.png;
    import std.file : read;

    thePlatform().notificationIcon(loadPNG!RGBA8(cast(ubyte[])read("testAssets/test.png")));
    thePlatform().notify(loadPNG!RGBA8(cast(ubyte[])read("testAssets/test2.png")), "Hey testing!"d, "Some text here..."d);

    thePlatform().createAWindow().show();
    thePlatform().optimizedEventLoop();
}

void displaysTest() {
    import std.experimental.platform;
    import std.experimental.ui.window.features;
    import std.experimental.graphic.image.fileformats.png;
    import std.file : write;
    import std.conv : text;

    auto primaryDisplay = defaultPlatform().primaryDisplay;
    writeln(primaryDisplay.name, " ", primaryDisplay.size, " ", primaryDisplay.refreshRate, "hz ", primaryDisplay.luminosity, " lumens");

    foreach(display; defaultPlatform().displays) {
        writeln(display.name, " ", display.size, " ", display.refreshRate, "hz");
    }

    string tempLocation(string for_) {
        import std.path : buildPath;
        import std.file : tempDir, exists, mkdirRecurse;
        import std.process : thisProcessID;
        import std.conv : text;
        
        string tempLoc = buildPath(tempDir(), thisProcessID.text);
        if (!exists(tempLoc))
            mkdirRecurse(tempLoc);
        
        return buildPath(tempLoc, for_);
    }

    writeln(tempLocation(""));

	import core.memory : GC;
	// std.zlib leaks memory so we gotta add some collects in there :/

    foreach(i, display; defaultPlatform().displays) {
		auto ds = display.screenshot();
		if (ds != typeof(ds).init && ds.width > 0 && ds.height > 0) {
			write(tempLocation("display_" ~ i.text ~ ".png"), ds.asPNG.toBytes);
			GC.collect;
		}

        foreach(j, window; display.windows) {
			auto ws = window.screenshot();
			if (ws != typeof(ws).init && ws.width > 0 && ws.height > 0)
				write(tempLocation("display_" ~ i.text ~ "_window_" ~ j.text ~ ".png"), ws.asPNG.toBytes);
			
			auto ii = window.icon;
			if (ii != typeof(ii).init && ii.width > 0 && ii.height > 0)
				write(tempLocation("display_" ~ i.text ~ "_window_" ~ j.text ~ "_icon.png"), ii.asPNG.toBytes);
			GC.collect;
		}
    }

	foreach(i, window; defaultPlatform().windows) {
		auto ws = window.screenshot();
		if (ws != typeof(ws).init && ws.width > 0 && ws.height > 0)
			write(tempLocation("window_" ~ i.text ~ ".png"), ws.asPNG.toBytes);

		auto ii = window.icon;
		if (ii != typeof(ii).init && ii.width > 0 && ii.height > 0)
			write(tempLocation("window_" ~ i.text ~ "_icon.png"), ii.asPNG.toBytes);
			GC.collect;
    }
}

void windowTest() {
    import std.experimental.platform;
    import std.experimental.ui;
    import std.experimental.graphic.image.manipulation.base : fillOn;

    IWindow window;

    auto creator = thePlatform.createWindow();
    //creator.style = WindowStyle.Fullscreen;
    //creator.size = UIPoint(cast(short)800, cast(short)600);
    
    window = creator.createWindow();
    window.title = "Title!";
    
    window.events.onForcedDraw = () {
        writeln("onForcedDraw");
        stdout.flush;
        
        window.context.vramAlphaBuffer.fillOn(RGBA8(255, 0, 0, 255));
        window.context.swapBuffers();
    };
    
    window.events.onCursorMove = (short x, short y) {
        writeln("onCursorMove: x: ", x, " y: ", y);
        stdout.flush;
    };
    
    window.events.onCursorAction = (CursorEventAction action) {
        writeln("onCursorAction: ", action);
        stdout.flush;
    };
    
    window.events.onKeyEntry = (dchar key, SpecialKey specialKey, ushort modifiers) {
        writeln("onKeyEntry: key: ", key, " specialKey: ", specialKey, " modifiers: ", modifiers);
        stdout.flush;
    };
    
    window.events.onScroll = (short amount) {
        writeln("onScroll: ", amount);
        stdout.flush;
    };
    
    window.events.onClose = () {
        writeln("onClose");
        stdout.flush;
    };
    
    import std.datetime : msecs;

    window.show();
	thePlatform().optimizedEventLoop(() { return window.renderable; });
    /+while(window.visible) {
        thePlatform().eventLoopIteration(true);
        //onIteration();
    }+/
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
    import std.experimental.allocator : IAllocator, processAllocator;

    managed!ManagedFoo create(IAllocator alloc=processAllocator()) {
        return managed!ManagedFoo(managers(), alloc);
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

        auto func2_1(IAllocator alloc=processAllocator()) {
            return cast(managed!ManagedIFoo)managed!ManagedFoo(managers!(ManagedFoo, ManagedRefCount), alloc);
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