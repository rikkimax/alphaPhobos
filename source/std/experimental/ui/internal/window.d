module std.experimental.ui.internal.window;
import std.experimental.ui.internal.defs;
import std.experimental.ui.internal.platform;
import std.experimental.ui.internal.display;
import std.experimental.ui.window.features;
import std.experimental.ui.window.styles;
import std.experimental.ui.events;
import std.experimental.ui.window.events;
import std.experimental.ui.window.defs;
import std.experimental.containers.map;
import std.experimental.containers.list;
import std.experimental.memory.managed;
import std.experimental.ui.rendering : IContext;
import std.experimental.platform : IPlatform;
import std.experimental.allocator : IAllocator;
import std.utf : byChar, byDchar, codeLength;

abstract class WindowImpl : IWindow, IWindowEvents {
	private {
		IAllocator alloc;
		IPlatform platform;
		IContext context_;

		bool ownedByProcess;

		// IRenderEvents
		EventOnForcedDrawDel onDrawDel;
		EventOnCursorMoveDel onCursorMoveDel;
		EventOnCursorActionDel onCursorActionDel, onCursorActionEndDel;
		EventOnScrollDel onScrollDel;
		EventOnCloseDel onCloseDel;
		EventOnKeyDel onKeyEntryDel;
		EventOnSizeChangeDel onSizeChangeDel;
		EventOnMoveDel onMoveDel;
	}
	
	@property {
		IContext context() { return context_; }
		IAllocator allocator() { return alloc; }
		IRenderEvents events() { return windowEvents(); }
		IWindowEvents windowEvents() { return ownedByProcess ? this : null; }
		bool renderable() { return visible(); }
	}
	
	abstract {
		void hide();
		void show();
		void close();
		void* __handle();
		
		@property {
			managed!dstring title();
			
			void title(string text);
			void title(wstring text);
			void title(dstring text);

			bool visible();
			managed!IDisplay display();

			vec2!ushort size();
			void size(vec2!ushort);
			vec2!short location();
			void location(vec2!short);
		}
	}
	
	// IRenderEvents + IWindowEvents
	
	@property {
		void onForcedDraw(EventOnForcedDrawDel del) { onDrawDel = del; }
		void onCursorMove(EventOnCursorMoveDel del) { onCursorMoveDel = del; }
		void onCursorAction(EventOnCursorActionDel del) { onCursorActionDel = del; }
		void onCursorActionEnd(EventOnCursorActionDel del) { onCursorActionEndDel = del; }
		void onScroll(EventOnScrollDel del) { onScrollDel = del; }
		void onClose(EventOnCloseDel del) { onCloseDel = del; }
		void onKeyEntry(EventOnKeyDel del) { onKeyEntryDel = del; }
		void onSizeChange(EventOnSizeChangeDel del) { onSizeChangeDel = del; }
		
		void onMove(EventOnMoveDel del) { onMoveDel = del; }
	}
}

