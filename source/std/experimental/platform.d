module std.experimental.platform;
import std.experimental.ui.window.defs : IWindow, IWindowCreator;
import std.experimental.ui.rendering;
import std.experimental.internal.dummyRefCount;
import std.experimental.allocator : IAllocator, processAllocator, theAllocator;
import std.datetime : Duration, seconds;

void delegate() onDrawDel;

interface IPlatform {
    DummyRefCount!IRenderPointCreator createRenderPoint(IAllocator alloc = theAllocator());
    IRenderPoint createARenderPoint(IAllocator alloc = theAllocator()); // completely up to platform implementation to what the defaults are

    DummyRefCount!IWindowCreator createWindow(IAllocator alloc = theAllocator());
    IWindow createAWindow(IAllocator alloc = theAllocator()); // completely up to platform implementation to what the defaults are

    @property {
        DummyRefCount!IDisplay primaryDisplay(IAllocator alloc = processAllocator());
        DummyRefCount!(IDisplay[]) displays(IAllocator alloc = processAllocator());
        DummyRefCount!(IWindow[]) windows(IAllocator alloc = processAllocator());
    }

    void optimizedEventLoop(bool delegate() callback);
    void optimizedEventLoop(Duration timeout = 0.seconds, bool delegate() callback=null);

    bool eventLoopIteration(bool untilEmpty);
    bool eventLoopIteration(Duration timeout = 0.seconds, bool untilEmpty=false);

    final void setAsDefault() {
        thePlatform_ = this;
    }
}

IPlatform thePlatform() {
    return thePlatform_;
}

IPlatform defaultPlatform() {
    return defaultPlatform_;
}

// FIXME: private is bugged, package is not
package __gshared {
    IPlatform defaultPlatform_;
    IPlatform thePlatform_;
    
    shared static this() {
        import std.experimental.internal.platform_window_impl;
        defaultPlatform_ = new WindowPlatformImpl();
        thePlatform_ = defaultPlatform_;
    }
}
