﻿module std.experimental.ui.internal.platform;
import std.experimental.ui.window : IWindowCreator, IWindow;
import std.experimental.ui.rendering : IDisplay, IRenderPointCreator, IRenderPoint;
import std.experimental.platform : IPlatform, thePlatform;
import std.experimental.memory.managed;
import std.experimental.graphic.color : RGB8, RGBA8;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.allocator : IAllocator, processAllocator, theAllocator;
import std.experimental.math.linearalgebra.vector : vec2;
import std.datetime : Duration, seconds, msecs;
import std.experimental.ui.context_features.vram;

private {
	import std.experimental.ui.internal.defs;
	import std.experimental.ui.internal.window;
	import std.experimental.ui.internal.window_creator;
	import std.experimental.ui.notifications;
	import std.experimental.containers.list;
	import std.experimental.containers.map;
	import std.experimental.bindings.x11 : XEvent;

	static import X11SB = std.experimental.bindings.x11;
	alias X11Display = X11SB.Display;
	alias X11Window = X11SB.Window;

	version(Windows) {
		import core.sys.windows.windows : NOTIFYICONDATAW, MSG, DWORD,
			PeekMessageW, TranslateMessage, DispatchMessageW, PM_REMOVE,
			WAIT_TIMEOUT, INFINITE, MsgWaitForMultipleObjectsEx,
			QS_ALLEVENTS, QS_SENDMESSAGE, MWMO_ALERTABLE, MWMO_INPUTAVAILABLE,
			Shell_NotifyIconW, NIF_ICON, NIF_STATE, GetDC, ReleaseDC,
			NIM_DELETE, NIM_ADD, NIM_MODIFY, NIM_SETVERSION;
		pragma(lib, "gdi32");
		pragma(lib, "user32");

		enum NEED_GUARD_LOAD = false;
		interface PlatformInterfaces : Feature_Notification, Have_Notification {}
	} else {
		enum NEED_GUARD_LOAD = true;
		interface PlatformInterfaces {}
	}
}

/*
 * Do not forget when implementing the event loop on non Windows
 *  it will be necessary to process a second event loop e.g. kqueue or epoll.
 */

final class PlatformImpl : IPlatform, PlatformInterfaces {
	package(std.experimental.ui.internal) {
		// theoretically it is possible that you could have e.g. Wayland/X11 on a platform such as Windows
		//  but also have a Windows event loop *grrr*
		version(Windows) {
			ushort enabledEventLoops = EnabledEventLoops.Windows;
		} else {
			ushort enabledEventLoops;
		}

		IAllocator taskbarCustomIconAllocator;
		ImageStorage!RGBA8 taskbarCustomIcon;
		
		version(Windows) {
			IWindow taskbarIconWindow;
			NOTIFYICONDATAW taskbarIconNID;
		}

		List!(X11Display*) x11Displays = void;
		Map!(X11Window, WindowImpl) x11Windows = void;
	}

	private {
		// this can be safely inlined!
		pragma(inline, true)
		void guardCheck() {
			static if (NEED_GUARD_LOAD) {
				if (enabledEventLoops == 0)
					handleGuardCheck();
			} else {
				// if we don't need to check, this is a free call
			}
		}

		void handleGuardCheck() {
			import std.experimental.bindings.symbolloader : ShouldThrow;
			bool isMissing;
			ShouldThrow missingCallback(string) { isMissing = true; return ShouldThrow.No; }

			// 1. check X11
			import std.experimental.bindings.x11 : X11Loader, XrandrLoader;

			if (!X11Loader.isLoaded || !XrandrLoader.isLoaded) {
				isMissing = false;

				X11Loader.missingSymbolCallback(&missingCallback);
				X11Loader.load();

				if (!isMissing) {
					isMissing = false;
					XrandrLoader.missingSymbolCallback(&missingCallback);
					XrandrLoader.load();

					if (!isMissing) {
						x11Displays = List!(X11Display*)(theAllocator);
						enabledEventLoops |= EnabledEventLoops.X11;
					}
				}
			}

			// 2. XCB
		}
	}