version(Windows) {
	final class WinAPIWindowImpl : WindowImpl, Feature_ScreenShot, Feature_Icon, Feature_Menu, Feature_Cursor, Feature_Style, Have_ScreenShot, Have_Icon, Have_Menu, Have_Cursor, Have_Style {
		import std.experimental.ui.internal.native_menu;
		import std.traits : isSomeString;
		import core.sys.windows.windows : MONITORINFOEXA, GetMonitorInfoA, MONITORINFOF_PRIMARY,
			DEVMODEA, EnumDisplaySettingsA, ENUM_CURRENT_SETTINGS, CreateDCA, HMENU, HCURSOR,
			LoadImageW, GetWindowTextLengthW, GetWindowTextW, SetWindowTextW, GetClientRect,
			SetWindowPos, AdjustWindowRectEx, MonitorFromWindow, ShowWindow, UpdateWindow,
			CloseWindow, HWND, IDC_APPSTARTING, IMAGE_CURSOR, LR_DEFAULTSIZE, LR_SHARED, SWP_NOSIZE,
			GetWindowLongA, GetMenu, SWP_NOMOVE, MONITOR_DEFAULTTONULL, SW_HIDE, SW_SHOW,
			GWL_STYLE, GWL_EXSTYLE, GetDC, ReleaseDC, GetClassLongA, GetIconInfo, GetObjectA, GetClassLongA,
			GCL_HICON, DestroyIcon, SendMessageA, WM_SETICON, ICON_BIG, ICON_SMALL, DestroyCursor,
			IDC_WAIT, IDC_HAND, IDC_NO, IDC_SIZENESW, IDC_SIZENWSE, IDC_SIZEWE, IDC_SIZENS, IDC_ARROW,
			GetSystemMetrics, CreateCursor, SetWindowLongW, SWP_NOCOPYBITS, SWP_NOZORDER, SWP_NOOWNERZORDER,
			SM_CXCURSOR, SM_CYCURSOR;
		
		package(std.experimental.ui.internal) {
			HWND hwnd;
			HMENU hMenu;
			HCURSOR hCursor;
			
			List!MenuItem menuItems = void;
			uint menuItemsCount;
			Map!(uint, MenuCallback) menuCallbacks = void;
			
			bool redrawMenu;
			WindowStyle windowStyle;
			
			WindowCursorStyle cursorStyle;
			ImageStorage!RGBA8 customCursor;
		}
		
		this(HWND hwnd, IContext context, IAllocator alloc, IPlatform platform, HMENU hMenu=null, bool processOwns=false) {
			this.hwnd = hwnd;
			this.platform = platform;
			this.alloc = alloc;
			this.context_ = context;
			this.hMenu = hMenu;
			this.ownedByProcess = processOwns;
			
			if (hMenu !is null)
				menuItems = List!MenuItem(alloc);
			
			menuCallbacks = Map!(uint, MenuCallback)(alloc);
			menuItemsCount = 9000;
			
			if (processOwns)
				hCursor = LoadImageW(null, cast(wchar*)IDC_APPSTARTING, IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED);
			else
				cursorStyle = WindowCursorStyle.Underterminate;
		}
		
		~this() {
			import std.experimental.ui.internal.platform : PlatformImpl;
			
			if (menuItems.length > 0) {
				foreach(item; menuItems) {
					item.remove();
				}
			}
		}
		
		@property {
			managed!dstring title() {
				int textLength = GetWindowTextLengthW(hwnd);
				wchar[] buffer = alloc.makeArray!wchar(textLength + 1);
				GetWindowTextW(hwnd, buffer.ptr, cast(int)buffer.length);
				
				// what is allocated could potentially be _more_ then required
				dchar[] buffer2 = alloc.makeArray!dchar(codeLength!char(buffer));
				
				size_t i;
				foreach(c; buffer.byDchar) {
					buffer2[i] = c;
					i++;
				}
				
				alloc.dispose(buffer);
				return managed!dstring(cast(dstring)buffer2, managers(), Ownership.Secondary, alloc);
			}

			void title(string text) { setTitle(text); }
			void title(wstring text) { setTitle(text); }
			void title(dstring text) { setTitle(text); }
			
			void setTitle(String)(String text) if (isSomeString!String) {
				wchar[] buffer = alloc.makeArray!wchar(codeLength!wchar(text) + 1);
				buffer[$-1] = 0;
				
				size_t i;
				foreach(c; text.byWchar) {
					buffer[i] = c;
					i++;
				}
				
				SetWindowTextW(hwnd, buffer.ptr);
				alloc.dispose(buffer);
			}
			
			vec2!ushort size() {
				RECT rect;
				GetClientRect(hwnd, &rect);
				return vec2!ushort(cast(ushort)rect.right, cast(ushort)rect.bottom);
			}
			
			void size(vec2!ushort point) {
				RECT rect;
				rect.top = point.x;
				rect.bottom = point.y;
				
				assert(AdjustWindowRectEx(&rect, GetWindowLongA(hwnd, GWL_STYLE), GetMenu(hwnd) !is null, GetWindowLongA(hwnd, GWL_EXSTYLE)));
				SetWindowPos(hwnd, null, 0, 0, rect.right, rect.bottom, SWP_NOMOVE);
			}
			
			vec2!short location() {
				RECT rect;
				GetWindowRect(hwnd, &rect);
				return vec2!short(cast(short)rect.left, cast(short)rect.top);
			}
			
			void location(vec2!short point) {
				SetWindowPos(hwnd, null, point.x, point.y, 0, 0, SWP_NOSIZE);
			}
			
			bool visible() {
				return cast(bool)IsWindowVisible(hwnd);
			}
			
			// display_ can and will most likely change during runtime
			managed!IDisplay display() {
				import std.typecons : tuple;
				
				HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONULL);
				if (monitor is null)
					return (managed!IDisplay).init;
				else
					return cast(managed!IDisplay)managed!DisplayImpl(managers(), tuple(monitor, alloc, platform), alloc);
			}
			
			void* __handle() { return &hwnd; }
		}
		
		void hide() {
			ShowWindow(hwnd, SW_HIDE);
		}
		
		void show() {
			ShowWindow(hwnd, SW_SHOW);
			UpdateWindow(hwnd);
		}
		
		void close() {
			CloseWindow(hwnd);
		}
		
		// features
		
		Feature_ScreenShot __getFeatureScreenShot() {
			return this;
		}
		
		ImageStorage!RGB8 screenshot(IAllocator alloc=null) {
			if (alloc is null)
				alloc = this.alloc;
			
			HDC hWindowDC = GetDC(hwnd);
			auto storage = screenshotImpl(alloc, hWindowDC, cast(vec2!ushort)size());
			ReleaseDC(hwnd, hWindowDC);
			return storage;
		}
		
		Feature_Icon __getFeatureIcon() {
			return this;
		}
		
		ImageStorage!RGBA8 getIcon() @property {
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
		}
		
		void setIcon(ImageStorage!RGBA8 from) @property {
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
		}
		
		Feature_Menu __getFeatureMenu() {
			if (hMenu is null)
				return null;
			else
				return this;
		}
		
		MenuItem addItem() {
			auto ret = alloc.make!MenuItemImpl(this, hMenu, null);
			
			menuItems ~= ret;
			return ret;
		}
		
		@property managed!(MenuItem[]) items() {
			auto ret = menuItems.opSlice();
			return cast(managed!(MenuItem[]))ret;
		}
		
		Feature_Cursor __getFeatureCursor() {
			return this;
		}
		
		void setCursor(WindowCursorStyle style) {
			assert(cursorStyle != WindowCursorStyle.Underterminate);
			
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
		}
		
		WindowCursorStyle getCursor() {
			return cursorStyle;
		}
		
		void setCustomCursor(ImageStorage!RGBA8 image) {
			import std.experimental.graphic.image.storage.base : ImageStorageHorizontal;
			import std.experimental.graphic.image.interfaces : imageObjectFrom;
			
			assert(cursorStyle != WindowCursorStyle.Underterminate);
			
			// The comments here specify the preferred way to do this.
			// Unfortunately at the time of writing, it is not possible to
			//  use std.experimental.graphic.image for resizing.
			
			setCursor(WindowCursorStyle.Custom);
			
			HDC hFrom = GetDC(null);
			HDC hMemoryDC = CreateCompatibleDC(hFrom);
			
			// duplicate image, store
			customCursor = imageObjectFrom!(ImageStorageHorizontal!RGBA8)(image, alloc);
			
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
		}
		
		ImageStorage!RGBA8 getCursorIcon() {
			return customCursor;
		}
		
		Feature_Style __getFeatureStyle() {
			return this;
		}
		
		void setStyle(WindowStyle style) {
			windowStyle = style;
			
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
			
			vec2!short setpos = location();
			MONITORINFOEXA mi;
			mi.cbSize = MONITORINFOEXA.sizeof;
			
			HMONITOR hMonitor = *cast(HMONITOR*)display_().__handle;
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
		}
		
		WindowStyle getStyle() {
			return windowStyle;
		}
	}
}

