/**
 * Window cursor support.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.ui.window.features.cursor;
import std.experimental.ui.window.defs;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGBA8;
import std.experimental.memory.managed;

/**
 * What the cursor will be displayed to the user
 */
enum WindowCursorStyle {
    /**
     * The standard arrow cursor
     */
    Standard,
    
    /**
     * The cursor for use when e.g. "clicking" on a link
     */
    Hand,
    
    /**
     * When attempting to resize something vertically
     */
    ResizeVertical,
    
    /**
     * When attempting to resize something horizontally
     */
    ResizeHorizontal,
    
    /**
     * Resizing from the left corner of a rectangle
     */
    ResizeCornerLeft,
    
    /**
     * Resizing from the right corner of a rectangle
     */
    ResizeCornerRight,

    /**
     * It is not possible to act e.g. circle around an X
     */
    NoAction,

    /**
     * Process is currently busy relating to e.g. a control, usually displayed as an hour glass
     */
    Busy,
    
    /**
     * A custom cursor
     */
    Custom,
    
    /**
     * Removes the cursor for display
     */
    None,

    /**
     * Unknown, may not be owned by current process.
     * If the cursor style is set as this, then expect errors to try and modify the cursor.
     */
    Underterminate
}

interface Have_Cursor {
    Feature_Cursor __getFeatureCursor();
}

interface Feature_Cursor {
    void setCursor(WindowCursorStyle);
    WindowCursorStyle getCursor();
    void setCustomCursor(ImageStorage!RGBA8);
    ImageStorage!RGBA8 getCursorIcon();
}

@property {
    /**
     * Assigns a cursor to a window[creator] if capable
     * 
     * Do not pass in Custom as cursor style.
     * 
     * Params:
     * 		self	=	Window or window creator instance
     * 		to		=	Style of cursor to set
     */
    void cursor(T)(T self, WindowCursorStyle to) if (is(T : IWindow) || is(T : IWindowCreator)) {
		if (!self.capableOfCursors)
			return (managed!(ImageStorage!RGBA8)).init;
		else {
			(cast(Have_Cursor)self).__getFeatureCursor().setCursor(to);
		}
    }
    
    void cursor(T)(T self, WindowCursorStyle to) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }

    /// Retrives the cursor style or Invalid if not capable
    WindowCursorStyle cursor(T)(T self) if (is(T : IWindow) || is(T : IWindowCreator)) {
		if (!self.capableOfCursors)
			return WindowCursorStyle.Invalid;
		else {
			return (cast(Have_Cursor)self).__getFeatureCursor().getCursor();
		}
    }
    
    WindowCursorStyle cursor(T)(T self) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }

    /**
     * Sets the cursor icon to the specified image if capable
     * 
     * Automatically set the cursor style to Custom.
     * 
     * Params:
     * 		self	=	The window or window creator to assign to
     * 		to		=	Image to use as cursor icon
     */
    void cursorIcon(T)(T self, ImageStorage!RGBA8 to) if (is(T : IWindow) || is(T : IWindowCreator)) {
		if (self.capableOfCursors) {
			(cast(Have_Cursor)self).__getFeatureCursor().setCustomCursor(to);
		}
    }

    void cursorIcon(T)(T self, ImageStorage!RGBA8 to)  if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }
    
    /**
     * Gets a copy of the cursor if it is assigned as custom or null if not possible or not currently set as custom
     */
    managed!(ImageStorage!RGBA8) cursorIcon(T)(T self) if (is(T : IWindow) || is(T : IWindowCreator)) {
		if (!self.capableOfCursors)
			return (managed!(ImageStorage!RGBA8)).init;
		else {
			auto ret = (cast(Have_Cursor)self).__getFeatureCursor().getCursorIcon();

			if (ret is null)
				return (managed!(ImageStorage!RGBA8)).init;
			else
				return managed!(ImageStorage!RGBA8)(ret, managers(), Ownership.Secondary, self.allocator);
		}
    }
    
    managed!(ImageStorage!RGBA8) cursorIcon(T)(T self) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }

	/**
	 * Does the given window[creator] support cursors?
	 * 
	 * Params:
	 * 		self	=	The window[creator] instance
	 * 
	 * Returns:
	 * 		If the window[creator] supports having a cursors
	 */
	bool capableOfCursors(T)(T self) if (is(T : IWindow) || is(T : IWindowCreator)) {
		if (self is null)
			return false;
		else if (Have_Cursor ss = cast(Have_Cursor)self)
			return ss.__getFeatureCursor() !is null;
		else
			return false;
	}

	bool capableOfCursors(T)(T self) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
		static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow, IWindowCreator types.");
	}
}
