module std.experimental.platform;
import std.experimental.ui.window.defs : IWindow, IWindowCreator, Point;
import std.datetime : Duration, seconds;

shared interface IPlatform {
    IWindowCreator createWindow();
    IWindow createAWindow(); // completely up to platform implementation to what the defaults are
    
    @property {
        immutable(IDisplay) primaryDisplay();
        immutable(IDisplay[]) displays();
        immutable(IWindow[]) windows();
    }
    
    void optimizedEventLoop(Duration timeout = 0.seconds, bool delegate() callback=null);
    bool eventLoopIteration(Duration timeout = 0.seconds, bool untilEmpty=false);
    
    final void setAsDefault() {
        thePlatform_ = this;
    }
}

shared(IPlatform) thePlatform() {
    return thePlatform_;
}

shared(IPlatform) defaultPlatform() {
    return defaultPlatform_;
}

interface IDisplay {
    @property {
        string name();
        Point size();
        uint refreshRate();
        uint dotsPerInch();
        immutable(IWindow[]) windows();
    }
}

private {
    shared(IPlatform) defaultPlatform_;
    shared(IPlatform) thePlatform_;
    
    shared static this() {
        defaultPlatform_ = new shared ImplPlatform();
        thePlatform_ = defaultPlatform_;
    }

    /*
     * Do not forget when implementing the event loop on non Windows
     *      it will be necessary to process a second event loop e.g. kqueue or epoll.
     */
    
    version(Windows) {
        extern(System) {
            import core.sys.windows.windows : DWORD, HANDLE;
            DWORD MsgWaitForMultipleObjectsEx(DWORD nCount, const(HANDLE) *pHandles, DWORD dwMilliseconds, DWORD dwWakeMask, DWORD dwFlags);
            
            enum {
                QS_HOTKEY = 0x0080,
                QS_KEY = 0x0001,
                QS_MOUSEBUTTON = 0x0004,
                QS_MOUSEMOVE = 0x0002,
                QS_PAINT = 0x0020,
                QS_POSTMESSAGE = 0x0008,
                QS_RAWINPUT = 0x0400,
                QS_TIMER = 0x0010, 
                
                QS_MOUSE = (QS_MOUSEMOVE | QS_MOUSEBUTTON),
                QS_INPUT = (QS_MOUSE | QS_KEY | QS_RAWINPUT),
                QS_ALLEVENTS = (QS_INPUT | QS_POSTMESSAGE | QS_TIMER | QS_PAINT | QS_HOTKEY),
            };
            
            enum {
                MWMO_ALERTABLE = 0x0002,
                MWMO_INPUTAVAILABLE = 0x0004,
            };
        }
    }
    
    final shared class ImplPlatform : IPlatform {
        IWindowCreator createWindow() {assert(0);}
        IWindow createAWindow() {assert(0);}
        
        @property {
            immutable(IDisplay) primaryDisplay() {assert(0);}
            immutable(IDisplay[]) displays() {assert(0);}
            immutable(IWindow[]) windows() {assert(0);}
        }
        
        void optimizedEventLoop(Duration timeout = 0.seconds, bool delegate() callback=null) {
            import std.datetime : to;
            import std.algorithm : min;
            
            version(Windows) {
                import core.sys.windows.windows : DWORD, PeekMessageW, TranslateMessage, DispatchMessageW, PM_REMOVE, MSG, WAIT_TIMEOUT, INFINITE;
                
                DWORD msTimeout = cast(DWORD)min(timeout.total!"msecs", INFINITE);
                MSG msg;
                
                // Effectively the purpose of this Windows event loop is to
                //  ensure that all messages get dispatched as soon as possible.
                // Of course, this is great for GUI's or asynchronous IO where they
                //  only respond to external events, such as user input or socket
                //  connections. But for games this could be slightly problematic.
                // Atleast in the case for game development, it is quite common
                //  to implement your own event loops or as per the game engine.
                // In the case of your own event loop, it becomes more important to
                //  be able to handle your own side independently of the external events
                //  to the application. A single iteration is the best approach here.
                
                do {
                    // effectively a sleep until more events
                    DWORD signal = MsgWaitForMultipleObjectsEx(
                        cast(DWORD)0,
                        null,
                        msTimeout,
                        QS_ALLEVENTS,
                        // MWMO_ALERTABLE: Wakes up to execute overlapped hEvent (i/o completion)
                        // MWMO_INPUTAVAILABLE: Processes key/mouse input to avoid window ghosting
                        MWMO_ALERTABLE | MWMO_INPUTAVAILABLE
                    );
                    
                    // there are no messages so lets make sure the callback is called then repeat
                    if (signal == WAIT_TIMEOUT)
                        continue;
                    
                    // remove all messages from the queue
                    while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE)) {
                        TranslateMessage(&msg);
                        DispatchMessageW(&msg);
                    }
                } while(callback is null ? true : callback());
                
                return;
            } else version(OSX) {
                assert(0);
            }
            
            // is X11 active?
            // is Wayland active?
            assert(0);
        }
        
        bool eventLoopIteration(Duration timeout = 0.seconds, bool untilEmpty=false) {
            import std.datetime : to;
            import std.algorithm : min;
            
            version(Windows) {
                import core.sys.windows.windows : DWORD, PeekMessageW, TranslateMessage, DispatchMessageW, PM_REMOVE, MSG, WAIT_TIMEOUT, INFINITE;
                
                DWORD msTimeout = cast(DWORD)min(timeout.total!"msecs", INFINITE);
                DWORD signal = MsgWaitForMultipleObjectsEx(
                    cast(DWORD)0,
                    null,
                    msTimeout,
                    QS_ALLEVENTS,
                    // MWMO_ALERTABLE: Wakes up to execute overlapped hEvent (i/o completion)
                    // MWMO_INPUTAVAILABLE: Processes key/mouse input to avoid window ghosting
                    MWMO_ALERTABLE | MWMO_INPUTAVAILABLE
                );
                
                if (signal == WAIT_TIMEOUT)
                    return false;
                
                MSG msg;
                
                if (untilEmpty) {
                    while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE)) {
                        TranslateMessage(&msg);
                        DispatchMessageW(&msg);
                    }
                } else {
                    PeekMessageW(&msg, null, 0, 0, PM_REMOVE);
                    TranslateMessage(&msg);
                    DispatchMessageW(&msg);
                }
                
                return true;
            } else version(OSX) {
                assert(0);
            }
            
            // is X11 active?
            // is Wayland active?
            assert(0);
        }
    }
    
}