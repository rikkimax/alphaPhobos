module std.experimental.internal.platform_window_impl;

package(std.experimental) {
    import std.experimental.internal.containers.list;
    import std.experimental.ui.window.defs;
    import std.experimental.ui.context_features;
    import std.experimental.ui.window.features;
    import std.experimental.ui.notifications;
    import std.experimental.ui.rendering;
    import std.experimental.allocator : IAllocator, processAllocator, theAllocator, make, makeArray, dispose;
    import std.experimental.math.linearalgebra.vector : vec2;
    import std.experimental.graphic.image : ImageStorage;
    import std.experimental.ui.window.features;
    import std.experimental.graphic.color : RGB8, RGBA8;
    import std.experimental.internal.dummyRefCount;
    import std.datetime : Duration, seconds, msecs;
    import std.experimental.platform;
    
    enum EnabledEventLoops {
        None = 1 << 0,
        Windows = 1 << 1,
        X11 = 1 << 2,
        Cocoa = 1 << 3,
        Wayland = 1 << 4,
        Epoll = 1 << 5,
        LibEvent = 1 << 6,
    }

    /*
     * Do not forget when implementing the event loop on non Windows
     *  it will be necessary to process a second event loop e.g. kqueue or epoll.
     */
    final class WindowPlatformImpl : IPlatform, Feature_Notification, Have_Notification {
        private {
            // theoretically it is possible that you could have e.g. Wayland/X11 on a platform such as Windows
            //  but also have a Windows event loop *grrr*

            version(Windows) {
                ubyte enabledEventLoops = EnabledEventLoops.Windows;
            } else {
                ubyte enabledEventLoops;
            }
        }
        version(Windows) {
            pragma(lib, "gdi32");
            pragma(lib, "user32");
        }
        
        DummyRefCount!IWindowCreator createWindow(IAllocator alloc = theAllocator()) {
            return DummyRefCount!IWindowCreator(alloc.make!WindowCreatorImpl(this, alloc), alloc);
        }
        
        IWindow createAWindow(IAllocator alloc = theAllocator()) {
            auto creator = createWindow(alloc);
            creator.size = UIPoint(cast(short)800, cast(short)600);
            // set as VRAM context
            return creator.createWindow();
        }

        DummyRefCount!IRenderPointCreator createRenderPoint(IAllocator alloc = theAllocator()) {
            return DummyRefCount!IRenderPointCreator(alloc.make!WindowCreatorImpl(this, alloc), alloc);
        }

        IRenderPoint createARenderPoint(IAllocator alloc = theAllocator()) {
            return createAWindow(alloc);
        }

        @property {
            DummyRefCount!IDisplay primaryDisplay(IAllocator alloc = processAllocator()) {
                foreach(display; displays) {
                    if ((cast(DisplayImpl)display).primary) {
                        return DummyRefCount!IDisplay((cast(DisplayImpl)display).dup(alloc), alloc);
                    }
                }
                
                return DummyRefCount!IDisplay(null, null);
            }
            
            DummyRefCount!(IDisplay[]) displays(IAllocator alloc = processAllocator()) {
                version(Windows) {
                    GetDisplays ctx = GetDisplays(alloc, this);
                    ctx.call;
                    return DummyRefCount!(IDisplay[])(ctx.displays, alloc);
                } else
                    assert(0);
            }
            
            DummyRefCount!(IWindow[]) windows(IAllocator alloc = processAllocator()) {
                version(Windows) {
                    GetWindows ctx = GetWindows(alloc, this, null);
                    ctx.call;
                    return DummyRefCount!(IWindow[])(ctx.windows, alloc);
                } else
                    assert(0);
            }
        }
        
        Feature_Notification __getFeatureNotification() {
            version(Windows)
                return this;
            else
                assert(0);
        }

        @property {
            ImageStorage!RGBA8 getNotificationIcon(IAllocator alloc=theAllocator) {
                import std.experimental.graphic.image.interfaces : imageObjectFrom;
                import std.experimental.graphic.image.storage.base : ImageStorageHorizontal;

                version(Windows) {
                    return imageObjectFrom!(ImageStorageHorizontal!RGBA8)(taskbarCustomIcon, alloc);
                } else {
                    assert(0);
                }
            }

            void setNotificationIcon(ImageStorage!RGBA8 icon, IAllocator alloc=theAllocator) {
                import std.experimental.graphic.image.interfaces : imageObjectFrom;
                import std.experimental.graphic.image.storage.base : ImageStorageHorizontal;

                version(Windows) {
                    if (icon is null) {
                        Shell_NotifyIconW(NIM_DELETE, &taskbarIconNID);
                        taskbarIconNID = NOTIFYICONDATAW.init;
                    } else {
                        bool toAdd = taskbarIconNID is NOTIFYICONDATAW.init;

                        if (taskbarIconWindow is null) {
                            taskbarIconWindow = thePlatform().createAWindow(alloc);
                        }

                        taskbarIconNID.cbSize = NOTIFYICONDATAW.sizeof;
                        taskbarIconNID.uVersion = NOTIFYICON_VERSION_4;
                        taskbarIconNID.uFlags = NIF_ICON | NIF_STATE;
                        taskbarIconNID.hWnd = *cast(HWND*)taskbarIconWindow.__handle;

                        HDC hFrom = GetDC(null);
                        HDC hMemoryDC = CreateCompatibleDC(hFrom);

                        scope(exit) {
                            DeleteDC(hMemoryDC);
                            ReleaseDC(null, hFrom);
                        }

                        if (taskbarIconNID.hIcon !is null) {
                            DeleteObject(taskbarIconNID.hIcon);
                            taskbarCustomIconAllocator.dispose(taskbarCustomIcon);
                        }

                        taskbarCustomIconAllocator = alloc;
                        taskbarCustomIcon = imageObjectFrom!(ImageStorageHorizontal!RGBA8)(icon, alloc);

                        taskbarIconNID.hIcon = imageToIcon(icon, hMemoryDC, alloc);

                        if (toAdd) {
                            Shell_NotifyIconW(NIM_ADD, &taskbarIconNID);
                        } else {
                            Shell_NotifyIconW(NIM_MODIFY, &taskbarIconNID);
                        }

                        Shell_NotifyIconW(NIM_SETVERSION, &taskbarIconNID);
                    }
                } else
                    assert(0);
            }
        }
        
        void notify(ImageStorage!RGBA8 icon, dstring title, dstring text, IAllocator alloc=theAllocator) {
            import std.utf : byUTF;
            version(Windows) {
                if (taskbarIconWindow is null)
                    taskbarIconWindow = thePlatform().createAWindow(alloc);

                NOTIFYICONDATAW nid;
                nid.cbSize = NOTIFYICONDATAW.sizeof;
                nid.uVersion = NOTIFYICON_VERSION_4;
                nid.uFlags = NIF_ICON | NIF_SHOWTIP | NIF_INFO | NIF_STATE | NIF_REALTIME;
                nid.uID = 1;
                nid.hWnd = *cast(HWND*)taskbarIconWindow.__handle;

                size_t i;
                foreach(c; byUTF!wchar(title)) {
                    if (i >= nid.szInfoTitle.length - 1) {
                        nid.szInfoTitle[i] = cast(wchar)0;
                        break;
                    } else
                        nid.szInfoTitle[i] = c;

                    i++;
                    if (i == title.length)
                        nid.szInfoTitle[i] = cast(wchar)0;
                }
                
                i = 0;
                foreach(c; byUTF!wchar(text)) {
                    if (i >= nid.szInfo.length - 1) {
                        nid.szInfo[i] = cast(wchar)0;
                        break;
                    } else
                        nid.szInfo[i] = c;

                    i++;
                    if (i == text.length)
                        nid.szInfo[i] = cast(wchar)0;
                }

                HDC hFrom = GetDC(null);
                HDC hMemoryDC = CreateCompatibleDC(hFrom);
                
                scope(exit) {
                    DeleteDC(hMemoryDC);
                    ReleaseDC(null, hFrom);
                }
                
                nid.hIcon = imageToIcon(icon, hMemoryDC, alloc);

                Shell_NotifyIconW(NIM_ADD, &nid);
                Shell_NotifyIconW(NIM_SETVERSION, &nid);
                
                Shell_NotifyIconW(NIM_DELETE, &nid);
                DeleteObject(nid.hIcon);
            } else
                assert(0);
        }

        void clearNotifications() {
            version(Windows) {
                // nothing needs to happen :)
            } else {
                assert(0);
            }
        }

        private {
            IAllocator taskbarCustomIconAllocator;
            ImageStorage!RGBA8 taskbarCustomIcon;

            version(Windows) {
                IWindow taskbarIconWindow;
                NOTIFYICONDATAW taskbarIconNID;
            }
        }
        void optimizedEventLoop(bool delegate() callback) {
            optimizedEventLoop(0.seconds, callback);
        }

        void optimizedEventLoop(Duration timeout = 0.seconds, bool delegate() callback=null) {
            import std.datetime : to;
            import std.algorithm : min;

            version(Windows) {
                if (enabledEventLoops & EnabledEventLoops.Windows) {
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
                            QS_ALLEVENTS | QS_SENDMESSAGE,
                            // MWMO_ALERTABLE: Wakes up to execute overlapped hEvent (i/o completion)
                            // MWMO_INPUTAVAILABLE: Processes key/mouse input to avoid window ghosting
                            MWMO_ALERTABLE | MWMO_INPUTAVAILABLE
                        );

                        // there are no messages so lets make sure the callback is called then repeat
                        if (signal == WAIT_TIMEOUT) {
                            import core.thread : Thread;
                            Thread.sleep(50.msecs);
                            continue;
                        }

                        // remove all messages from the queue
                        while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) > 0) {
                            TranslateMessage(&msg);
                            DispatchMessageW(&msg);
                        }
                    } while(callback is null ? true : callback());
                }
            } else version(OSX) {
                if (enabledEventLoops & EnabledEventLoops.Cocoa) {
                    assert(0);
                }
            }

            if (enabledEventLoops & EnabledEventLoops.X11) {
                assert(0);
            }
            if (enabledEventLoops & EnabledEventLoops.Wayland) {
                assert(0);
            }
        }

        bool eventLoopIteration(bool untilEmpty) {
            return eventLoopIteration(0.seconds, untilEmpty);
        }

        bool eventLoopIteration(Duration timeout = 0.seconds, bool untilEmpty=false) {
            import std.datetime : to;
            import std.algorithm : min;

            version(Windows) {
                if (enabledEventLoops & EnabledEventLoops.Windows) {
                    import core.sys.windows.windows : DWORD, PeekMessageW, TranslateMessage, DispatchMessageW, PM_REMOVE, MSG, WAIT_TIMEOUT, INFINITE;

                    DWORD msTimeout = cast(DWORD)min(timeout.total!"msecs", INFINITE);
                    DWORD signal = MsgWaitForMultipleObjectsEx(
                        cast(DWORD)0,
                        null,
                        msTimeout,
                        QS_ALLEVENTS | QS_SENDMESSAGE,
                        // MWMO_ALERTABLE: Wakes up to execute overlapped hEvent (i/o completion)
                        // MWMO_INPUTAVAILABLE: Processes key/mouse input to avoid window ghosting
                        MWMO_ALERTABLE | MWMO_INPUTAVAILABLE
                        );

                    if (signal == WAIT_TIMEOUT)
                        return false;

                    MSG msg;

                    if (untilEmpty) {
                        while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) > 0) {
                            TranslateMessage(&msg);
                            DispatchMessageW(&msg);
                        }
                    } else {
                        PeekMessageW(&msg, null, 0, 0, PM_REMOVE);
                        TranslateMessage(&msg);
                        DispatchMessageW(&msg);
                    }
                }
            } else version(OSX) {
                if (enabledEventLoops & EnabledEventLoops.Cocoa) {
                    assert(0);
                }
            }

            if (enabledEventLoops & EnabledEventLoops.X11) {
                assert(0);
            }
            if (enabledEventLoops & EnabledEventLoops.Wayland) {
                assert(0);
            }

            return true;
        }
    }
    
    version(Windows) {
        import core.sys.windows.windows;
        static wstring ClassNameW = __MODULE__ ~ ":Class\0"w;
        
        enum WindowDWStyles : DWORD {
            Dialog = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX,
            DialogEx = WS_EX_ACCEPTFILES | WS_EX_APPWINDOW,
            
            Borderless = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_BORDER | WS_MINIMIZEBOX,
            BorderlessEx = WS_EX_ACCEPTFILES | WS_EX_APPWINDOW,
            
            Popup = WS_POPUPWINDOW | WS_CAPTION | WS_SYSMENU | WS_BORDER | WS_MINIMIZEBOX,
            PopupEx = WS_EX_ACCEPTFILES | WS_EX_APPWINDOW | WS_EX_TOPMOST,
            
            Fullscreen = WS_POPUP | WS_CLIPCHILDREN | WS_CLIPSIBLINGS,
            FullscreenEx = WS_EX_APPWINDOW | WS_EX_TOPMOST
        } 
        
        //
        
        alias HMONITOR = HANDLE;
        
        enum MONITORINFOF_PRIMARY = 1;
        enum CCHDEVICENAME = 32;
        enum VREFRESH = 116;
        enum DWORD ENUM_CURRENT_SETTINGS = cast(DWORD)-1;
        enum DIB_RGB_COLORS = 0x0;
        enum BI_RGB = 0;
        enum MONITOR_DEFAULTTONULL = 0;
        enum GWL_STYLE = -16;
        enum GWL_EXSTYLE = -20;
        enum GCL_HICON = -14;
        enum ICON_SMALL = 0;
        enum ICON_BIG = 1;
        enum MF_SEPARATOR = 0x00000800;
        enum MF_DISABLED = 0x00000002;
        enum MF_ENABLED = 0;
        enum MF_BITMAP = 0x00000004;
        enum MF_BYCOMMAND = 0;
        enum MF_STRING = 0;
        enum MF_POPUP = 0x00000010;
        enum GWLP_USERDATA = -21;
        enum HTCLIENT = 1;
        enum IMAGE_CURSOR = 2;
        enum LR_DEFAULTSIZE = 0x00000040;
        enum LR_SHARED = 0x00008000;
        enum NOTIFYICON_VERSION_4 = 4;
        enum NIF_ICON = 2;
        enum NIF_MESSAGE = 1;
        enum NIM_ADD = 0;
        enum NIM_MODIFY = 1;
        enum NIM_DELETE = 2;
        enum NIM_SETVERSION = 4;
        enum NIF_SHOWTIP = 0x00000080;
        enum NIS_SHAREDICON = 0x00000002;
        enum NIF_TIP  = 0x00000004;
        enum NIF_INFO = 0x00000010;
        enum NIF_STATE = 0x00000008;
        enum NIS_HIDDEN = 0x00000001;
        enum NIF_REALTIME = 0x00000040;
        enum NIIF_USER  = 0x00000004;
        enum WM_EXITSIZEMOVE = 0x232;

        /**
         * Boost licensed, will be removed when it is part of core.sys.windows.winuser
         */
        
        template MAKEINTRESOURCE_T(WORD i) {
            enum LPTSTR MAKEINTRESOURCE_T = cast(LPTSTR)(i);
        }
        
        enum {
            IDC_ARROW       = MAKEINTRESOURCE_T!(32512),
            IDC_IBEAM       = MAKEINTRESOURCE_T!(32513),
            IDC_WAIT        = MAKEINTRESOURCE_T!(32514),
            IDC_CROSS       = MAKEINTRESOURCE_T!(32515),
            IDC_UPARROW     = MAKEINTRESOURCE_T!(32516),
            IDC_SIZE        = MAKEINTRESOURCE_T!(32640),
            IDC_ICON        = MAKEINTRESOURCE_T!(32641),
            IDC_SIZENWSE    = MAKEINTRESOURCE_T!(32642),
            IDC_SIZENESW    = MAKEINTRESOURCE_T!(32643),
            IDC_SIZEWE      = MAKEINTRESOURCE_T!(32644),
            IDC_SIZENS      = MAKEINTRESOURCE_T!(32645),
            IDC_SIZEALL     = MAKEINTRESOURCE_T!(32646),
            IDC_NO          = MAKEINTRESOURCE_T!(32648),
            IDC_HAND        = MAKEINTRESOURCE_T!(32649),
            IDC_APPSTARTING = MAKEINTRESOURCE_T!(32650),
            IDC_HELP        = MAKEINTRESOURCE_T!(32651),
            IDI_APPLICATION = MAKEINTRESOURCE_T!(32512),
            IDI_HAND        = MAKEINTRESOURCE_T!(32513),
            IDI_QUESTION    = MAKEINTRESOURCE_T!(32514),
            IDI_EXCLAMATION = MAKEINTRESOURCE_T!(32515),
            IDI_ASTERISK    = MAKEINTRESOURCE_T!(32516),
            IDI_WINLOGO     = MAKEINTRESOURCE_T!(32517),
            IDI_WARNING     = IDI_EXCLAMATION,
            IDI_ERROR       = IDI_HAND,
            IDI_INFORMATION = IDI_ASTERISK
        }
        
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
    
            QS_SENDMESSAGE = 0x0040
        }
    
        enum {
            MWMO_ALERTABLE = 0x0002,
            MWMO_INPUTAVAILABLE = 0x0004,
        }
        
        /**
         * Boost licensed, will be removed when it is part of core.sys.windows.winuser
         */
        
        alias TCHAR = char;
        
        struct MONITORINFOEX {
            DWORD cbSize;
            RECT rcMonitor;
            RECT rcWork;
            DWORD dwFlags;
            TCHAR[32] szDevice;
        }
        
        alias POINTL = POINT;
        
        struct DEVMODE {
            BYTE[32] dmDeviceName;
            WORD   dmSpecVersion;
            WORD   dmDriverVersion;
            WORD   dmSize;
            WORD   dmDriverExtra;
            DWORD  dmFields;
            union {
                struct {
                    short dmOrientation;
                    short dmPaperSize;
                    short dmPaperLength;
                    short dmPaperWidth;
                    short dmScale;
                    short dmCopies;
                    short dmDefaultSource;
                    short dmPrintQuality;
                }
                POINTL dmPosition;
                DWORD  dmDisplayOrientation;
                DWORD  dmDisplayFixedOutput;
            }
            short  dmColor;
            short  dmDuplex;
            short  dmYResolution;
            short  dmTTOption;
            short  dmCollate;
            BYTE[32]   dmFormName;
            WORD   dmLogPixels;
            DWORD  dmBitsPerPel;
            DWORD  dmPelsWidth;
            DWORD  dmPelsHeight;
            union {
                DWORD  dmDisplayFlags;
                DWORD  dmNup;
            }
            DWORD  dmDisplayFrequency;
            DWORD  dmICMMethod;
            DWORD  dmICMIntent;
            DWORD  dmMediaType;
            DWORD  dmDitherType;
            DWORD  dmReserved1;
            DWORD  dmReserved2;
            DWORD  dmPanningWidth;
            DWORD  dmPanningHeight;
        }
        
        struct ICONINFO {
            bool fIcon;
            DWORD xHotspot;
            DWORD yHotspot;
            HBITMAP hbmMask;
            HBITMAP hbmColor;
        }
        
        struct MENUITEMINFO {
            UINT      cbSize;
            UINT      fMask;
            UINT      fType;
            UINT      fState;
            UINT      wID;
            HMENU     hSubMenu;
            HBITMAP   hbmpChecked;
            HBITMAP   hbmpUnchecked;
            ULONG_PTR dwItemData;
            LPTSTR    dwTypeData;
            UINT      cch;
            HBITMAP   hbmpItem;
        }

        struct NOTIFYICONDATAW {
            DWORD cbSize;
            HWND  hWnd;
            UINT  uID;
            UINT  uFlags;
            UINT  uCallbackMessage;
            HICON hIcon;
            WCHAR[128] szTip;
            DWORD dwState;
            DWORD dwStateMask;
            WCHAR[256] szInfo;
            union {
                UINT uTimeout;
                UINT uVersion;
            }
            WCHAR[64] szInfoTitle;
            DWORD dwInfoFlags;
            GUID  guidItem;
            HICON hBalloonIcon;
        }

        struct GUID {
            DWORD Data1;
            WORD  Data2;
            WORD  Data3;
            BYTE[8]  Data4;
        }
        
        extern(Windows) {
            alias MONITORENUMPROC = bool function(HMONITOR, HDC, LPRECT, LPARAM);
            alias WNDENUMPROC = bool function(HWND, LPARAM);
            
            extern {
                bool GetMonitorInfoW(HMONITOR, MONITORINFOEX*);
                bool EnumDisplayMonitors(HDC, LPRECT, MONITORENUMPROC, LPARAM);
                bool GetMonitorInfoA(HMONITOR, MONITORINFOEX*);
                bool EnumDisplaySettingsA(char*, DWORD, DEVMODE*);
                HDC CreateDCA(char*, char*, char*, DEVMODE*);
                HBITMAP CreateCompatibleBitmap(HDC, int, int);
                bool BitBlt(HDC, int, int, int, int, HDC, int, int, DWORD);
                int GetDIBits(HDC, HBITMAP, uint, uint, void*, BITMAPINFO*, uint);
                bool EnumWindows(WNDENUMPROC, LPARAM);
                HMONITOR MonitorFromWindow(HWND, DWORD);
                HMENU GetMenu(HWND);
                LONG GetWindowLongA(HWND, int);
                int GetWindowTextLengthW(HWND);
                int GetWindowTextW(HWND, wchar*, int);
                BOOL SetWindowTextW(HWND, wchar*);
                bool CloseWindow(HWND);
                bool IsWindowVisible(HWND);
                DWORD GetClassLongA(HWND, int);
                bool GetIconInfo(HICON, ICONINFO*);
                HICON CreateIconIndirect(ICONINFO*);
                HBITMAP CreateBitmap(int, int, uint, uint, void*);
                bool DestroyIcon(HICON);
                bool ModifyMenuA(HMENU, uint, uint, void*, void*);
                int GetMenuStringW(HMENU, uint, void*, int, uint);
                uint GetMenuState(HMENU, uint, uint);
                bool GetMenuItemInfoA(HMENU, uint, bool, MENUITEMINFO*);
                bool DeleteMenu(HMENU, uint, uint);
                bool RemoveMenu(HMENU, uint, uint);
                bool AppendMenuA(HMENU, uint, UINT_PTR, void*);
                HMENU CreatePopupMenu();
                bool GetClassInfoExW(HINSTANCE, wchar*, WNDCLASSEXW*);
                LONG GetWindowLongW(HWND hWnd,int nIndex) nothrow;
                LONG SetWindowLongW(HWND hWnd,int nIndex,LONG dwNewLong) nothrow;
                DWORD MsgWaitForMultipleObjectsEx(DWORD nCount, const(HANDLE) *pHandles, DWORD dwMilliseconds, DWORD dwWakeMask, DWORD dwFlags);
                
                version(X86_64){
                    LONG_PTR SetWindowLongPtrW(HWND, int, LONG_PTR) nothrow;
                    LONG_PTR GetWindowLongPtrW(HWND, int) nothrow;
                } else {
                    alias GetWindowLongPtrW = GetWindowLongW;
                    alias SetWindowLongPtrW = SetWindowLongW;
                }
                
                bool DestroyCursor(HCURSOR);
                HANDLE LoadImageW(HINSTANCE, wchar*, uint, int, int, uint);
                HCURSOR CreateCursor(HINSTANCE, int, int, int, int, void*, void*);
                bool Shell_NotifyIconW(DWORD, NOTIFYICONDATAW*);
                HWND GetDesktopWindow();
            }
            
            struct GetDisplays {
                IAllocator alloc;
                IPlatform platform;
                
                IDisplay[] displays;
                
                void call() {
                    EnumDisplayMonitors(null, null, &callbackGetDisplays, cast(LPARAM)cast(void*)&this);
                }
            }
            
            bool callbackGetDisplays(HMONITOR hMonitor, HDC, LPRECT, LPARAM lParam) {
                GetDisplays* ctx = cast(GetDisplays*)lParam;
                
                IDisplay display = ctx.alloc.make!DisplayImpl(hMonitor, ctx.alloc, ctx.platform);
                
                ctx.alloc.expandArray(ctx.displays, 1);
                ctx.displays[$-1] = display;
                
                return true;
            }
            
            struct GetWindows {
                IAllocator alloc;
                
                IPlatform platform;
                IDisplay display;
                
                IWindow[] windows;
                
                void call() {
                    EnumWindows(&callbackGetWindows, cast(LPARAM)&this);
                }
            }
            
            bool callbackGetWindows(HWND hwnd, LPARAM lParam) {
                GetWindows* ctx = cast(GetWindows*)lParam;
                
                if (!IsWindowVisible(hwnd))
                    return true;
                
                RECT rect;
                GetWindowRect(hwnd, &rect);
                
                if (rect.right - rect.left == 0 || rect.bottom - rect.top == 0)
                    return true;
                
                WindowImpl window = ctx.alloc.make!WindowImpl(hwnd, cast(IContext)null, ctx.alloc, ctx.platform);
                
                if (ctx.display is null) {
                    ctx.alloc.expandArray(ctx.windows, 1);
                    ctx.windows[$-1] = window;
                } else {
                    IDisplay display2 = (cast(IWindow)window).display;
                    if (display2 is null) {
                        ctx.alloc.dispose(window);
                        return true;
                    }
                    
                    if (display2.name == ctx.display.name) {
                        ctx.alloc.expandArray(ctx.windows, 1);
                        ctx.windows[$-1] = window;
                    } else
                        ctx.alloc.dispose(window);
                }
                
                return true;
            }
            
            LRESULT callbackWindowHandler(HWND hwnd, uint uMsg, WPARAM wParam, LPARAM lParam) nothrow {
                WindowImpl window = cast(WindowImpl)cast(void*)GetWindowLongPtrW(hwnd, GWLP_USERDATA);

                switch(uMsg) {
                    case WM_DESTROY:
                        return 0;
                    case WM_SETCURSOR:
                        if (LOWORD(lParam) == HTCLIENT && window.cursorStyle != WindowCursorStyle.Underterminate) {
                            SetCursor(window.hCursor);
                            return 1;
                        } else
                            return DefWindowProcW(hwnd, uMsg, wParam, lParam);
                    case WM_SIZE:
                    case WM_EXITSIZEMOVE:
                        InvalidateRgn(hwnd, null, true);
                        // TODO: event
                        return 0;
                    case WM_ERASEBKGND:
                    case WM_PAINT:
                        import std.experimental.platform : onDrawDel;

                        if (onDrawDel is null || window.context_ is null) {
                            // This fixes a bug where when a window is fullscreen Windows
                            //  will not auto draw the background of a window.
                            // If the context is not yet assigned or VRAM, it
                            //  should default to this.

                            PAINTSTRUCT ps;
                            HDC hdc = BeginPaint(hwnd, &ps);
                            FillRect(hdc, &ps.rcPaint, cast(HBRUSH) (COLOR_WINDOW+1));
                            EndPaint(hwnd, &ps);
                        } else {
                            try {
                            onDrawDel();
                            } catch (Exception e) {}

                            ValidateRgn(hwnd, null);
                        }

                        return 0;
                    default:
                        return DefWindowProcW(hwnd, uMsg, wParam, lParam);
                }
                
                assert(0);
            }
        }
        
        ImageStorage!RGB8 screenshotImpl(IAllocator alloc, HDC hFrom, vec2!ushort size_) {
            HDC hMemoryDC = CreateCompatibleDC(hFrom);
            HBITMAP hBitmap = CreateCompatibleBitmap(hFrom, size_.x, size_.y);
            
            HBITMAP hOldBitmap = SelectObject(hMemoryDC, hBitmap);
            BitBlt(hMemoryDC, 0, 0, size_.x, size_.y, hFrom, 0, 0, SRCCOPY);
            
            auto storage = bitmapToImage(hBitmap, hMemoryDC, vec2!size_t(size_.x, size_.y), alloc);
            
            hBitmap = SelectObject(hMemoryDC, hOldBitmap);
            DeleteDC(hMemoryDC);
            
            return storage;
        }
        
        ImageStorage!RGB8 bitmapToImage(HBITMAP hBitmap, HDC hMemoryDC, vec2!size_t size_, IAllocator alloc) {
            import std.experimental.graphic.image.storage.base : ImageStorageHorizontal;
            import std.experimental.graphic.image.interfaces : imageObject;
            
            size_t dwBmpSize = ((size_.x * 32 + 31) / 32) * 4 * size_.y;
            ubyte[] buffer = alloc.makeArray!ubyte(dwBmpSize);
            auto storage = imageObject!(ImageStorageHorizontal!RGB8)(size_.x, size_.y, alloc);
            
            BITMAPINFOHEADER bi;
            
            bi.biSize = BITMAPINFOHEADER.sizeof;
            bi.biWidth = cast(int)size_.x;
            bi.biHeight = cast(int)size_.y;
            bi.biPlanes = 1;
            bi.biBitCount = 32;
            bi.biCompression = BI_RGB;
            bi.biSizeImage = 0;
            bi.biXPelsPerMeter = 0;
            bi.biYPelsPerMeter = 0;
            bi.biClrUsed = 0;
            bi.biClrImportant = 0;
            
            BITMAPINFO bitmapInfo;
            bitmapInfo.bmiHeader = bi;
            
            GetDIBits(hMemoryDC, hBitmap, 0, cast(int)size_.y, buffer.ptr, &bitmapInfo, DIB_RGB_COLORS);
            
            size_t x;
            size_t y = size_.y-1;
            for(size_t i = 0; i < buffer.length; i += 4) {
                RGB8 c = RGB8(buffer[i+2], buffer[i+1], buffer[i]);
                
                storage[x, y] = c;
                
                x++;
                if (x == size_.x) {
                    x = 0;
                    if (y == 0)
                        break;
                    y--;
                }
            }
            
            alloc.dispose(buffer);
            return storage;
        }
        
        ImageStorage!RGBA8 bitmapToAlphaImage(HBITMAP hBitmap, HDC hMemoryDC, vec2!size_t size_, IAllocator alloc) {
            import std.experimental.graphic.image.storage.base : ImageStorageHorizontal;
            import std.experimental.graphic.image.interfaces : imageObject;
            
            size_t dwBmpSize = ((size_.x * 32 + 31) / 32) * 4 * size_.y;
            ubyte[] buffer = alloc.makeArray!ubyte(dwBmpSize);
            auto storage = imageObject!(ImageStorageHorizontal!RGBA8)(size_.x, size_.y, alloc);
            
            BITMAPINFOHEADER bi;
            
            bi.biSize = BITMAPINFOHEADER.sizeof;
            bi.biWidth = cast(int)size_.x;
            bi.biHeight = cast(int)size_.y;
            bi.biPlanes = 1;
            bi.biBitCount = 32;
            bi.biCompression = BI_RGB;
            bi.biSizeImage = 0;
            bi.biXPelsPerMeter = 0;
            bi.biYPelsPerMeter = 0;
            bi.biClrUsed = 0;
            bi.biClrImportant = 0;
            
            BITMAPINFO bitmapInfo;
            bitmapInfo.bmiHeader = bi;
            
            GetDIBits(hMemoryDC, hBitmap, 0, cast(int)size_.y, buffer.ptr, &bitmapInfo, DIB_RGB_COLORS);
            
            size_t x;
            size_t y = size_.y-1;
            for(size_t i = 0; i < buffer.length; i += 4) {
                RGBA8 c = RGBA8(buffer[i+2], buffer[i+1], buffer[i], 255);
                
                storage[x, y] = c;
                
                x++;
                if (x == size_.x) {
                    x = 0;
                    if (y == 0)
                        break;
                    y--;
                }
            }
            
            alloc.dispose(buffer);
            return storage;
        }
        
        HBITMAP imageToBitmap(ImageStorage!RGB8 from, HDC hMemoryDC, IAllocator alloc) {
            size_t dwBmpSize = ((from.width * 32 + 31) / 32) * 4 * from.height;
            ubyte[] buffer = alloc.makeArray!ubyte(dwBmpSize);
            
            HICON ret;
            
            size_t x;
            size_t y = from.height-1;
            for(size_t i = 0; i < buffer.length; i += 4) {
                RGB8 c = from[x, y];
                
                buffer[i] = c.b;
                buffer[i+1] = c.g;
                buffer[i+2] = c.r;
                buffer[i+3] = 255;
                
                x++;
                if (x == from.width) {
                    x = 0;
                    if (y == 0)
                        break;
                    y--;
                }
            }
            
            HBITMAP hBitmap = CreateBitmap(cast(uint)from.width, cast(uint)from.height, 1, 32, buffer.ptr);
            alloc.dispose(buffer);
            return hBitmap;
        }
        
        HBITMAP imageToAlphaBitmap(ImageStorage!RGBA8 from, HDC hMemoryDC, IAllocator alloc) {
            size_t dwBmpSize = ((from.width * 32 + 31) / 32) * 4 * from.height;
            ubyte[] buffer = alloc.makeArray!ubyte(dwBmpSize);
            
            HICON ret;
            
            size_t x;
            size_t y = from.height-1;
            for(size_t i = 0; i < buffer.length; i += 4) {
                RGBA8 c = from[x, y];
                
                buffer[i] = c.b;
                buffer[i+1] = c.g;
                buffer[i+2] = c.r;
                buffer[i+3] = c.a;
                
                x++;
                if (x == from.width) {
                    x = 0;
                    if (y == 0)
                        break;
                    y--;
                }
            }
            
            HBITMAP hBitmap = CreateBitmap(cast(uint)from.width, cast(uint)from.height, 1, 32, buffer.ptr);
            alloc.dispose(buffer);
            return hBitmap;
        }
        
        HICON imageToIcon(ImageStorage!RGBA8 from, HDC hMemoryDC, IAllocator alloc) {
            HBITMAP hBitmap = imageToAlphaBitmap(from, hMemoryDC, alloc);
            HICON ret = bitmapToIcon(hBitmap, hMemoryDC, vec2!size_t(from.width, from.height));
            
            scope(exit)
                DeleteObject(hBitmap);
            
            return ret;
        }
        
        HICON bitmapToIcon(HBITMAP hBitmap, HDC hMemoryDC, vec2!size_t size_) {
            HICON ret;
            HBITMAP hbmMask = CreateCompatibleBitmap(hMemoryDC, cast(uint)size_.x, cast(uint)size_.y);
            
            ICONINFO ii;
            ii.fIcon = true;
            ii.hbmColor = hBitmap;
            ii.hbmMask = hbmMask;
            
            ret = CreateIconIndirect(&ii);
            
            DeleteObject(hbmMask);
            
            return ret;
        }
        
        HBITMAP resizeBitmap(HBITMAP hBitmap, HDC hDC, vec2!size_t toSize, vec2!size_t fromSize) {
            HDC hMemDC1 = CreateCompatibleDC(hDC);
            HBITMAP hBitmap1 = CreateCompatibleBitmap(hDC, cast(int)toSize.x, cast(int)toSize.y);
            HGDIOBJ hOld1 = SelectObject(hMemDC1, hBitmap1);
            
            HDC hMemDC2 = CreateCompatibleDC(hDC);
            HGDIOBJ hOld2 = SelectObject(hMemDC2, hBitmap);
            
            BITMAP bitmap;
            GetObjectW(hBitmap, BITMAP.sizeof, &bitmap);
            
            StretchBlt(hMemDC1, 0, 0, cast(int)toSize.x, cast(int)toSize.y, hMemDC2, 0, 0, cast(int)fromSize.x, cast(int)fromSize.y, SRCCOPY);
            
            SelectObject(hMemDC1, hOld1);
            SelectObject(hMemDC2, hOld2);
            DeleteDC(hMemDC1);
            DeleteDC(hMemDC2);
            
            return hBitmap1;
        }
    }
    
    final class DisplayImpl : IDisplay, Feature_ScreenShot, Have_ScreenShot {
        private {
            IAllocator alloc;
            IPlatform platform;
            
            char[] name_;
            bool primaryDisplay_;
            vec2!ushort size_;
            uint refreshRate_;
            
            version(Windows) {
                HMONITOR hMonitor;
            }
        }
        
        version(Windows) {
            this(HMONITOR hMonitor, IAllocator alloc, IPlatform platform) {
                import std.string : fromStringz;
                
                this.alloc = alloc;
                this.platform = platform;
                
                this.hMonitor = hMonitor;

                MONITORINFOEX info;
                info.cbSize = MONITORINFOEX.sizeof;
                GetMonitorInfoA(hMonitor, &info);

                char[] temp = info.szDevice.ptr.fromStringz;
                name_ = alloc.makeArray!char(temp.length + 1);
                name_[0 .. $-1] = temp[];
                name_[$-1] = '\0';
                
                size_.x = cast(ushort)(info.rcMonitor.right - info.rcMonitor.left);
                size_.y = cast(ushort)(info.rcMonitor.bottom - info.rcMonitor.top);
                
                primaryDisplay_ = (info.dwFlags & MONITORINFOF_PRIMARY) == MONITORINFOF_PRIMARY;

                DEVMODE devMode;
                devMode.dmSize = DEVMODE.sizeof;
                EnumDisplaySettingsA(name_.ptr, ENUM_CURRENT_SETTINGS, &devMode);
                refreshRate_ = devMode.dmDisplayFrequency;
            }
        }
        
        @property {
            string name() { return cast(immutable)name_[0 .. $-1]; }
            vec2!ushort size() { return size_; }
            uint refreshRate() { return refreshRate_; }
            
            DummyRefCount!(IWindow[]) windows() {
                version(Windows) {
                    GetWindows ctx = GetWindows(alloc, cast()platform, cast()this);
                    ctx.call;
                    return DummyRefCount!(IWindow[])(ctx.windows, alloc);
                } else
                    assert(0);
            }
            
            bool primary() { return primaryDisplay_; }
            
            IDisplay dup(IAllocator alloc) {
                version(Windows) {
                    return alloc.make!DisplayImpl(hMonitor, alloc, platform);
                } else
                    assert(0);
            }
            
            void* __handle() {
                version(Windows) {
                    return &hMonitor;
                } else
                    assert(0);
            }
        }
        
        Feature_ScreenShot __getFeatureScreenShot() {
            version(Windows)
                return this;
            else
                return null;
        }
        
        ImageStorage!RGB8 screenshot(IAllocator alloc = null) {
            if (alloc is null)
                alloc = this.alloc;
            
            version(Windows) {
                HDC hScreenDC = CreateDCA(name_.ptr, null, null, null);
                auto storage = screenshotImpl(alloc, hScreenDC, size_);
                DeleteDC(hScreenDC);
                return storage;
            } else {
                assert(0);
            }
        }
    }
    
    final class WindowImpl : IWindow, Feature_ScreenShot, Feature_Icon, Feature_Menu, Feature_Cursor, Feature_Style, Have_ScreenShot, Have_Icon, Have_Menu, Have_Cursor, Have_Style {
        private {
            import std.experimental.internal.containers.map;
            import std.traits : isSomeString;
            
            IPlatform platform;
            IAllocator alloc;
            IContext context_;
            
            AllocList!MenuItemImpl menuItems;
            uint menuItemsCount;
            AAMap!(uint, MenuCallback) menuCallbacks;
            
            bool redrawMenu;
            
            WindowCursorStyle cursorStyle;
            ImageStorage!RGBA8 customCursor;
            
            WindowStyle windowStyle;
            
            version(Windows) {
                HWND hwnd;
                HMENU hMenu;
                HCURSOR hCursor;
            }
        }
        
        version(Windows) {
            this(HWND hwnd, IContext context, IAllocator alloc, IPlatform platform, HMENU hMenu=null, bool processOwns=false) {
                this.hwnd = hwnd;
                this.platform = platform;
                this.alloc = alloc;
                this.context_ = context;
                this.hMenu = hMenu;
                
                if (hMenu !is null)
                    menuItems = AllocList!MenuItemImpl(alloc);
                
                menuItemsCount = 9000;
                
                if (processOwns)
                    hCursor = LoadImageW(null, cast(wchar*)IDC_APPSTARTING, IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED);
                else
                    cursorStyle = WindowCursorStyle.Underterminate;
            }
        }
        
        ~this() {
            if (menuItems.length > 0) {
                foreach(item; menuItems) {
                    item.remove();
                }
            }
        }
        
        @property {
            DummyRefCount!(dchar[]) title() {
                import std.utf : byDchar;
                
                version(Windows) {
                    int textLength = GetWindowTextLengthW(hwnd);
                    wchar[] buffer = alloc.makeArray!wchar(textLength + 1);
                    GetWindowTextW(hwnd, buffer.ptr, cast(int)buffer.length);
                    
                    // what is allocated could potentially be _more_ then required
                    dchar[] buffer2 = alloc.makeArray!dchar(textLength + 1);
                    
                    size_t i;
                    foreach(c; buffer.byDchar) {
                        if (i > buffer2.length) {
                            alloc.expandArray(buffer2, 1);
                        }
                        
                        buffer2[i] = c;
                        i++;
                    }
                    
                    // removes the last character (\0)
                    if (i < buffer2.length - 1) {
                        alloc.shrinkArray(buffer2, buffer.length - i);
                    }
                    
                    alloc.dispose(buffer);
                    return DummyRefCount!(dchar[])(buffer2, alloc);
                } else
                    assert(0);
            }
            
            void title(string text) { setTitle(text); }
            void title(wstring text) { setTitle(text); }
            void title(dstring text) { setTitle(text); }
            
            final void setTitle(String)(String text) if (isSomeString!String) {
                import std.utf : byWchar;
            
                version(Windows) {
                    wchar[] buffer = alloc.makeArray!wchar((text.length + 1) * 2);
                    
                    size_t i;
                    foreach(c; text.byWchar) {
                        if (i > buffer.length) {
                            alloc.expandArray(buffer, 1);
                        }
                        
                        buffer[i] = c;
                        i++;
                    }
                    
                    if (i == buffer.length)
                        alloc.expandArray(buffer, 1);
                    buffer[$-1] = 0;
                    
                    SetWindowTextW(hwnd, buffer.ptr);
                    alloc.dispose(buffer);
                } else
                    assert(0);
            }
            
            UIPoint size() {
                version(Windows) {
                    RECT rect;
                    GetClientRect(hwnd, &rect);
                    return UIPoint(cast(short)rect.right, cast(short)rect.bottom);
                } else
                    assert(0);
            }
            
            void location(UIPoint point) {
                version(Windows) {
                    SetWindowPos(hwnd, null, point.x, point.y, 0, 0, SWP_NOSIZE);
                } else
                    assert(0);
            }
            
            UIPoint location() {
                version(Windows) {
                    RECT rect;
                    GetWindowRect(hwnd, &rect);
                    return UIPoint(cast(short)rect.left, cast(short)rect.top);
                } else
                    assert(0);
            }
            
            void size(UIPoint point) {
                version(Windows) {
                    RECT rect;
                    rect.top = point.x;
                    rect.bottom = point.y;
                    
                    assert(AdjustWindowRectEx(&rect, GetWindowLongA(hwnd, GWL_STYLE), GetMenu(hwnd) !is null, GetWindowLongA(hwnd, GWL_EXSTYLE)));
                    SetWindowPos(hwnd, null, 0, 0, rect.right, rect.bottom, SWP_NOMOVE);
                } else
                    assert(0);
            }
            
            bool visible() {
                version(Windows)
                    return IsWindowVisible(hwnd);
                else
                    assert(0);
            }
            
            // display can and will most likely change during runtime
            DummyRefCount!IDisplay display() {
                version(Windows) {
                    HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONULL);
                    if (monitor is null)
                        return DummyRefCount!IDisplay(null, null);
                    else
                        return DummyRefCount!IDisplay(alloc.make!DisplayImpl(monitor, alloc, platform),  alloc);
                } else
                    assert(0);
            }
            
            IContext context() { return context_; }
            
            void* __handle() {
                version(Windows)
                    return &hwnd;
                else
                    assert(0);
            }
            
            IAllocator allocator() { return alloc; }
        }
        
        void hide() {
            version(Windows)
                ShowWindow(hwnd, SW_HIDE);
            else
                assert(0);
        }
        
        void show() {
            version(Windows) {
                ShowWindow(hwnd, SW_SHOW);
                UpdateWindow(hwnd);
            } else
                assert(0);
        }
        
        void close() {
            version(Windows)
                CloseWindow(hwnd);
            else
                assert(0);
        }
        
        // features
        
        Feature_ScreenShot __getFeatureScreenShot() {
            version(Windows)
                return this;
            else
                return null;
        }
        
        ImageStorage!RGB8 screenshot(IAllocator alloc=null) {
            if (alloc is null)
                alloc = this.alloc;
            
            version(Windows) {
                HDC hWindowDC = GetDC(hwnd);
                auto storage = screenshotImpl(alloc, hWindowDC, cast(vec2!ushort)size());
                ReleaseDC(hwnd, hWindowDC);
                return storage;
            } else {
                assert(0);
            }
        }
        
        Feature_Icon __getFeatureIcon() {
            version(Windows)
                return this;
            else
                return null;
        }
        
        ImageStorage!RGBA8 getIcon() @property {
            version(Windows) {
                HICON hIcon = cast(HICON)GetClassLongA(hwnd, GCL_HICON);
                ICONINFO iconinfo;
                GetIconInfo(hIcon, &iconinfo);
                HBITMAP hBitmap = iconinfo.hbmColor;
                
                BITMAP bm;
                GetObjectA(hBitmap, BITMAP.sizeof, &bm);
                
                HDC hFrom = GetDC(null);
                HDC hMemoryDC = CreateCompatibleDC(hFrom);
                
                scope(exit) {
                    DeleteDC(hMemoryDC);
                    ReleaseDC(null, hFrom);
                }
                
                return bitmapToAlphaImage(hBitmap, hMemoryDC, vec2!size_t(bm.bmWidth, bm.bmHeight), alloc);
            } else
                assert(0);
        }
        
        void setIcon(ImageStorage!RGBA8 from) @property {
            version(Windows) {
                HICON hIcon = cast(HICON)GetClassLongA(hwnd, GCL_HICON);
                if (hIcon)
                    DestroyIcon(hIcon);
                
                HDC hFrom = GetDC(null);
                HDC hMemoryDC = CreateCompatibleDC(hFrom);
                
                hIcon = imageToIcon(from, hMemoryDC, alloc);
                
                if (hIcon) {
                    SendMessageA(hwnd, WM_SETICON, cast(WPARAM)ICON_BIG, cast(LPARAM)hIcon);
                    SendMessageA(hwnd, WM_SETICON, cast(WPARAM)ICON_SMALL, cast(LPARAM)hIcon);
                }
                
                DeleteDC(hMemoryDC);
                ReleaseDC(null, hFrom);
            } else
                assert(0);
        }
        
        Feature_Menu __getFeatureMenu() {
            version(Windows) {
                if (hMenu is null)
                    return null;
                else
                    return this;
            } else
                assert(0);
        }
        
        MenuItem addItem() {
            version(Windows) {
                auto ret = alloc.make!MenuItemImpl(this, hMenu);
            } else
                assert(0);
            menuItems ~= ret;
            return ret;
        }
        
        @property immutable(MenuItem[]) items() {
            return cast(immutable(MenuItem[]))menuItems.__internalValues;
        }
        
        Feature_Cursor __getFeatureCursor() {
            version(Windows)
                return this;
            else
                assert(0);
        }
        
        void setCursor(WindowCursorStyle style) {
            assert(cursorStyle != WindowCursorStyle.Underterminate);
            
            version(Windows) {
                if (cursorStyle == WindowCursorStyle.Custom) {
                    // unload systemy stuff
                    DestroyCursor(hCursor);
                    //FIXME: alloc.dispose(customCursor);
                }
                
                cursorStyle = style;
                
                if (style != WindowCursorStyle.Custom) {
                    // load up reference to system one
                    
                    switch(style) {
                        case WindowCursorStyle.Busy:
                            hCursor = LoadImageW(null, cast(wchar*)IDC_WAIT, IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED);
                            break;
                        case WindowCursorStyle.Hand:
                            hCursor = LoadImageW(null, cast(wchar*)IDC_HAND, IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED);
                            break;
                        case WindowCursorStyle.NoAction:
                            hCursor = LoadImageW(null, cast(wchar*)IDC_NO, IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED);
                            break;
                        case WindowCursorStyle.ResizeCornerLeft:
                            hCursor = LoadImageW(null, cast(wchar*)IDC_SIZENESW, IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED);
                            break;
                        case WindowCursorStyle.ResizeCornerRight:
                            hCursor = LoadImageW(null, cast(wchar*)IDC_SIZENWSE, IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED);
                            break;
                        case WindowCursorStyle.ResizeHorizontal:
                            hCursor = LoadImageW(null, cast(wchar*)IDC_SIZEWE, IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED);
                            break;
                        case WindowCursorStyle.ResizeVertical:
                            hCursor = LoadImageW(null, cast(wchar*)IDC_SIZENS, IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED);
                            break;
                        case WindowCursorStyle.None:
                            hCursor = null;
                            break;
                        case WindowCursorStyle.Standard:
                        default:
                            hCursor = LoadImageW(null, cast(wchar*)IDC_ARROW, IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED);
                            break;
                    }
                }
            } else
                assert(0);
        }
        
        WindowCursorStyle getCursor() {
            version(Windows) {
                return cursorStyle;
            } else
                assert(0);
        }
        
        void setCustomCursor(ImageStorage!RGBA8 image) {
            import std.experimental.graphic.image.storage.base : ImageStorageHorizontal;
            import std.experimental.graphic.image.interfaces : imageObjectFrom;
            
            assert(cursorStyle != WindowCursorStyle.Underterminate);
            
            version(Windows) {
                // The comments here specify the preferred way to do this.
                // Unfortunately at the time of writing, it is not possible to
                //  use std.experimental.graphic.image for resizing.
                
                setCursor(WindowCursorStyle.Custom);
                
                HDC hFrom = GetDC(null);
                HDC hMemoryDC = CreateCompatibleDC(hFrom);
                
                // duplicate image, store
                //FIXME: customCursor = imageObjectFrom!(ImageStorageHorizontal!RGBA8)(image, alloc);
                
                // customCursor must be a set size, as defined by:
                vec2!size_t toSize = vec2!size_t(GetSystemMetrics(SM_CXCURSOR), GetSystemMetrics(SM_CYCURSOR));
                
                // so customCursor must be resized to the given size
                
                // load systemy copy of image
                // imageToIcon
                
                HBITMAP hBitmap = imageToAlphaBitmap(image, hMemoryDC, alloc);
                HBITMAP hBitmap2 = resizeBitmap(hBitmap, hMemoryDC, toSize, vec2!size_t(image.width, image.height));
                HICON hIcon = bitmapToIcon(hBitmap2, hMemoryDC, toSize);
                
                // GetIconInfo
                
                ICONINFO ii;
                GetIconInfo(hIcon, &ii);
                
                // CreateCursor
                
                hCursor = CreateCursor(null, ii.xHotspot, ii.yHotspot, cast(int)toSize.x, cast(int)toSize.y, ii.hbmColor, ii.hbmMask);
                
                DeleteObject(hBitmap);
                DeleteObject(hBitmap2);
                DeleteDC(hMemoryDC);
                ReleaseDC(null, hFrom);
            } else
                assert(0);
        }
        
        ImageStorage!RGBA8 getCursorIcon() {
            version(Windows) {
                return customCursor;
            } else
                assert(0);
        }
        
        Feature_Style __getFeatureStyle() {
            version(Windows) {
                return this;
            } else
                assert(0);
        }
        
        void setStyle(WindowStyle style) {
            windowStyle = style;
            
            version(Windows) {
                RECT rect;
                DWORD dwStyle, dwExStyle;
                
                switch(style) {
                    case WindowStyle.Fullscreen:
                        dwStyle = WindowDWStyles.Fullscreen;
                        dwExStyle = WindowDWStyles.FullscreenEx;
                        break;
                
                    case WindowStyle.Popup:
                        dwStyle = WindowDWStyles.Popup;
                        dwExStyle = WindowDWStyles.PopupEx;
                        break;
                
                    case WindowStyle.Borderless:
                        dwStyle = WindowDWStyles.Borderless;
                        dwExStyle = WindowDWStyles.BorderlessEx;
                        break;
                
                    case WindowStyle.Dialog:
                    default:
                        dwStyle = WindowDWStyles.Dialog;
                        dwExStyle = WindowDWStyles.DialogEx;
                        break;
                }
                
                // multiple monitors support
                
                UIPoint setpos = location();
                MONITORINFOEX mi;
                mi.cbSize = MONITORINFOEX.sizeof;
                
                HMONITOR hMonitor = *cast(HMONITOR*)display().__handle;
                GetMonitorInfoA(hMonitor, &mi);
                
                if (windowStyle == WindowStyle.Fullscreen) {
                    rect = mi.rcMonitor;
                    
                    setpos.x = cast(short)rect.left;
                    setpos.y = cast(short)rect.top;
                }
                
                setpos.x -= rect.left;
                setpos.y -= rect.top;
                
                if (windowStyle != WindowStyle.Fullscreen) {
                    AdjustWindowRectEx(&rect, dwStyle, false, dwExStyle);
                }
                
                // multiple monitors support
                
                SetWindowLongW(hwnd, GWL_STYLE, dwStyle);
                SetWindowLongW(hwnd, GWL_EXSTYLE, dwExStyle);
                SetWindowPos(hwnd, null, setpos.x, setpos.y, rect.right - rect.left, rect.bottom - rect.top, SWP_NOCOPYBITS | SWP_NOZORDER | SWP_NOOWNERZORDER);
                
                if (windowStyle == WindowStyle.Fullscreen) {
                    SetWindowPos(hwnd, cast(HWND)0 /*HWND_TOP*/, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOOWNERZORDER);
                }
            } else
                assert(0);
        }
        
        WindowStyle getStyle() {
            return windowStyle;
        }
    }
    
    final class MenuItemImpl : MenuItem {
        private {
            WindowImpl window;
            AllocList!MenuItemImpl menuItems;
            
            uint menuItemId;
            MenuItemImpl parentMenuItem;
            
            version(Windows) {
                HMENU parent;
                HMENU myChildren;
                HBITMAP lastBitmap;
            }
        }
        
        version(Windows) {
            this(WindowImpl window, HMENU parent, MenuItemImpl parentMenuItem=null) {
                this.window = window;
                this.parent = parent;
                this.parentMenuItem = parentMenuItem;
                
                menuItemId = window.menuItemsCount;
                window.menuItemsCount++;
                
                AppendMenuA(parent, 0, menuItemId, null);
                window.redrawMenu = true;
            }
        }
        
        override MenuItem addChildItem() {
            version(Windows) {
                if (myChildren is null) {
                    myChildren = CreatePopupMenu();
                }
                
                ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_POPUP, myChildren, null);
                return window.alloc.make!MenuItemImpl(window, myChildren, this);
            }
        }
        
        override void remove() {
            version(Windows) {
                foreach(sub; menuItems) {
                    sub.remove();
                }
                
                menuItems.length = 0;
                
                RemoveMenu(parent, menuItemId, MF_BYCOMMAND);
                DeleteMenu(parent, menuItemId, MF_BYCOMMAND);
                
                if (parentMenuItem is null)
                    window.menuItems.remove(this);
                else
                    parentMenuItem.menuItems.remove(this);
                
                window.menuCallbacks.remove(menuItemId);
                if (lastBitmap !is null)
                    DeleteObject(lastBitmap);
                
                window.redrawMenu = true;
                window.alloc.dispose(this);
            }
        }
        
        @property {
            override immutable(MenuItem[]) childItems() {
                return cast(immutable(MenuItem[]))menuItems.__internalValues;
            }
            
            override DummyRefCount!(ImageStorage!RGB8) image() {
                version(Windows) {
                    MENUITEMINFO mmi;
                    mmi.cbSize = MENUITEMINFO.sizeof;
                    GetMenuItemInfoA(parent, menuItemId, false, &mmi);
                    
                    HDC hFrom = GetDC(null);
                    HDC hMemoryDC = CreateCompatibleDC(hFrom);
                    
                    scope(exit) {
                        DeleteDC(hMemoryDC);
                        ReleaseDC(window.hwnd, hFrom);
                    }
                    
                    BITMAP bm;
                    GetObjectA(mmi.hbmpItem, BITMAP.sizeof, &bm);
                    
                    return DummyRefCount!(ImageStorage!RGB8)(bitmapToImage(mmi.hbmpItem, hMemoryDC, vec2!size_t(bm.bmWidth, bm.bmHeight), window.alloc), window.alloc);
                }
            }
            
            override void image(ImageStorage!RGB8 input) {
                version(Windows) {
                    HDC hFrom = GetDC(null);
                    HDC hMemoryDC = CreateCompatibleDC(hFrom);
                    
                    scope(exit) {
                        DeleteDC(hMemoryDC);
                        ReleaseDC(window.hwnd, hFrom);
                    }
                    
                    HBITMAP bitmap = imageToBitmap(input, hMemoryDC, window.alloc);
                    ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_BITMAP, null, bitmap);
                    
                    if (lastBitmap !is null)
                        DeleteObject(lastBitmap);
                    lastBitmap = bitmap;
                }
                window.redrawMenu = true;
            }
            
            override DummyRefCount!(dchar[]) text() {
                version(Windows) {
                    wchar[32] buffer;
                    int length = GetMenuStringW(parent, menuItemId, buffer.ptr, buffer.length, MF_BYCOMMAND);
                    assert(length >= 0);
                    
                    dchar[] buffer2 = window.alloc.makeArray!dchar(length);
                    buffer2[0 .. length] = cast(dchar[])buffer[0 .. length];
                    
                    return DummyRefCount!(dchar[])(buffer2, window.alloc);
                }
            }
            
            private void setText(T)(T input) {
                version(Windows) {
                    import std.utf : byWchar;
                    
                    wchar[] buffer = window.alloc.makeArray!wchar(input.length);
                    
                    size_t i;
                    foreach(c; input.byWchar) {
                        if (i > buffer.length)
                            window.alloc.expandArray(buffer, 1);
                        
                        buffer[i] = c;
                        i++;
                    }
                    
                    window.alloc.expandArray(buffer, 1); // \0 last byte
                    buffer[$-1] = '\0';
                    
                    ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_STRING, null, buffer.ptr);
                    window.alloc.dispose(buffer);
                }
                window.redrawMenu = true;
            }
            
            override void text(dstring input) {
                version(Windows) {
                    setText(input);
                }
            }
            
            override void text(wstring input) {
                version(Windows) {
                    setText(input);
                }
            }
            override void text(string input) {
                version(Windows) {
                    setText(input);
                }
            }
            
            override bool devider() {
                version(Windows) {
                    return (GetMenuState(parent, menuItemId, MF_BYCOMMAND) & MF_SEPARATOR) == MF_SEPARATOR;
                }
            }
            
            override void devider(bool v) {
                version(Windows) {
                    if (v)
                        ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_SEPARATOR, null, null);
                    else
                        ModifyMenuA(parent, menuItemId, MF_BYCOMMAND & ~MF_SEPARATOR, null, null);
                }
                window.redrawMenu = true;
            }
            
            override bool disabled() {
                version(Windows) {
                    return (GetMenuState(parent, menuItemId, MF_BYCOMMAND) & MF_DISABLED) == MF_DISABLED;
                }
            }
            
            override void disabled(bool v) {
                version(Windows) {
                    if (v)
                        ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_DISABLED, null, null);
                    else
                        ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_ENABLED, null, null);
                }
                window.redrawMenu = true;
            }
            
            override void callback(MenuCallback callback) {
                window.menuCallbacks[menuItemId] = callback;
            }
        }
    }
    
    final class WindowCreatorImpl : IWindowCreator, Have_Icon, Have_Cursor, Have_Style, Have_VRamCtx, Feature_Icon, Feature_Cursor, Feature_Style {
        private {
            WindowPlatformImpl platform;
            
            UIPoint size_ = UIPoint(cast(short)800, cast(short)600);
            UIPoint location_;
            IDisplay display_;
            IAllocator alloc;
            
            ImageStorage!RGBA8 icon;
            
            WindowCursorStyle cursorStyle = WindowCursorStyle.Standard;
            ImageStorage!RGBA8 cursorIcon;
            
            WindowStyle windowStyle = WindowStyle.Dialog;

            bool useVRAMContext, vramWithAlpha;
        }
        
        this(WindowPlatformImpl platform, IAllocator alloc) {
            this.alloc = alloc;
            this.platform = platform;

            useVRAMContext = true;
        }
        
        @property {
            void size(UIPoint v) { size_ = v; }
            void location(UIPoint v) { location_ = v; }
            void display(IDisplay v) { display_ = v; }
            void allocator(IAllocator v) { alloc = v; }
        }
        
        IRenderPoint create() {
            return cast(IRenderPoint)createWindow;
        }
        
        IWindow createWindow() {
            auto primaryDisplay = platform.primaryDisplay;

            import std.stdio;

            version(Windows) {
                WNDCLASSEXW wndClass;
                wndClass.cbSize = WNDCLASSEXW.sizeof;
                HINSTANCE hInstance = GetModuleHandleW(null);
                
                // not currently being set/used, so for now lets stub it out
                IContext context = null;
                HMENU hMenu = null;

                if (GetClassInfoExW(hInstance, cast(wchar*)ClassNameW.ptr, &wndClass) == 0) {
                    wndClass.cbSize = WNDCLASSEXW.sizeof;
                    wndClass.hInstance = hInstance;
                    wndClass.lpszClassName = cast(wchar*)ClassNameW.ptr;
                    wndClass.hCursor = LoadImageW(null, cast(wchar*)IDC_ARROW, IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED);
                    wndClass.style = CS_OWNDC/+ | CS_HREDRAW | CS_VREDRAW+/; // causes flickering
                    wndClass.lpfnWndProc = &callbackWindowHandler;
                    
                    RegisterClassExW(&wndClass);
                }

                RECT rect;
                rect.right = size_.x;
                rect.bottom = size_.y;
                
                DWORD dwStyle, dwExStyle;
                
                switch(windowStyle) {
                    case WindowStyle.Fullscreen:
                        dwStyle = WindowDWStyles.Fullscreen;
                        dwExStyle = WindowDWStyles.FullscreenEx;
                        break;
                
                    case WindowStyle.Popup:
                        dwStyle = WindowDWStyles.Popup;
                        dwExStyle = WindowDWStyles.PopupEx;
                        break;
                
                    case WindowStyle.Borderless:
                        dwStyle = WindowDWStyles.Borderless;
                        dwExStyle = WindowDWStyles.BorderlessEx;
                        break;
                
                    case WindowStyle.Dialog:
                    default:
                        dwStyle = WindowDWStyles.Dialog;
                        dwExStyle = WindowDWStyles.DialogEx;
                        break;
                }

                // multiple monitor support
                
                UIPoint setpos = location_;
                MONITORINFOEX mi;
                mi.cbSize = MONITORINFOEX.sizeof;

                HMONITOR hMonitor;
                if (display_ is null)
                    hMonitor = *cast(HMONITOR*)primaryDisplay.__handle;
                else
                    hMonitor = *cast(HMONITOR*)display_.__handle;
                GetMonitorInfoA(hMonitor, &mi);

                if (windowStyle == WindowStyle.Fullscreen) {
                    rect = mi.rcMonitor;
                    
                    setpos.x = cast(short)rect.left;
                    setpos.y = cast(short)rect.top;
                }
                
                setpos.x -= rect.left;
                setpos.y -= rect.top;

                if (windowStyle != WindowStyle.Fullscreen) {
                    AdjustWindowRectEx(&rect, dwStyle, false, dwExStyle);
                }

                // multiple monitor support
                
                HWND hwnd = CreateWindowExW(
                    dwExStyle,
                    cast(wchar*)ClassNameW.ptr,
                    null,
                    dwStyle,
                    setpos.x, setpos.y,
                    rect.right - rect.left, rect.bottom - rect.top,
                    null,
                    null,
                    hInstance,
                    null);

                if (useVRAMContext) {
                    context = alloc.make!VRAMContextImpl(hwnd, vramWithAlpha, alloc);
                }

                WindowImpl ret = alloc.make!WindowImpl(hwnd, context, alloc, platform, hMenu, true);
                SetWindowLongPtrW(hwnd, GWLP_USERDATA, cast(size_t)cast(void*)ret);
                if (icon !is null)
                    ret.setIcon(icon);

                if (cursorStyle == WindowCursorStyle.Custom)
                    ret.setCustomCursor(cursorIcon);
                else
                    ret.setCursor(cursorStyle);

                InvalidateRgn(hwnd, null, true);

                return ret;
            } else
                assert(0);
        }
        
        // features
        
        Feature_Icon __getFeatureIcon() {
            version(Windows) {
                return this;
            } else
                assert(0);
        }
        
        Feature_Cursor __getFeatureCursor() {
            version(Windows)
                return this;
            else
                assert(0);
        }
        
        @property {
            ImageStorage!RGBA8 getIcon() { return icon; }
            void setIcon(ImageStorage!RGBA8 v) { icon = v; }
        }
        
        void setCursor(WindowCursorStyle v) { cursorStyle = v; }
        WindowCursorStyle getCursor() { return cursorStyle; }
        
        void setCustomCursor(ImageStorage!RGBA8 v) {
            cursorStyle = WindowCursorStyle.Custom;
            cursorIcon = v;
        }
        
        ImageStorage!RGBA8 getCursorIcon() { return cursorIcon; }
        
        Feature_Style __getFeatureStyle() {
            version(Windows)
                return this;
            else
                assert(0);
        }
        
        void setStyle(WindowStyle style) {
            windowStyle = style;
        }
    
        WindowStyle getStyle() {
            return windowStyle;
        }

        void assignVRamContext(bool withAlpha=false) {
            useVRAMContext = true;
            vramWithAlpha = withAlpha;
        }
    }

    final class VRAMContextImpl : IContext, Have_VRam, Feature_VRam {
        import std.experimental.graphic.image.interfaces : SwappableImage, imageObject;
        import std.experimental.graphic.image.storage.flat;

        private {
            bool assignedAlpha;

            // how we exposed the storage
            ImageStorage!RGB8 storage2;
            ImageStorage!RGBA8 alphaStorage2;

            // the intermediary between the exposed (pixel format) and the actual supported one
            SwappableImage!RGB8 storage3 = void;
            SwappableImage!RGBA8 alphaStorage3 = void;

            version(Windows) {
                import std.experimental.graphic.color.rgb : BGR8, BGRA8;

                HWND hwnd;
                HDC hdc, hdcMem;

                // where the actual pixels are stored
                FlatImageStorage!BGR8 storage1 = void;
                FlatImageStorage!BGRA8 alphaStorage1 = void;
            }
        }

        // sets up our internal image buffer
        this(bool assignAlpha, size_t width, size_t height, IAllocator alloc) {
            assignedAlpha = assignAlpha;

            if (assignAlpha) {
                // create the actual storage
                alphaStorage1 = FlatImageStorage!BGRA8(width, height, alloc);

                // we need to do a bit of magic to translate the colors
                storage3 = SwappableImage!RGB8(&alphaStorage1, alloc);
                storage2 = imageObject(&storage3, alloc);

                alphaStorage3 = SwappableImage!RGBA8(&alphaStorage1, alloc);
                alphaStorage2 = imageObject(&alphaStorage3, alloc);
            } else {
                // create the actual storage
                storage1 = FlatImageStorage!BGR8(width, height, alloc);

                // we need to do a bit of magic to translate the colors
                storage3 = SwappableImage!RGB8(&storage1, alloc);
                storage2 = imageObject(&storage3, alloc);
                
                alphaStorage3 = SwappableImage!RGBA8(&storage1, alloc);
                alphaStorage2 = imageObject(&alphaStorage3, alloc);
            }
        }

        version(Windows) {
            this(HWND hwnd, bool assignAlpha, IAllocator alloc) {
                this(true, 1, 1, alloc);

                this.hwnd = hwnd;

                hdc = GetDC(hwnd);
                hdcMem = CreateCompatibleDC(hdc);
                swapBuffers();
            }
        }

        @property {
            ImageStorage!RGB8 vramBuffer() { return storage2; }
            ImageStorage!RGBA8 vramAlphaBuffer() { return alphaStorage2; }
        }

        Feature_VRam __getFeatureVRam() {
            return this;
        }

        void swapBuffers() {
            version(Windows) {
                if (!IsWindowVisible(hwnd))
                    return;

                ubyte* bufferPtr;
                uint bitsCount;

                if (assignedAlpha) {
                    bitsCount = 32;
                    bufferPtr = cast(ubyte*)alphaStorage1.__pixelsRawArray.ptr;
                } else {
                    bitsCount = 24;
                    bufferPtr = cast(ubyte*)storage1.__pixelsRawArray.ptr;
                }

                RECT windowRect;
                GetClientRect(hwnd, &windowRect);

                HBITMAP hBitmap = CreateBitmap(cast(uint)storage2.width, cast(uint)storage2.height, 1, bitsCount, bufferPtr);

                HGDIOBJ oldBitmap = SelectObject(hdcMem, hBitmap);

                HBITMAP bitmap;
                GetObjectA(hBitmap, HBITMAP.sizeof, &bitmap);

                StretchBlt(hdc, 0, 0, cast(uint)storage2.width, cast(uint)storage2.height, hdcMem, 0, 0, cast(uint)windowRect.right, cast(uint)windowRect.bottom, SRCCOPY);

                SelectObject(hdcMem, oldBitmap);
                DeleteObject(hBitmap);

                if (windowRect.right != storage2.width || windowRect.bottom != storage2.height) {
                    if (assignedAlpha) {
                        alphaStorage1.resize(windowRect.right, windowRect.bottom);
                    } else {
                        storage1.resize(windowRect.right, windowRect.bottom);
                    }
                }

                InvalidateRgn(hwnd, null, true);
            } else
                assert(0);
        }
    }
}
