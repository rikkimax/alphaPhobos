/**
 * Window and display screenshot capabilities.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.ui.window.features.screenshot;
import std.experimental.ui.window.defs;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.allocator : IAllocator;
import std.experimental.platform : IDisplay, IPlatform;
import std.experimental.graphic.color : RGB8;
import std.experimental.memory.managed;

interface Have_ScreenShot {
    Feature_ScreenShot __getFeatureScreenShot();
}

interface Feature_ScreenShot {
    ImageStorage!RGB8 screenshot(IAllocator alloc=null);
}

@property {
    /// Takes a screenshot or null if not possible
    managed!(ImageStorage!RGB8) screenshot(T)(T self, IAllocator alloc=null) if (is(T : IWindow) || is(T : IDisplay) || is(T : IPlatform)) {
		if (!self.capableOfScreenShot)
			return (managed!(ImageStorage!RGB8)).init;
		else {
			auto ret = (cast(Have_ScreenShot)self).__getFeatureScreenShot().screenshot;
			return managed!(ImageStorage!RGB8)(ret, managers(), Ownership.Secondary, self.allocator);
		}
    }

    ImageStorage!RGB8 screenshot(T)(T self, IAllocator alloc=null) if (!(is(T : IWindow) || is(T : IDisplay) || is(T : IPlatform))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow, IDisplay or IPlatform types.");
    }

	/**
	 * Can a screenshot be taken of window/display/platform?
	 * 
	 * Params:
	 * 		self	=	The window/display/platform instance
	 * 
	 * Returns:
	 * 		If the window/display/platform supports having a screenshot taken of it
	 */
	bool capableOfScreenShot(T)(T self) if (is(T : IWindow) || is(T : IDisplay) || is(T : IPlatform)) {
		if (self is null)
			return false;
		else if (Have_ScreenShot ss = cast(Have_ScreenShot)self)
			return ss.__getFeatureScreenShot() !is null;
		else
			return false;
	}

	bool capableOfScreenShot(T)(T self) if (!(is(T : IWindow) || is(T : IDisplay) || is(T : IPlatform))) {
		static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow, IDisplay or IPlatform types.");
	}
}
