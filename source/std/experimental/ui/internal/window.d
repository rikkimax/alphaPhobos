module std.experimental.ui.internal.window;
import std.experimental.memory.managed;
import std.experimental.ui.rendering : IContext;
import std.experimental.platform : IPlatform;
import std.experimental.allocator : IAllocator;

private {
	import std.experimental.ui.internal.defs;
	import std.experimental.ui.window.features;
	import std.experimental.ui.window.styles;
	import std.experimental.ui.events;
	import std.experimental.ui.window.events;
	import std.experimental.ui.window.defs;
	
	version(Windows) {
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

		interface WindowInterfaces : IWindowEvents, Feature_ScreenShot, Feature_Icon, Feature_Menu, Feature_Cursor, Feature_Style, Have_ScreenShot, Have_Icon, Have_Menu, Have_Cursor, Have_Style {}
	}
}

package(std.experimental.ui.internal) {
	final class WindowImpl : IWindow, WindowInterfaces {
		import std.experimental.containers.map;
		import std.experimental.containers.list;
		import std.experimental.ui.internal.native_menu;
		import std.experimental.ui.internal.display;
		import std.traits : isSomeString;
		
		IPlatform platform;
		IAllocator alloc;
		IContext context_;
		
		List!MenuItem menuItems = void;
		uint menuItemsCount;
		Map!(uint, MenuCallback) menuCallbacks = void;
		
		bool redrawMenu;

		// IRenderEvents
		EventOnForcedDrawDel onDrawDel;
		EventOnCursorMoveDel onCursorMoveDel;
		EventOnCursorActionDel onCursorActionDel, onCursorActionEndDel;
		EventOnScrollDel onScrollDel;
		EventOnCloseDel onCloseDel;
		EventOnKeyDel onKeyEntryDel;
		EventOnSizeChangeDel onSizeChangeDel;
		EventOnMoveDel onMoveDel;

		WindowCursorStyle cursorStyle;
		ImageStorage!RGBA8 customCursor;
		
		WindowStyle windowStyle;
		bool ownedByProcess;
		
		version(Windows) {
			HWND hwnd;
			HMENU hMenu;
			HCURSOR hCursor;

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
		}
		
		~this() {
			if (menuItems.length > 0) {
				foreach(item; menuItems) {
					item.remove();
				}
			}
		}
		
		@property {
			managed!dstring title() {
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
					return managed!dstring(cast(dstring)buffer2, managers(), Ownership.Secondary, alloc);
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
			
			vec2!ushort size() {
				version(Windows) {
					RECT rect;
					GetClientRect(hwnd, &rect);
					return vec2!ushort(cast(ushort)rect.right, cast(ushort)rect.bottom);
				} else
					assert(0);
			}
			
			void location(vec2!short point) {
				version(Windows) {
					SetWindowPos(hwnd, null, point.x, point.y, 0, 0, SWP_NOSIZE);
				} else
					assert(0);
			}
			
			vec2!short location() {
				version(Windows) {
					RECT rect;
					GetWindowRect(hwnd, &rect);
					return vec2!short(cast(short)rect.left, cast(short)rect.top);
				} else
					assert(0);
			}
			
			void size(vec2!ushort point) {
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
					return cast(bool)IsWindowVisible(hwnd);
				else
					assert(0);
			}
			
			// display can and will most likely change during runtime
			managed!IDisplay display() {
				import std.typecons : tuple;
				
				version(Windows) {
					HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONULL);
					if (monitor is null)
						return (managed!IDisplay).init;
					else
						return cast(managed!IDisplay)managed!DisplayImpl(managers(), tuple(monitor, alloc, platform), alloc);
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
			
			IRenderEvents events() { return this; }
			IWindowEvents windowEvents() { return ownedByProcess ? this : null; }
			bool renderable() { return visible(); }
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
				auto ret = alloc.make!MenuItemImpl(this, hMenu, null);

				menuItems ~= ret;
				return ret;
			} else
				assert(0);
		}
		
		@property managed!(MenuItem[]) items() {
			auto ret = menuItems.opSlice();
			return cast(managed!(MenuItem[]))ret;
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
				
				vec2!short setpos = location();
				MONITORINFOEXA mi;
				mi.cbSize = MONITORINFOEXA.sizeof;
				
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
}