	Feature_Notification __getFeatureNotification() {
		version(Windows)
			return this;
		else
			assert(0);
	}

	managed!IWindowCreator createWindow(IAllocator alloc = theAllocator()) {
		import std.typecons : tuple;
		guardCheck();
		return cast(managed!IWindowCreator)managed!WindowCreatorImpl(managers(), tuple(this, alloc), alloc);
	}
	
	IWindow createAWindow(IAllocator alloc = theAllocator()) {
		auto creator = createWindow(alloc);
		creator.size = vec2!ushort(cast(short)800, cast(short)600);
		creator.assignVRamContext;
		return creator.createWindow();
	}
	
	managed!IRenderPointCreator createRenderPoint(IAllocator alloc = theAllocator()) {
		import std.typecons : tuple;
		guardCheck();
		return cast(managed!IRenderPointCreator)managed!WindowCreatorImpl(managers(), tuple(this, alloc), alloc);
	}
	
	IRenderPoint createARenderPoint(IAllocator alloc = theAllocator()) {
		return createAWindow(alloc);
	}

	@property {
		managed!IDisplay primaryDisplay(IAllocator alloc = processAllocator()) {
			import std.experimental.ui.internal.display;
		
			foreach(display; displays) {
				if (display.isPrimary) {
					return managed!IDisplay(display, managers(), Ownership.Primary, alloc);
				}
			}
			
			return (managed!IDisplay).init;
		}
		
		managed!(IDisplay[]) displays(IAllocator alloc = processAllocator()) {
			guardCheck();

			version(Windows) {
				GetDisplays ctx = GetDisplays(alloc, this);
				ctx.call;
				return managed!(IDisplay[])(ctx.displays, managers(), Ownership.Secondary, alloc);
			} else
				assert(0);
		}
		
		managed!(IWindow[]) windows(IAllocator alloc = processAllocator()) {
			guardCheck();

			version(Windows) {
				GetWindows ctx = GetWindows(alloc, this, null);
				ctx.call;
				return managed!(IWindow[])(ctx.windows, managers(), Ownership.Secondary, alloc);
			} else
				assert(0);
		}
	}

