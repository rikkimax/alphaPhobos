module std.experimental.ui.internal.defs;

package(std.experimental.ui.internal) {
	import std.experimental.allocator : IAllocator, make, makeArray, expandArray, dispose;
	import std.experimental.ui.window.defs : IWindow;
	import std.experimental.ui.rendering : IDisplay;
	import std.experimental.ui.events : KeyModifiers, SpecialKey, EventOnKeyDel;
	import std.experimental.platform : IPlatform;
	import std.experimental.graphic.image : ImageStorage;
	import std.experimental.math.linearalgebra.vector : vec2;
	import std.experimental.graphic.color : RGB8, RGBA8;

	enum EnabledEventLoops : ushort {
		None = 1 << 0,
		Windows = 1 << 1,
		X11 = 1 << 2,
		Cocoa = 1 << 3,
		Wayland = 1 << 4,
		Epoll = 1 << 5,
		LibEvent = 1 << 6,
		MIR = 1 << 7,
		XCB = 1 << 8
	}

	version(Windows) {
		import core.sys.windows.windows : DWORD, BOOL, HANDLE, LPDWORD, HMONITOR, WCHAR,
			WS_OVERLAPPED, WS_CAPTION, WS_SYSMENU, WS_THICKFRAME, WS_MINIMIZEBOX, WS_MAXIMIZEBOX,
			WS_EX_ACCEPTFILES, WS_EX_APPWINDOW, WS_POPUPWINDOW, WS_BORDER, WS_EX_TOPMOST,
			WS_POPUP, WS_CLIPCHILDREN, WS_CLIPSIBLINGS, HWND, LPARAM, HDC, RECT, GetWindowRect,
			LPRECT, EnumDisplayMonitors, EnumWindows, WPARAM, HIWORD, GetKeyState,
			VK_LMENU, VK_RMENU, VK_LCONTROL, VK_RCONTROL, VK_LSHIFT, VK_RSHIFT, VK_CAPITAL,
			VK_NUMLOCK, VK_LWIN, VK_RWIN, VK_NUMPAD0, VK_NUMPAD9, LOWORD,
			VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_F1, VK_F12, VK_OEM_1, VK_OEM_2, VK_OEM_PLUS,
			VK_OEM_MINUS, VK_OEM_COMMA, VK_OEM_PERIOD, VK_OEM_7, VK_OEM_5, VK_DECIMAL,
			VK_ESCAPE, VK_SPACE, VK_RETURN, VK_BACK, VK_TAB, VK_PRIOR, VK_NEXT, VK_END,
			VK_HOME, VK_INSERT, VK_DELETE, VK_ADD, VK_SUBTRACT, VK_MULTIPLY, VK_DIVIDE,
			VK_PAUSE, VK_SCROLL, HBITMAP, HICON, CreateCompatibleDC, CreateCompatibleBitmap,
			SelectObject, BitBlt, DeleteDC, SRCCOPY, BITMAPINFOHEADER, BITMAPINFO, GetDIBits,
			CreateBitmap, DeleteObject, ICONINFO, CreateIconIndirect, HGDIOBJ, BITMAP, GetObjectW,
			StretchBlt, BI_RGB, DIB_RGB_COLORS, IsWindowVisible;

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

		enum {
			PHYSICAL_MONITOR_DESCRIPTION_SIZE = 128,
			Atoa = 'a' - 'A',
			MC_CAPS_BRIGHTNESS = 0x00000002,
			ClassNameW = __MODULE__ ~ ":Class\0"w,
		}

		struct PHYSICAL_MONITOR {
			HANDLE hPhysicalMonitor;
			WCHAR[PHYSICAL_MONITOR_DESCRIPTION_SIZE]  szPhysicalMonitorDescription;
		}

		extern(Windows) {
			// dxva2
			BOOL GetMonitorCapabilities(HANDLE hMonitor, LPDWORD pdwMonitorCapabilities, LPDWORD pdwSupportedColorTemperatures);
			BOOL GetMonitorBrightness(HANDLE hMonitor, LPDWORD pdwMinimumBrightness, LPDWORD pdwCurrentBrightness, LPDWORD pdwMaximumBrightness);
			BOOL GetPhysicalMonitorsFromHMONITOR(HMONITOR hMonitor, DWORD dwPhysicalMonitorArraySize, PHYSICAL_MONITOR* pPhysicalMonitorArray);
		}

		int GET_X_LPARAM(LPARAM p) { return cast(int)LOWORD(p); }
		int GET_Y_LPARAM(LPARAM p) { return cast(int)HIWORD(p); }
		short GET_WHEEL_DELTA_WPARAM(WPARAM p) { return cast(short)HIWORD(p); }

		struct GetDisplays {
			IAllocator alloc;
			IPlatform platform;
			
			IDisplay[] displays;
			
			void call() {
				EnumDisplayMonitors(null, null, &callbackGetDisplays, cast(LPARAM)cast(void*)&this);
			}
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

		extern(Windows) {
			int callbackGetDisplays(HMONITOR hMonitor, HDC, LPRECT, LPARAM lParam) nothrow {
				import std.experimental.ui.internal.display;
				GetDisplays* ctx = cast(GetDisplays*)lParam;
				
				try {
					IDisplay display = ctx.alloc.make!DisplayImpl(hMonitor, ctx.alloc, ctx.platform);
					ctx.alloc.expandArray(ctx.displays, 1);
					ctx.displays[$-1] = display;
				} catch (Exception e) {}
				
				return true;
			}

			int callbackGetWindows(HWND hwnd, LPARAM lParam) nothrow {
				import std.experimental.ui.internal.window;
				GetWindows* ctx = cast(GetWindows*)lParam;
				
				if (!IsWindowVisible(hwnd))
					return true;
				
				RECT rect;
				GetWindowRect(hwnd, &rect);

				if (rect.right - rect.left == 0 || rect.bottom - rect.top == 0)
					return true;

				try {
					WinAPIWindowImpl window = ctx.alloc.make!WinAPIWindowImpl(hwnd, cast(IContext)null, ctx.alloc, ctx.platform);
					
					if (ctx.display is null) {
						ctx.alloc.expandArray(ctx.windows, 1);
						ctx.windows[$-1] = window;
					} else {
						auto display2 = window.display;
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
				} catch(Exception e) {}
				
				return true;
			}
		}

		
		pragma(inline, true)
		void processModifiers(out ushort modifiers) nothrow {
			if (HIWORD(GetKeyState(VK_LMENU)) != 0)
				modifiers |= KeyModifiers.LAlt;
			else if (HIWORD(GetKeyState(VK_RMENU)) != 0)
				modifiers |= KeyModifiers.RAlt;
			
			if (HIWORD(GetKeyState(VK_LCONTROL)) != 0)
				modifiers |= KeyModifiers.LControl;
			else if (HIWORD(GetKeyState(VK_RCONTROL)) != 0)
				modifiers |= KeyModifiers.RControl;
			
			if (HIWORD(GetKeyState(VK_LSHIFT)) != 0)
				modifiers |= KeyModifiers.LShift;
			else if (HIWORD(GetKeyState(VK_RSHIFT)) != 0)
				modifiers |= KeyModifiers.RShift;
			
			if (GetKeyState(VK_CAPITAL) != 0)
				modifiers |= KeyModifiers.Capslock;
			
			if (GetKeyState(VK_NUMLOCK) != 0)
				modifiers |= KeyModifiers.Numlock;
			
			if (HIWORD(GetKeyState(VK_LWIN)) != 0)
				modifiers |= KeyModifiers.LSuper;
			else if (HIWORD(GetKeyState(VK_RWIN)) != 0)
				modifiers |= KeyModifiers.RSuper;
		}


		int translateKeyCall(WPARAM code, LPARAM lParam, EventOnKeyDel del) {
			dchar key = 0;
			SpecialKey specialKey = SpecialKey.None;
			ushort modifiers;
			
			bool isShift, isCapital, isCtrl;
			
			processModifiers(modifiers);
			
			isShift = (modifiers & KeyModifiers.Shift) == KeyModifiers.Shift;
			isCapital = isShift || 
				(modifiers & KeyModifiers.Capslock) == KeyModifiers.Capslock;
			isCtrl = (modifiers & KeyModifiers.Control) == KeyModifiers.Control;
			
			switch (code)
			{
				case VK_NUMPAD0: .. case VK_NUMPAD9:
					key = cast(dchar)('0' + (code - VK_NUMPAD0));
					modifiers |= KeyModifiers.Numlock; break;
				case 'A': .. case 'Z':
					if (isCtrl)
						key = cast(dchar)(isCapital ? code : (code + Atoa));
					break;
				case VK_LEFT:
					specialKey = SpecialKey.LeftArrow; break;
				case VK_RIGHT:
					specialKey = SpecialKey.RightArrow; break;
				case VK_UP:
					specialKey = SpecialKey.UpArrow; break;
				case VK_DOWN:
					specialKey = SpecialKey.DownArrow; break;
				case VK_F1: .. case VK_F12:
					specialKey =  cast(SpecialKey)(SpecialKey.F1 + (code - VK_F1)); break;
				case VK_OEM_1:
					key = isShift ? ':' : ';'; break;
				case VK_OEM_2:
					key = isShift ? '?' : '/'; break;
				case VK_OEM_PLUS:
					key = isShift ? '+' : '='; break;
				case VK_OEM_MINUS:
					key = isShift ? '_' : '-'; break;
				case VK_OEM_COMMA:
					key = isShift ? '<' : ','; break;
				case VK_OEM_PERIOD:
					key = isShift ? '>' : '.'; break;
				case VK_OEM_7:
					key = isShift ? '"' : '\''; break;
				case VK_OEM_5:
					key = isShift ? '|' : '\\'; break;
				case VK_DECIMAL:
					key = '.';
					modifiers |= KeyModifiers.Numlock; break;
				case VK_ESCAPE:
					specialKey = SpecialKey.Escape; break;
				case VK_SPACE:
					key = ' '; break;
				case VK_RETURN:
					specialKey = SpecialKey.Enter; break;
				case VK_BACK:
					specialKey = SpecialKey.Backspace; break;
				case VK_TAB:
					specialKey = SpecialKey.Tab; break;
				case VK_PRIOR:
					specialKey = SpecialKey.PageUp; break;
				case VK_NEXT:
					specialKey = SpecialKey.PageDown; break;
				case VK_END:
					specialKey = SpecialKey.End; break;
				case VK_HOME:
					specialKey = SpecialKey.Home; break;
				case VK_INSERT:
					specialKey = SpecialKey.Insert; break;
				case VK_DELETE:
					specialKey = SpecialKey.Delete; break;
				case VK_ADD:
					key = '+';
					modifiers |= KeyModifiers.Numlock; break;
				case VK_SUBTRACT:
					key = '-';
					modifiers |= KeyModifiers.Numlock; break;
				case VK_MULTIPLY:
					key = '*';
					modifiers |= KeyModifiers.Numlock; break;
				case VK_DIVIDE:
					key = '/';
					modifiers |= KeyModifiers.Numlock; break;
				case VK_PAUSE:
					specialKey = SpecialKey.Pause; break;
				case VK_SCROLL:
					specialKey = SpecialKey.ScrollLock; break;
					
				default:
					break;
			}
			
			if (key > 0 || specialKey > 0) {
				del(key, specialKey, modifiers);
				return 0;
			} else
				return -1;
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

	import std.experimental.bindings.x11 : XEvent, XIC, XPointer;
	import X11SB = std.experimental.bindings.x11;
	alias X11Bool = X11SB.Bool;
	alias X11Display = X11SB.Display;

	auto translateKeyCallXLib(XEvent* e, XIC xic, out SpecialKey specialKey, out ushort KeyModifiers, char[] buffer) {
		import std.experimental.bindings.x11;
		import std.utf : byDchar;

		KeySym keysym;
		int bufResult = Xutf8LookupString(xic, &e.xkey, buffer.ptr, cast(int)buffer.length, &keysym, null);

		switch(keysym) {
			// TODO: assign from keysym as SpecialKey when working

			default:
				specialKey = SpecialKey.None;
				break;
		}

		if (bufResult >= 0) {
			return buffer[0 .. bufResult].byDchar;
		} else {
			/// XBufferOverflow or something else kinda bad
			return buffer[0 .. 0].byDchar;
		}
	}

	extern(C) X11Bool X11CheckEventKeyPress(X11Display* display, XEvent* event, XPointer arg) {
		import std.experimental.bindings.x11 : KeyPress, XKeyEvent;
		XKeyEvent* eventPrevious = cast(XKeyEvent*)arg;
		return event.type == KeyPress && event.xkey.keycode == eventPrevious.keycode && event.xkey.time == eventPrevious.time && event.xkey.state == eventPrevious.state;
	}
}