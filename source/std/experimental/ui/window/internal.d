module std.experimental.ui.window.internal;

package(std.experimental) {
    import std.experimental.internal.containers.list;
    import std.experimental.ui.window.defs;
    import std.experimental.platform : IDisplay, ImplPlatform;
    import std.experimental.allocator : IAllocator, processAllocator, make, makeArray, dispose;
    import std.experimental.math.linearalgebra.vector : vec2;
    import std.experimental.graphic.image : ImageStorage;
    import std.experimental.ui.window.features;
    import std.experimental.graphic.color : RGB8;
    import std.experimental.internal.dummyRefCount;

    mixin template WindowPlatformImpl() {
        version(Windows)
            pragma(lib, "gdi32");

        IWindowCreator createWindow() {assert(0);}
        IWindow createAWindow() {assert(0);}

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
                GetDisplays ctx = GetDisplays(alloc, this);
                ctx.call;
                return DummyRefCount!(IDisplay[])(ctx.displays, alloc);
            }
            
            DummyRefCount!(IWindow[]) windows(IAllocator alloc = processAllocator()) {
                GetWindows ctx = GetWindows(alloc, this, null);
                ctx.call;
                return DummyRefCount!(IWindow[])(ctx.windows, alloc);
            }
        }
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
            import std.experimental.graphic.image.storage.base : ImageStorageHorizontal;
            import std.experimental.graphic.image.interfaces : imageObject;
            
            HDC hMemoryDC = CreateCompatibleDC(hFrom);
            HBITMAP hBitmap = CreateCompatibleBitmap(hFrom, size_.x, size_.y);
            
            HBITMAP hOldBitmap = SelectObject(hMemoryDC, hBitmap);
            BitBlt(hMemoryDC, 0, 0, size_.x, size_.y, hFrom, 0, 0, SRCCOPY);
            
            size_t dwBmpSize = ((size_.x * 32 + 31) / 32) * 4 * size_.y;
            ubyte[] buffer = alloc.makeArray!ubyte(dwBmpSize);
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
            auto storage = imageObject!(ImageStorageHorizontal!RGB8)(size_.x, size_.y, alloc);
            
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
            
            hBitmap = SelectObject(hMemoryDC, hOldBitmap);
            DeleteDC(hMemoryDC);
            alloc.dispose(buffer);
            
            return storage;
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
                GetWindows ctx = GetWindows(alloc, cast()platform, cast()this);
                ctx.call;
                return DummyRefCount!(IWindow[])(ctx.windows, alloc);
            }

            bool primary() { return primaryDisplay_; }

            IDisplay dup(IAllocator alloc) {
                version(Windows) {
                    return alloc.make!DisplayImpl(hMonitor, alloc, platform);
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

    final class WindowImpl : IWindow, Feature_ScreenShot, Feature_Icon, Have_ScreenShot, Have_Icon {
        private {
            IPlatform platform;
            IAllocator alloc;
            IContext context_;

            version(Windows) {
                HWND hwnd;
            }
        }

        version(Windows) {
            this(HWND hwnd, IContext context, IAllocator alloc, IPlatform platform) {
                this.hwnd = hwnd;
                this.platform = platform;
                this.alloc = alloc;
                this.context_ = context;
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
        }
        
        void hide() {
            version(Windows)
                ShowWindow(hwnd, SW_HIDE);
            else
                return null;
        }

        void show() {
            version(Windows)
                ShowWindow(hwnd, SW_SHOW);
            else
                return null;
        }

        void close() {
            version(Windows)
                CloseWindow(hwnd);
            else
                return null;
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

        Feature_Icon __getFeatureIcon() { return this; }
        ImageStorage!RGBA8 getIcon() @property { assert(0); }
        void setIcon(ImageStorage!RGBA8) @property { assert(0); }
    }
}