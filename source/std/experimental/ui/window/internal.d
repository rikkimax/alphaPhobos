module std.experimental.ui.window.internal;
import std.experimental.ui.window.defs;
import std.experimental.platform : IDisplay, ImplPlatform;
import std.experimental.allocator : IAllocator, processAllocator, make, makeArray;
import std.experimental.math.linearalgebra.vector : vec2;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.ui.window.features;

package(std.experimental) {
    mixin template WindowPlatformImpl() {
        version(Windows)
            pragma(lib, "gdi32");

        IWindowCreator createWindow() {assert(0);}
        IWindow createAWindow() {assert(0);}
        
        @property {
            immutable(IDisplay) primaryDisplay() {
                foreach(display; displays) {
                    if ((cast(immutable(DisplayImpl))display).primary) {
                        return cast(immutable)display;
                    }
                }

                return null;
            }
            
            immutable(IDisplay[]) displays() {
                alloc = processAllocator();

                (cast()displays_impl_).length = 0;
                displays_impl_ = AllocList!IDisplay(cast()alloc);

                version(Windows) {
                    assert(EnumDisplayMonitors(null, null, &callbackDisplays, cast(LPARAM)cast(void*)this) > 0);
                }

                return displays_impl_.__internalValues;
            }
            
            immutable(IWindow[]) windows() {assert(0);}
        }
        
        package(std.experimental) {
            import std.experimental.internal.containers.list;
            AllocList!IDisplay displays_impl_;
            IAllocator alloc;
        }
    }

    version(Windows) {
        import core.sys.windows.windows;
        alias HMONITOR = HANDLE;

        enum MONITORINFOF_PRIMARY = 1;
        enum CCHDEVICENAME = 32;
        enum VREFRESH = 116;
        enum DWORD ENUM_CURRENT_SETTINGS = cast(DWORD)-1;

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

        alias MONITORENUMPROC = extern(Windows)bool function(HMONITOR, HDC, LPRECT, LPARAM);
        
        extern(Windows) {
            extern bool GetMonitorInfoW(HMONITOR, MONITORINFOEX*);
            extern bool EnumDisplayMonitors(HDC, LPRECT, MONITORENUMPROC, LPARAM);
            extern bool GetMonitorInfoA(HMONITOR, MONITORINFOEX*);
            extern bool EnumDisplaySettingsA(char*, DWORD, DEVMODE*);
            
            bool callbackDisplays(HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData) {
                ImplPlatform platform = cast(ImplPlatform)cast(void*)dwData;
                
                with(platform) {
                    displays_impl_ ~= alloc.make!DisplayImpl(hMonitor, hdcMonitor, alloc);
                }

                return true;
            }
        }
    }
    
    final class DisplayImpl : IDisplay {
        private {
            IAllocator alloc;
            char[] name_;
            bool primaryDisplay_;
            vec2!ushort size_;
            uint refreshRate_;

            version(Windows) {
                HMONITOR hMonitor;
                HDC hdc;
            }
        }

        version(Windows) {
            this(HMONITOR hMonitor, HDC hdc, IAllocator alloc) {
                import std.string : fromStringz;

                this.alloc = alloc;
                this.hMonitor = hMonitor;
                this.hdc = hdc;
                
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

        @property immutable {
            string name() { return cast(immutable)name_[0 .. $-1]; }
            vec2!ushort size() { return size_; }
            uint refreshRate() { return refreshRate_; }
            IWindow[] windows() { assert(0); }

            bool primary() { return primaryDisplay_; }
        }
    }

    final class WindowImpl : IWindow, Feature_ScreenShot, Feature_Icon, Have_ScreenShot, Have_Icon {
        private {
            version(Windows)
                HWND hwnd;
        }

        version(Windows) {
            this(HWND hwnd) {
                this.hwnd = hwnd;
            }
        }

        @property {
            string title();
            void title(string);
            
            UIPoint size();
            void location(UIPoint);
            
            UIPoint location();
            void size(UIPoint);
            
            IDisplay display();
            IContext context();
        }
        
        void hide();
        void show();
        void close();

        // features

        Feature_ScreenShot __getFeatureScreenShot() { return this; }
        ImageStorage!RGB8 screenshot();

        Feature_Icon __getFeatureIcon() { return this; }
        ImageStorage!RGBA8 getIcon() @property;
        void setIcon(ImageStorage!RGBA8) @property;
    }
}