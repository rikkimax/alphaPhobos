module std.experimental.ui.internal.native_menu;
import std.experimental.ui.window.features.menu;
import std.experimental.ui.internal.defs;
import std.experimental.memory.managed;
import std.experimental.platform : IPlatform;
import std.experimental.allocator : IAllocator;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGB8, RGBA8;

abstract class MenuItemImpl : MenuItem {
	import std.experimental.containers.list;

	private {
		List!MenuItemImpl menuItems = void;
		
		uint menuItemId;
		MenuItemImpl parentMenuItem;
	}

	abstract {
		MenuItem addChildItem();
		void remove();

		@property {
			managed!(MenuItem[]) childItems();
			managed!(ImageStorage!RGB8) image();
			void image(ImageStorage!RGB8 input);

			managed!dstring text();
			void text(string text);
			void text(wstring text);
			void text(dstring text);

			bool divider();
			void divider(bool v);
			bool disabled();
			void disabled(bool v);
			void callback(MenuCallback callback);
		}
	}
}

version(Windows) {
	final class WinAPIMenuItemImpl : MenuItemImpl {
		import std.experimental.ui.internal.window : WinAPIWindowImpl;
		import std.traits : isSomeString;
		import core.sys.windows.windows : HMENU, HBITMAP, AppendMenuA, CreatePopupMenu,
			ModifyMenuA, RemoveMenu, DeleteMenu, DeleteObject, MENUITEMINFOA, GetMenuItemInfoA,
			HDC, GetDC, CreateCompatibleDC, DeleteDC, ReleaseDC, BITMAP, GetObjectA, ModifyMenuW,
			MF_BYCOMMAND, MF_POPUP, UINT_PTR, GetMenuStringW, MF_STRING, GetMenuState, MF_BITMAP,
			MF_SEPARATOR, MF_DISABLED, MF_ENABLED;

		package(std.experimental.ui.internal) {
			WinAPIWindowImpl window;
			uint menuItemId;

			HMENU parent;
			HMENU myChildren;
			HBITMAP lastBitmap;
		}

		this(WinAPIWindowImpl window, HMENU parent, WinAPIMenuItemImpl parentMenuItem=null) {
			import std.experimental.containers.list;
			this.window = window;
			this.parent = parent;
			this.parentMenuItem = parentMenuItem;
			
			menuItems = List!MenuItemImpl(window.alloc);
			
			menuItemId = window.menuItemsCount;
			window.menuItemsCount++;
			
			AppendMenuA(parent, 0, menuItemId, null);
			window.redrawMenu = true;
		}

		override MenuItem addChildItem() {
			if (myChildren is null) {
				myChildren = CreatePopupMenu();
			}
			
			ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_POPUP, cast(UINT_PTR) myChildren, null);
			return window.alloc.make!WinAPIMenuItemImpl(window, myChildren, this);
		}
		
		override void remove() {
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

		@property {
			override managed!(MenuItem[]) childItems() {
				return cast(managed!(MenuItem[]))menuItems[];
			}
			
			override managed!(ImageStorage!RGB8) image() {
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
			}
			
			override void image(ImageStorage!RGB8 input) {
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

				window.redrawMenu = true;
			}
			
			override managed!dstring text() {
				wchar[32] buffer;
				int length = GetMenuStringW(parent, menuItemId, buffer.ptr, buffer.length, MF_BYCOMMAND);
				assert(length >= 0);
				
				dchar[] buffer2 = window.alloc.makeArray!dchar(length);
				buffer2[0 .. length] = cast(dchar[])buffer[0 .. length];
				
				return managed!dstring(cast(dstring)buffer2, managers(), Ownership.Secondary, window.alloc);
			}
			
			private void setText(T)(T input) if (isSomeString!T) {
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

				window.redrawMenu = true;
			}
			
			override void text(dstring input) { setText(input); }
			override void text(wstring input) { setText(input); }
			override void text(string input) { setText(input); }
			
			override bool divider() {
				return (GetMenuState(parent, menuItemId, MF_BYCOMMAND) & MF_SEPARATOR) == MF_SEPARATOR;
			}
			
			override void divider(bool v) {
				if (v)
					ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_SEPARATOR, 0, null);
				else
					ModifyMenuA(parent, menuItemId, MF_BYCOMMAND & ~MF_SEPARATOR, 0, null);

				window.redrawMenu = true;
			}
			
			override bool disabled() {
				return (GetMenuState(parent, menuItemId, MF_BYCOMMAND) & MF_DISABLED) == MF_DISABLED;
			}
			
			override void disabled(bool v) {
				if (v)
					ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_DISABLED, 0, null);
				else
					ModifyMenuA(parent, menuItemId, MF_BYCOMMAND | MF_ENABLED, 0, null);

				window.redrawMenu = true;
			}
			
			override void callback(MenuCallback callback) {
				window.menuCallbacks[menuItemId] = callback;
			}
		}
	}
}