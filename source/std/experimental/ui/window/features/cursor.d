module std.experimental.ui.window.features.cursor;
import std.experimental.ui.window.defs;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGBA8;
import std.experimental.internal.dummyRefCount;

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
     * Unknown, may not be owned by current process.
     * If the cursor style is set as this, then expect errors to try and modify the cursor.
     */
    Underterminate
}

interface Have_Cursor {
    Feature_Cursor __getFeatureCursor();
}

interface Feature_Cursor {
    /**
     * Do not pass in Custom as cursor style. It is automatically determined when using setCursorIcon.
     */
    void setCursor(WindowCursorStyle);
    WindowCursorStyle getCursor();

    /**
     * Automatically set sthe cursor style to Custom.
     * And updates the cursor to the given one.
     */
    void setCustomCursor(ImageStorage!RGBA8);

    /**
     * Gets a copy of the cursor if it is assigned as custom
     */
    ImageStorage!RGBA8 getCursorIcon();
}

@property {
    void cursor(T)(T self, WindowCursorStyle to) if (is(T : IWindow) || is(T : IWindowCreator)) {
        if (self is null)
            return;
        if (Have_Cursor ss = cast(Have_Cursor)self) {
            auto fss = ss.__getFeatureCursor();
            if (fss !is null) {
                fss.setCursor(to);
            }
        }
    }
    
    void cursor(T)(T self, WindowCursorStyle to) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }

    WindowCursorStyle cursor(T)(T self) if (is(T : IWindow) || is(T : IWindowCreator)) {
        if (self is null)
            return WindowCursorStyle.Invalid;
        
        if (Have_Cursor ss = cast(Have_Cursor)self) {
            auto fss = ss.__getFeatureCursor();
            if (fss !is null) {
                auto ret = fss.getCursor();
                return ret;
            }
        }
        
        return WindowCursorStyle.Invalid;
    }
    
    WindowCursorStyle cursor(T)(T self) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }

    void cursorIcon(T)(T self, ImageStorage!RGBA8 to) if (is(T : IWindow) || is(T : IWindowCreator)) {
        if (self is null)
            return;
        if (Have_Cursor ss = cast(Have_Cursor)self) {
            auto fss = ss.__getFeatureCursor();
            if (fss !is null) {
                fss.setCustomCursor(to);
            }
        }
    }
    
    void cursorIcon(T)(T self, ImageStorage!RGBA8 to)  if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }
    
    DummyRefCount!(ImageStorage!RGBA8) cursorIcon(T)(T self) if (is(T : IWindow) || is(T : IWindowCreator)) {
        if (self is null)
            return DummyRefCount!(ImageStorage!RGBA8)(null, null);
        
        if (Have_Cursor ss = cast(Have_Cursor)self) {
            auto fss = ss.__getFeatureCursor();
            if (fss !is null) {
                auto ret = fss.getCursorIcon();
                return DummyRefCount!(ImageStorage!RGBA8)(ret, self.allocator);
            }
        }
        
        return DummyRefCount!(ImageStorage!RGBA8)(null, null);
    }
    
    DummyRefCount!(ImageStorage!RGBA8) cursorIcon(T)(T self) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }
}