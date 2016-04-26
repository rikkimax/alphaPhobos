module std.experimental.platform;
import std.experimental.ui.window.defs : IWindow, IWindowCreator;
import std.experimental.ui.rendering;
import std.experimental.memory.managed;
import std.experimental.allocator : IAllocator, processAllocator, theAllocator;
import std.datetime : Duration, seconds;

///
interface IPlatform {
    ///
    managed!IRenderPointCreator createRenderPoint(IAllocator alloc = theAllocator());
    
    ///
    IRenderPoint createARenderPoint(IAllocator alloc = theAllocator()); // completely up to platform implementation to what the defaults are

    ///
    managed!IWindowCreator createWindow(IAllocator alloc = theAllocator());
    
    ///
    IWindow createAWindow(IAllocator alloc = theAllocator()); // completely up to platform implementation to what the defaults are

    @property {
        ///
        managed!IDisplay primaryDisplay(IAllocator alloc = processAllocator());
        
        ///
        managed!(IDisplay[]) displays(IAllocator alloc = processAllocator());
        
        ///
        managed!(IWindow[]) windows(IAllocator alloc = processAllocator());
    }

    ///
    void optimizedEventLoop(bool delegate() callback);
    
    ///
    void optimizedEventLoop(Duration timeout = 0.seconds, bool delegate() callback=null);

    ///
    bool eventLoopIteration(bool untilEmpty=false);

    ///
    final void setAsDefault() {
        thePlatform_ = this;
    }
}

///
IPlatform thePlatform() {
    return thePlatform_;
}

///
IPlatform defaultPlatform() {
    return defaultPlatform_;
}

// not __gshared, thread local.
private {
    IPlatform defaultPlatform_;
    IPlatform thePlatform_;
    
    static this() {
		import std.experimental.ui.internal.platform;
        defaultPlatform_ = new PlatformImpl();
        thePlatform_ = defaultPlatform_;
    }
}