final class X11WindowImpl : WindowImpl {
	import std.experimental.bindings.x11;
	import std.traits : isSomeString, ReturnType;
	
	Window windowHandle;
	Display* display_;
	Atom closeAtom;
	XIC xic;
	
	vec2!ushort lastSize;
	vec2!short lastLocation;
	
	bool hadUpEventHandled, hasBeenClosed_;

	char[256] gotKeyBuffer;
	ushort activeKeyModifiers;
	uint keyPreviousState, keyPreviousKeyCode;
	ReturnType!(byDchar!(char[])) previousActiveKeys;
	
	void processEvent(XEvent* e) {
		KeyModifiers convertKeyFromXlibEventModifiers(uint code) {
			KeyModifiers ret;
			
			if (code & Mod1Mask)
				ret |= KeyModifiers.Alt;
			if (code & ControlMask)
				ret |= KeyModifiers.Control;
			if (code & ShiftMask || code & LockMask)
				ret |= KeyModifiers.Shift;
			
			return ret;
		}
		
		if (e.type == Expose) {
			onDrawDel();
		} else if (e.type == ConfigureNotify) {
			if (lastLocation.x != e.xconfigure.x || lastLocation.y != e.xconfigure.y) {
				lastLocation = vec2!short(cast(short)e.xconfigure.x, cast(short)e.xconfigure.y);
				onMoveDel(lastLocation.x, lastLocation.y);
			}
			
			if (lastSize.x != e.xconfigure.width || lastSize.y != e.xconfigure.height) {
				lastSize = vec2!ushort(cast(ushort)e.xconfigure.width, cast(ushort)e.xconfigure.height);
				onSizeChangeDel(lastSize.x, lastSize.y);
			}
		} else if (e.type == ClientMessage) {
			if (e.xclient.data.l[0] == closeAtom) {
				close();
				onCloseDel();
			}
		} else if (e.type == MotionNotify) {
			onCursorMoveDel(cast(short)e.xmotion.x, cast(short)e.xmotion.y);
		} else if (e.type == ButtonPress) {
			CursorEventAction cEvent;
			
			switch(e.xbutton.button) {
				case Button2:
					cEvent = CursorEventAction.ViewChange;
					break;
					
				case Button3:
					cEvent = CursorEventAction.Alter;
					break;
					
				case Button1:
				default:
					cEvent = CursorEventAction.Select;
					break;
			}
			
			onCursorActionDel(cEvent);
		} else if (e.type == ButtonRelease) {
			CursorEventAction cEvent;
			
			switch(e.xbutton.button) {
				case Button2:
					cEvent = CursorEventAction.ViewChange;
					break;
					
				case Button3:
					cEvent = CursorEventAction.Alter;
					break;
					
				case Button1:
				default:
					cEvent = CursorEventAction.Select;
					break;
			}
			
			onCursorActionEndDel(cEvent);
		} else if (e.type == KeyPress) {
			if (!hadUpEventHandled && e.xkey.keycode == keyPreviousKeyCode && e.xkey.state == keyPreviousState)
				return;
			else {
				hadUpEventHandled = false;
				keyPreviousKeyCode = e.xkey.keycode;
				keyPreviousState = e.xkey.state;
			}
			
			SpecialKey specialKey;
			ushort keyModifiers;
			
			previousActiveKeys = translateKeyCallXLib(e, xic, specialKey, keyModifiers, gotKeyBuffer[0 .. 256]);
			
			// if keyModifiers does not contain generic KeyModifiers
			//   remove them from activeKeyModifiers
			keyModifiers |= activeKeyModifiers;
			
			foreach(dchar c; previousActiveKeys.save) {
				onKeyEntryDel(c, specialKey, activeKeyModifiers);
			}
		} else if (e.type == KeyRelease) {
			XEvent gotEvent;
			
			if (XCheckIfEvent(display_, &gotEvent, &X11CheckEventKeyPress, &e.xkey) == False) {
				// take decoded event from previous KeyPress
				// call event delegate key up
				
				hadUpEventHandled = true;
			}
		}
	}

