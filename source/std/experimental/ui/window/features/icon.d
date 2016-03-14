/**
 * Window icon support.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.ui.window.features.icon;
import std.experimental.ui.window.defs;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGBA8;
import std.experimental.memory.managed;

interface Have_Icon {
    Feature_Icon __getFeatureIcon();
}

interface Feature_Icon {
    @property {
        ImageStorage!RGBA8 getIcon();
        void setIcon(ImageStorage!RGBA8);
    }
}

@property {
    /// Sets the icon on a window[creator] if capable
    void icon(T)(T self, ImageStorage!RGBA8 to) if (is(T : IWindow) || is(T : IWindowCreator)) {
		if (self.capableOfWindowIcon) {
			(cast(Have_Icon)self).__getFeatureIcon().setIcon(to);
		}
    }

    void icon(T)(T self, ImageStorage!RGBA8 to) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }

    /// Retrives the window icon if capable or null if not
    managed!(ImageStorage!RGBA8) icon(T)(T self) if (is(T : IWindow) || is(T : IWindowCreator)) {
		if (!self.capableOfWindowIcon)
			return (managed!(ImageStorage!RGBA8)).init;
		else {
			auto ret = (cast(Have_Icon)self).__getFeatureIcon().getIcon();
			return managed!(ImageStorage!RGBA8)(ret, managers(), Ownership.Secondary, self.allocator);
		}
    }

    managed!(ImageStorage!RGBA8) icon(T)(T self) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }

	/**
	 * Does the given window[creator] support icons?
	 * 
	 * Params:
	 * 		self	=	The window[creator] instance
	 * 
	 * Returns:
	 * 		If the window[creator] supports having an icon
	 */
	bool capableOfWindowIcon(T)(T self) if (is(T : IWindow) || is(T : IWindowCreator)) {
		if (self is null)
			return false;
		else if (Have_Icon ss = cast(Have_Icon)self)
			return ss.__getFeatureIcon() !is null;
		else
			return false;
	}

	bool capableOfWindowIcon(T)(T self) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
		static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow, IWindowCreator types.");
	}
}