	@property {
		ImageStorage!RGBA8 getNotificationIcon(IAllocator alloc=theAllocator) {
			import std.experimental.graphic.image.interfaces : imageObjectFrom;
			import std.experimental.graphic.image.storage.base : ImageStorageHorizontal;

			guardCheck();

			version(Windows) {
				return imageObjectFrom!(ImageStorageHorizontal!RGBA8)(taskbarCustomIcon, alloc);
			} else {
				assert(0);
			}
		}
		
		void setNotificationIcon(ImageStorage!RGBA8 icon, IAllocator alloc=theAllocator) {
			import std.experimental.graphic.image.interfaces : imageObjectFrom;
			import std.experimental.graphic.image.storage.base : ImageStorageHorizontal;
			
			guardCheck();

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

		guardCheck();

		version(Windows) {
			import core.sys.windows.windows : HDC, GetDC, CreateCompatibleDC, HWND, Shell_NotifyIconW,
				DeleteObject, DeleteDC, ReleaseDC, NIF_ICON, NIF_INFO, NIF_STATE, NIM_ADD, NIM_SETVERSION, NIM_DELETE;

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
		guardCheck();

		version(Windows) {
			// nothing needs to happen :)
		} else {
			assert(0);
		}
	}

	void optimizedEventLoop(bool delegate() callback) {
		optimizedEventLoop(5.seconds, callback);
	}
	
	void optimizedEventLoop(Duration timeout = 5.seconds, bool delegate() callback=null) {
		import std.datetime : to;
		import std.algorithm : min;
		import core.thread : Thread;

		guardCheck();
		version(Windows) {
			if ((enabledEventLoops & EnabledEventLoops.Windows) == EnabledEventLoops.Windows) {
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
						if (callback is null ? false : callback())
							break;
						else {
							//Thread.sleep(5.msecs);
							continue;
						}
					}
					
					// remove all messages from the queue
					while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) > 0) {
						if (shouldTranslate(msg))
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

		if ((enabledEventLoops & EnabledEventLoops.X11) == EnabledEventLoops.X11) {
			import std.experimental.bindings.x11 : XPending, XNextEvent;
			XEvent event;

			foreach(display; x11Displays) {
				do {
					XNextEvent(display, &event);
					handleEvent(&event);
				} while(callback is null ? true : callback());
			}
		}

		if ((enabledEventLoops & EnabledEventLoops.Wayland) == EnabledEventLoops.Wayland) {
			assert(0);
		}
	}
	
	bool eventLoopIteration(bool untilEmpty=false) {
		import std.datetime : to;
		import std.algorithm : min;
		
		guardCheck();

		version(Windows) {
			if ((enabledEventLoops & EnabledEventLoops.Windows) == EnabledEventLoops.Windows) {
				MSG msg;
				
				if (untilEmpty) {
					while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) > 0) {
						if (shouldTranslate(msg))
							TranslateMessage(&msg);
						DispatchMessageW(&msg);
					}
				} else {
					PeekMessageW(&msg, null, 0, 0, PM_REMOVE);
					
					if (shouldTranslate(msg))
						TranslateMessage(&msg);
					
					DispatchMessageW(&msg);
				}
			}
		} else version(OSX) {
			if ((enabledEventLoops & EnabledEventLoops.Cocoa) == EnabledEventLoops.Cocoa) {
				assert(0);
			}
		}
		
		if ((enabledEventLoops & EnabledEventLoops.X11) == EnabledEventLoops.X11) {
			import std.experimental.bindings.x11 : XPending, XNextEvent;

			XEvent event;

			if (untilEmpty) {
				foreach(display; x11Displays) {
					while(XPending(display) > 0) {
						XNextEvent(display, &event);
						handleEvent(&event);
					}
				}
			} else {
				foreach(display; x11Displays) {
					XNextEvent(display, &event);
					handleEvent(&event);
				}
			}
		}
		if ((enabledEventLoops & EnabledEventLoops.Wayland) == EnabledEventLoops.Wayland) {
			assert(0);
		}
		
		return true;
	}

	private {
		void handleEvent(XEvent* event) {
			auto x11window = event.xany.window;

			WindowImpl windowInstance = x11Windows[x11window];
			if (X11WindowImpl instance = cast(X11WindowImpl)windowInstance) {
				instance.processEvent(event);
			}
		}
	}
}

version(Windows) {
	enum {
		NOTIFYICON_VERSION_4 = 4,
		NIF_SHOWTIP = 0x00000080,
		NIF_REALTIME = 0x00000040,
	}

	bool shouldTranslate(MSG msg) {
		import core.sys.windows.windows : LOWORD, HIWORD,
			WM_SYSKEYDOWN, WM_SYSKEYUP, WM_KEYDOWN, WM_KEYUP, WM_CHAR,
			VK_NUMPAD0, VK_NUMPAD9, VK_ADD, VK_SUBTRACT, VK_MULTIPLY,
			VK_DIVIDE, VK_DECIMAL, VK_OEM_2, VK_OEM_PERIOD, VK_OEM_COMMA;

		auto id = LOWORD(msg.message);
		
		switch(id) {
			case WM_SYSKEYDOWN: case WM_SYSKEYUP:
			case WM_KEYDOWN: case WM_KEYUP:
			case WM_CHAR:
				break;
			default:
				return false;
		}
		
		switch(msg.wParam) {
			case VK_NUMPAD0: .. case VK_NUMPAD9:
				bool haveAlt = (msg.lParam & (1 << 29)) == 1 << 29;
				return haveAlt;
				
			case VK_ADD: case VK_SUBTRACT:
			case VK_MULTIPLY: case VK_DIVIDE:
			case VK_DECIMAL:
			case VK_OEM_2:
			case VK_OEM_PERIOD:
			case VK_OEM_COMMA:
				return false;
			default:
				return true;
		}
	}
}