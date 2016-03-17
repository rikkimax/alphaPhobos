module std.experimental.ui.internal.window_creator;

private {
	import std.experimental.ui.internal.defs;
	import std.experimental.ui.internal.window;
	import std.experimental.ui.internal.context_vram;
	import std.experimental.ui.window.features;
	import std.experimental.ui.window.events;
	import std.experimental.ui.window.styles;
	import std.experimental.ui.window.defs;
	import std.experimental.ui.context_features.vram;
	import std.experimental.ui.rendering;
	import std.experimental.ui.events;

	import std.experimental.ui.internal.platform;


	version(Windows) {
		import core.sys.windows.windows : WNDCLASSEXW, HINSTANCE, GetModuleHandleW, HMENU, HWND,
			GetClassInfoExW, RegisterClassExW, RECT, MONITORINFOEXA, HMONITOR, GetMonitorInfoA, AdjustWindowRectEx,
			LoadImageW, CS_OWNDC, CreateWindowExW, SetWindowLongPtrW, InvalidateRgn, IDC_ARROW, IMAGE_CURSOR,
			LR_DEFAULTSIZE, LR_SHARED, GWLP_USERDATA, LRESULT, GetWindowLongPtrW, WM_DESTROY, WM_SETCURSOR, HTCLIENT,
			SetCursor, DefWindowProcW, WM_SIZE, WM_EXITSIZEMOVE, WM_ERASEBKGND, WM_PAINT, PAINTSTRUCT, BeginPaint, EndPaint,
			FillRect, ValidateRgn, WM_MOUSEMOVE, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN, WM_RBUTTONUP,
			WM_MBUTTONDOWN, WM_MBUTTONUP, COLOR_WINDOW, WM_MOUSEWHEEL, WM_KEYDOWN, WM_KEYUP, WM_CHAR, HBRUSH;
		
		interface WindowCreatorInterfaces : Have_Icon, Have_Cursor, Have_Style, Have_VRamCtx, Feature_Icon, Feature_Cursor, Feature_Style {}
	}
}

final class WindowCreatorImpl : IWindowCreator, WindowCreatorInterfaces {
	package(std.experimental.ui.internal) {
		PlatformImpl platform;
		
		vec2!ushort size_ = vec2!ushort(cast(short)800, cast(short)600);
		vec2!short location_;
		IDisplay display_;
		IAllocator alloc;
		
		ImageStorage!RGBA8 icon;
		
		WindowCursorStyle cursorStyle = WindowCursorStyle.Standard;
		ImageStorage!RGBA8 cursorIcon;
		
		WindowStyle windowStyle = WindowStyle.Dialog;
		
		bool useVRAMContext, vramWithAlpha;
	}
	
	this(PlatformImpl platform, IAllocator alloc) {
		this.alloc = alloc;
		this.platform = platform;
		
		useVRAMContext = true;
	}
	
