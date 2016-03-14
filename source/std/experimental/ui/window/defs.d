/**
 * Window representation.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.ui.window.defs;
import std.experimental.graphic.image.interfaces : SwappableImage;
import std.experimental.graphic.color.rgb : RGB8, RGBA8;
import std.experimental.platform : IPlatform;
import std.experimental.ui.rendering;
import std.experimental.math.linearalgebra.vector : vec2;
import std.experimental.allocator : IAllocator;
import std.experimental.memory.managed;

/**
 * Declares a point within display space for usage with windows
 */
alias UIPoint = vec2!short;

///
interface IWindow : IRenderPoint {
    @property {
        /// The title of the window
        managed!(dstring) title();
        
        /// Sets the title of the window (if possible)
        void title(string);

        /// Ditto
        void title(wstring);
        
        /// Ditto
        void title(dstring);
        
        /// Size of the window (user area)
        UIPoint size();
        
        /// Moves the window on its display
        void location(UIPoint);

        /// Gets the window location relative to its display
        UIPoint location();
        
        /// Sets the size of the window (user area)
        void size(UIPoint);

        /// Is the window currently being displayed?
        bool visible();
    }

    ///
    void hide();
    
    ///
    void show();
}

///
interface IWindowCreator : IRenderPointCreator {
    @property {
        /// Sets a size for a window to be created in (user area)
        void size(UIPoint);
        
        /// The location for a window to try and spawn in
        void location(UIPoint);
    }
    
	/// Creates the window
    IWindow createWindow();
}

/**
 * A style a window can have
 * Enables usage for fullscreen and non resizable
 */
enum WindowStyle {
    ///
    Unknown,
    
    /**
     * The default style of any window.
     * Close/Minimize/Maximize, resizable, moveable
     */
    Dialog,

    /**
     * Useful for tool boxes and such
     * Close/Minimize, non-resizable, moveable
     */
    Borderless,

    /**
     * Useful for e.g. message/input boxes
     * Close/Minimize, non-resizable, moveable, top most window
     */
    Popup,

    /**
     * Useful for e.g. 3d games
     * No top bar, non-resiable, non-moveable
     */
    Fullscreen
}

interface Have_Style {
    Feature_Style __getFeatureStyle();
}

interface Feature_Style {
    void setStyle(WindowStyle);
    WindowStyle getStyle();
}

@property {
	/**
     * Gets the style of the window
     *
     * Params:
	 * 		self	=	The window[creator] instance
     *
     * Returns:
     *      The window style or unknown
     */
    WindowStyle style(T)(T self) if (is(T : IWindow) || is(T : IWindowCreator)) {
        if (self is null)
            return WindowStyle.Unknown;
        if (Have_Style ss = cast(Have_Style)self) {
            auto fss = ss.__getFeatureStyle();
            if (fss !is null) {
                return fss.getStyle();
            }
        }
        
        return WindowStyle.Unknown;
    }
    
	/**
     * Sets the window[creator] style
     * 
     * Params:
	 * 		self	=	The window[creator] instance
	 * 		to		=	The style to set to
     */
    void style(T)(T self, WindowStyle to) if (is(T : IWindow) || is(T : IWindowCreator)) {
        if (self is null)
            return;
        if (Have_Style ss = cast(Have_Style)self) {
            auto fss = ss.__getFeatureStyle();
            if (fss !is null) {
                fss.setStyle(to);
            }
        }
    }

	/**
	 * Does the given window[creator] support styles?
	 * 
	 * Params:
	 * 		self	=	The window[creator] instance
	 * 
	 * Returns:
	 * 		If the window[creator] supports having a style
	 */
	bool capableOfWindowStyles(T)(T self) if (is(T : IWindow) || is(T : IWindowCreator)) {
		if (self is null)
			return false;
		else if (Have_Style ss = cast(Have_Style)self)
			return ss.__getFeatureStyle() !is null;
		else
			return false;
	}
}