	override void hide() {
		assert(!hasBeenClosed_);
		XUnmapWindow(display_, windowHandle);
	}

	override void show() {
		assert(!hasBeenClosed_);
		XMapWindow(display_, windowHandle);
	}

	override void close() {
		hide();
		(cast(PlatformImpl)platform).x11Windows.remove(windowHandle);
		XDestroyWindow(display_, windowHandle);
		hasBeenClosed_ = true;
	}

	override void* __handle() { return cast(void*)windowHandle; }
	
	@property {
		override bool visible() {
			XWindowAttributes winAttr;
			XGetWindowAttributes(display_, windowHandle, &winAttr);

			return winAttr.map_state == IsViewable;
		}

		override managed!dstring title() {
			import core.stdc.string : strlen;
			char* tcret;
			
			if (XFetchName(display_, windowHandle, &tcret) == BadWindow) {
				return managed!dstring.init;
			} else {
				size_t length = strlen(tcret);
				
				if (length == 0)
					return managed!dstring.init;
				else {
					dchar[] buffer2 = alloc.makeArray!dchar(codeLength!dchar(tcret[0 .. length]));

					size_t i;
					foreach(c; tcret[0 .. length].byDchar) {
						buffer2[i] = c;
						i++;
					}
					
					return managed!dstring(cast(dstring)buffer2, managers(), Ownership.Secondary, alloc);
				}
			}
		}

		override void title(string text) { setTitle(text); }
		override void title(wstring text) { setTitle(text); }
		override void title(dstring text) { setTitle(text); }

		void setTitle(String)(String text) if (isSomeString!String) {
			char[] buffer = alloc.makeArray!char(codeLength!char(text) + 1);
			buffer[$-1] = 0;
			
			size_t i;
			foreach(c; text.byChar) {
				buffer[i] = c;
				i++;
			}
			
			XStoreName(display_, windowHandle, buffer.ptr);
			alloc.dispose(buffer);
		}
		
		override vec2!ushort size() {
			Window rootWindow;
			int x, y;
			uint width, height;
			uint borderWidth, depth;

			XGetGeometry(display_, windowHandle, &rootWindow, &x, &y, &width, &height, &borderWidth, &depth);
			
			return vec2!ushort(cast(ushort)width, cast(ushort)height);
		}
		
		override void size(vec2!ushort point) {
			XResizeWindow(display_, windowHandle, point.x, point.y);
			XFlush(display_);
		}
		
		override vec2!short location() {
			Window rootWindow;
			int x, y;
			uint width, height;
			uint borderWidth, depth;
			
			XGetGeometry(display_, windowHandle, &rootWindow, &x, &y, &width, &height, &borderWidth, &depth);
			
			return vec2!short(cast(short)x, cast(short)y);
		}
		
		override void location(vec2!short point) {
			XMoveWindow(display_, windowHandle, point.x, point.y);
			XFlush(display_);
		}
	}
}