module std.experimental.ui.internal.native_menu;
import std.experimental.memory.managed;
import std.experimental.platform : IPlatform;
import std.experimental.allocator : IAllocator;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGB8, RGBA8;

private {
	import std.experimental.ui.window.features.menu;
	import std.experimental.ui.internal.window : WindowImpl;
	import std.experimental.ui.internal.defs;

	version(Windows) {
		import core.sys.windows.windows : HMENU, HBITMAP, AppendMenuA, CreatePopupMenu,
			ModifyMenuA, RemoveMenu, DeleteMenu, DeleteObject, MENUITEMINFOA, GetMenuItemInfoA,
			HDC, GetDC, CreateCompatibleDC, DeleteDC, ReleaseDC, BITMAP, GetObjectA, ModifyMenuW,
			MF_BYCOMMAND, MF_POPUP, UINT_PTR, GetMenuStringW, MF_STRING, GetMenuState, MF_BITMAP,
			MF_SEPARATOR, MF_DISABLED, MF_ENABLED;
	}
}

final class MenuItemImpl : MenuItem {
	package(std.experimental.ui.internal) {
		import std.experimental.containers.list;
		
		WindowImpl window;
		List!MenuItemImpl menuItems = void;
		
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
			
			menuItems = List!MenuItemImpl(window.alloc);
			
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
			
			ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_POPUP, cast(UINT_PTR) myChildren, null);
			return window.alloc.make!MenuItemImpl(window, myChildren, this);
		} else
			assert(0);
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
		override managed!(MenuItem[]) childItems() {
			return cast(managed!(MenuItem[]))menuItems[];
		}
		
		override managed!(ImageStorage!RGB8) image() {
			version(Windows) {
				MENUITEMINFOA mmi;
				mmi.cbSize = MENUITEMINFOA.sizeof;
				GetMenuItemInfoA(parent, menuItemId, false, &mmi);
				
				HDC hFrom = GetDC(null);
				HDC hMemoryDC = CreateCompatibleDC(hFrom);
				
				scope(exit) {
					DeleteDC(hMemoryDC);
					ReleaseDC(window.hwnd, hFrom);
				}
				
				BITMAP bm;
				GetObjectA(mmi.hbmpItem, BITMAP.sizeof, &bm);
				
				return managed!(ImageStorage!RGB8)(bitmapToImage(mmi.hbmpItem, hMemoryDC, vec2!size_t(bm.bmWidth, bm.bmHeight), window.alloc), managers(), Ownership.Secondary, window.alloc);
			} else
				assert(0);
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
				ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_BITMAP, 0, cast(const(char)*)bitmap);
				
				if (lastBitmap !is null)
					DeleteObject(lastBitmap);
				lastBitmap = bitmap;
			}
			window.redrawMenu = true;
		}
		
		override managed!dstring text() {
			version(Windows) {
				wchar[32] buffer;
				int length = GetMenuStringW(parent, menuItemId, buffer.ptr, buffer.length, MF_BYCOMMAND);
				assert(length >= 0);
				
				dchar[] buffer2 = window.alloc.makeArray!dchar(length);
				buffer2[0 .. length] = cast(dchar[])buffer[0 .. length];
				
				return managed!dstring(cast(dstring)buffer2, managers(), Ownership.Secondary, window.alloc);
			} else
				assert(0);
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
				
				ModifyMenuW(parent, menuItemId, MF_BYCOMMAND | MF_STRING, 0, cast(const(wchar)*)buffer.ptr);
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
		
		override bool divider() {
			version(Windows) {
				return (GetMenuState(parent, menuItemId, MF_BYCOMMAND) & MF_SEPARATOR) == MF_SEPARATOR;
			} else
				assert(0);
		}
		
		override void divider(bool v) {
			version(Windows) {
				if (v)
					ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_SEPARATOR, 0, null);
				else
					ModifyMenuA(parent, menuItemId, MF_BYCOMMAND & ~MF_SEPARATOR, 0, null);
			}
			window.redrawMenu = true;
		}
		
		override bool disabled() {
			version(Windows) {
				return (GetMenuState(parent, menuItemId, MF_BYCOMMAND) & MF_DISABLED) == MF_DISABLED;
			} else
				assert(0);
		}
		
		override void disabled(bool v) {
			version(Windows) {
				if (v)
					ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_DISABLED, 0, null);
				else
					ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_ENABLED, 0, null);
			}
			window.redrawMenu = true;
		}
		
		override void callback(MenuCallback callback) {
			window.menuCallbacks[menuItemId] = callback;
		}
	}
}