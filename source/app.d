import std.stdio : writeln;
import std.experimental.allocator;

void main() {
    //VFSTest();
    //windowTest();
    //displaysTest();
    //notifyTest();
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

    foreach(i, display; defaultPlatform().displays) {
        write(tempLocation("display_" ~ i.text ~ ".png"),
            (cast()display).screenshot().asPNG.toBytes);

        foreach(j, window; display.windows) {
            write(tempLocation("display_" ~ i.text ~ "_window_" ~ j.text ~ ".png"),
                (cast()window).screenshot().asPNG.toBytes);

            write(tempLocation("display_" ~ i.text ~ "_window_" ~ j.text ~ "_icon.png"),
                (cast()window).icon.asPNG.toBytes);
        }
    }

    foreach(i, window; defaultPlatform().windows) {
        write(tempLocation("window_" ~ i.text ~ ".png"),
            (cast()window).screenshot().asPNG.toBytes);

        write(tempLocation("window_" ~ i.text ~ "_icon.png"),
            (cast()window).icon.asPNG.toBytes);
    }
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

void windowTest() {
    import std.experimental.platform;
    import std.experimental.ui;
    import std.experimental.graphic.image.manipulation.base : fillOn;

    IWindow window;
    void onIteration() {
        window.context.vramAlphaBuffer.fillOn(RGBA8(255, 0, 0, 255));
        window.context.swapBuffers();
    }

    auto creator = thePlatform.createWindow();
    //creator.style = WindowStyle.Fullscreen;
    //creator.size = UIPoint(cast(short)800, cast(short)600);
    
    window = creator.createWindow();
    window.title = "Title!";
    window.events.onDraw = &onIteration;
    
    import std.datetime : msecs;

    window.show();
    thePlatform().optimizedEventLoop(/+() { onIteration(); return true;}+/);
    /+while(window.visible) {
        thePlatform().eventLoopIteration(true);
        //onIteration();
    }+/
}
