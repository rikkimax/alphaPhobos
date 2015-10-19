module std.experimental.ui.window.internal;

package(std.experimental) {
    import std.experimental.internal.containers.list;
    import std.experimental.ui.window.defs;
    import std.experimental.platform : IDisplay, ImplPlatform;
    import std.experimental.allocator : IAllocator, processAllocator, theAllocator, make, makeArray, dispose;
    import std.experimental.math.linearalgebra.vector : vec2;
    import std.experimental.graphic.image : ImageStorage;
    import std.experimental.ui.window.features;
    import std.experimental.graphic.color : RGB8, RGBA8;
    import std.experimental.internal.dummyRefCount;

    mixin template WindowPlatformImpl() {
        version(Windows)
            pragma(lib, "gdi32");

        DummyRefCount!IWindowCreator createWindow(IAllocator alloc = theAllocator()) {
            return DummyRefCount!IWindowCreator(alloc.make!WindowCreatorImpl(this, alloc), alloc);
        }

        IWindow createAWindow(IAllocator alloc = theAllocator()) {assert(0);}

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

        Feature_Notification __getFeatureNotification() { return null; }
    }

    version(Windows) {
        import core.sys.windows.windows;
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
                int GetWindowTextLengthA(HWND);
                int GetWindowTextA(HWND, char*, int);
                BOOL SetWindowTextA(HWND, char*);
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
            bi.biWidth = size_.x;
            bi.biHeight = size_.y;
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

            GetDIBits(hMemoryDC, hBitmap, 0, size_.y, buffer.ptr, &bitmapInfo, DIB_RGB_COLORS);

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
            bi.biWidth = size_.x;
            bi.biHeight = size_.y;
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

            GetDIBits(hMemoryDC, hBitmap, 0, size_.y, buffer.ptr, &bitmapInfo, DIB_RGB_COLORS);

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
            HICON ret;

            HBITMAP hBitmap = imageToAlphaBitmap(from, hMemoryDC, alloc);
            HBITMAP hbmMask = CreateCompatibleBitmap(hMemoryDC, cast(uint)from.width, cast(uint)from.height);

            ICONINFO ii;
            ii.fIcon = true;
            ii.hbmColor = hBitmap;
            ii.hbmMask = hbmMask;

            ret = CreateIconIndirect(&ii);

            DeleteObject(hbmMask);
            DeleteObject(hBitmap);

            return ret;
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

                primaryDisplay_ = info.dwFlags & MONITORINFOF_PRIMARY;

                DEVMODE devMode;
                devMode.dmSize = DEVMODE.sizeof;
                assert(EnumDisplaySettingsA(name_.ptr, ENUM_CURRENT_SETTINGS, &devMode) >  0);
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

    final class WindowImpl : IWindow, Feature_ScreenShot, Feature_Icon, Feature_Menu, Have_ScreenShot, Have_Icon, Have_Menu {
        private {
            import std.experimental.internal.containers.map;

            IPlatform platform;
            IAllocator alloc;
            IContext context_;

            AllocList!MenuItemImpl menuItems;
            uint menuItemsCount;
            AAMap!(uint, MenuCallback) menuCallbacks;

            bool redrawMenu;

            version(Windows) {
                HWND hwnd;
                HMENU hMenu;
            }
        }

        version(Windows) {
            this(HWND hwnd, IContext context, IAllocator alloc, IPlatform platform, HMENU hMenu=null) {
                this.hwnd = hwnd;
                this.platform = platform;
                this.alloc = alloc;
                this.context_ = context;
                this.hMenu = hMenu;

                if (hMenu !is null)
                    menuItems = AllocList!MenuItemImpl(alloc);

                menuItemsCount = 9000;
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
            DummyRefCount!(char[]) title() {
                version(Windows) {
                    int textLength = GetWindowTextLengthA(hwnd);
                    char[] buffer = alloc.makeArray!char(textLength + 1);
                    assert(GetWindowTextA(hwnd, buffer.ptr, buffer.length) > 0);
                    alloc.shrinkArray(buffer, 1);

                    return DummyRefCount!(char[])(buffer, alloc);
                } else
                    assert(0);
            }

            void title(string text) {
                version(Windows) {
                    char[] buffer = alloc.makeArray!char(text.length + 1);
                    buffer[0 .. $-1] = text[];

                    SetWindowTextA(hwnd, buffer.ptr);
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
                    assert(GetWindowRect(hwnd, &rect));
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
            version(Windows)
                ShowWindow(hwnd, SW_SHOW);
            else
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
                    ReleaseDC(hwnd, hFrom);
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
                ReleaseDC(hwnd, hFrom);
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

    final class WindowCreatorImpl : IWindowCreator, Have_Icon, Feature_Icon {
        private {
            ImplPlatform platform;

            UIPoint size_;
            UIPoint location_;
            IDisplay display_;
            IAllocator alloc;

            ImageStorage!RGBA8 icon;
        }

        this(ImplPlatform platform, IAllocator alloc) {
            this.alloc = alloc;
            this.platform = platform;
        }

        @property {
            void size(UIPoint v) { size_ = v; }
            void location(UIPoint v) { location_ = v; }
            void display(IDisplay v) { display_ = v; }
            void allocator(IAllocator v) { alloc = v; }
        }
        
        IWindow create() {
            if (display_ is null)
                display_ = platform.primaryDisplay;

            version(Windows) {
                // TODO
                assert(0);
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

        @property {
            ImageStorage!RGBA8 getIcon() { return icon; }
            void setIcon(ImageStorage!RGBA8 v) { icon = v; }
        }
    }
}
