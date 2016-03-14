/**
 * Styles for a window.
 * 
 * These are very commonly supported feature set.
 * They should not be considered optional for most targets.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.ui.window.styles;
import std.experimental.ui.window.defs;

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