	@property {
		void size(vec2!ushort v) { size_ = v; }
		void location(vec2!short v) { location_ = v; }
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
			
			vec2!short setpos = location_;
			MONITORINFOEXA mi;
			mi.cbSize = MONITORINFOEXA.sizeof;
			
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

package(std.experimental.ui.internal) {
	version(Windows) {
		extern(Windows)
		LRESULT callbackWindowHandler(HWND hwnd, uint uMsg, WPARAM wParam, LPARAM lParam) nothrow {
			WindowImpl window = cast(WindowImpl)cast(void*)GetWindowLongPtrW(hwnd, GWLP_USERDATA);
			
			switch(uMsg) {
				case WM_DESTROY:
					if (window.onCloseDel !is null) {
						try {
							window.onCloseDel();
						} catch(Exception e) {}
					}
					return 0;
				case WM_SETCURSOR:
					if (LOWORD(lParam) == HTCLIENT && window.cursorStyle != WindowCursorStyle.Underterminate) {
						SetCursor(window.hCursor);
						return 1;
					} else
						return DefWindowProcW(hwnd, uMsg, wParam, lParam);
				case WM_SIZE:
					InvalidateRgn(hwnd, null, true);
					
					if (window.onSizeChangeDel !is null) {
						try {
							window.onSizeChangeDel(LOWORD(lParam), HIWORD(lParam));
						} catch(Exception e) {}
					}
					
					return 0;
				case WM_EXITSIZEMOVE:
					InvalidateRgn(hwnd, null, true);
					
					if (window.onSizeChangeDel !is null) {
						try {
							// the size is not passed by WinAPI :( so have to get it custom
							auto size = window.size;
							window.onSizeChangeDel(size.x, size.y);
						} catch(Exception e) {}
					}
					
					return 0;
				case WM_ERASEBKGND:
				case WM_PAINT:
					if (window.onDrawDel is null || window.context_ is null) {
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
							window.onDrawDel();
						} catch (Exception e) {}
						
						ValidateRgn(hwnd, null);
					}
					
					return 0;
				case WM_MOUSEMOVE:
					if (window.onCursorMoveDel !is null) {
						try {
							window.onCursorMoveDel(cast(short)GET_X_LPARAM(lParam), cast(short)GET_Y_LPARAM(lParam));
						} catch (Exception e) {}
					}
					return 0;
				case WM_LBUTTONDOWN:
					if (window.onCursorActionDel !is null) {
						try {
							window.onCursorActionDel(CursorEventAction.Select);
						} catch (Exception e) {}
					}
					return 0;
				case WM_LBUTTONUP:
					if (window.onCursorActionEndDel !is null) {
						try {
							window.onCursorActionEndDel(CursorEventAction.Select);
						} catch (Exception e) {}
					}
					return 0;
				case WM_RBUTTONDOWN:
					if (window.onCursorActionDel !is null) {
						try {
							window.onCursorActionDel(CursorEventAction.Alter);
						} catch (Exception e) {}
					}
					return 0;
				case WM_RBUTTONUP:
					if (window.onCursorActionEndDel !is null) {
						try {
							window.onCursorActionEndDel(CursorEventAction.Alter);
						} catch (Exception e) {}
					}
					return 0;
				case WM_MBUTTONDOWN:
					if (window.onCursorActionDel !is null) {
						try {
							window.onCursorActionDel(CursorEventAction.ViewChange);
						} catch (Exception e) {}
					}
					return 0;
				case WM_MBUTTONUP:
					if (window.onCursorActionEndDel !is null) {
						try {
							window.onCursorActionEndDel(CursorEventAction.ViewChange);
						} catch (Exception e) {}
					}
					return 0;
				case WM_MOUSEWHEEL:
					if (window.onScrollDel !is null) {
						try {
							window.onScrollDel(GET_WHEEL_DELTA_WPARAM(wParam));
						} catch (Exception e) {}
					}
					return 0;
				case WM_KEYDOWN:
					if (window.onKeyEntryDel !is null) {
						try {
							translateKeyCall(wParam, lParam, window.onKeyEntryDel);
						} catch (Exception e) {}
					}
					return 0;
				case WM_KEYUP:
					return 0;
				case WM_CHAR:
					switch(wParam) {
						case 0: .. case ' ':
						case '\\': case '|':
						case '-': case '_':
						/+case '=': +/case '+':
						case ':': .. case '?':
						case '\'': case '"':
							break;
							
						default:
							ushort modifiers;
							processModifiers(modifiers);
							EventOnKeyDel del;
							
							try {
								if (window.onKeyEntryDel !is null)
									window.onKeyEntryDel(cast(dchar)wParam, SpecialKey.None, modifiers);
							} catch (Exception e) {}
							break;
					}
					
					
					return 0;
				default:
					return DefWindowProcW(hwnd, uMsg, wParam, lParam);
			}
			
			assert(0);
		}
	}
}