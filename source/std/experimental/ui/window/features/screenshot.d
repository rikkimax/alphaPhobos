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
import std.experimental.platform : IDisplay;
import std.experimental.graphic.color : RGB8;

interface Have_ScreenShot {
    Feature_ScreenShot __getFeatureScreenShot();
}

interface Feature_ScreenShot {
    ImageStorage!RGB8 screenshot(IAllocator alloc=null);
}

@property {
    ///
    ImageStorage!RGB8 screenshot(T)(T self, IAllocator alloc=null) if (is(T : IWindow) || is(T : IDisplay) || is(T : IPlatform)) {
        if (self is null)
            return null;
        if (Have_ScreenShot ss = cast(Have_ScreenShot)self) {
            auto fss = ss.__getFeatureScreenShot();
            if (fss !is null) {
                return fss.screenshot();
            }
        }

        return null;
    }

    ImageStorage!RGB8 screenshot(T)(T self, IAllocator alloc=null) if (!(is(T : IWindow) || is(T : IDisplay) || is(T : IPlatform))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow, IDisplay or IPlatform types.");
    }
}
