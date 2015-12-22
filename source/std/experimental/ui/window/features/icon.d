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
import std.experimental.internal.dummyRefCount;

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
    ///
    void icon(T)(T self, ImageStorage!RGBA8 to) if (is(T : IWindow) || is(T : IWindowCreator)) {
        if (self is null)
            return;
        if (Have_Icon ss = cast(Have_Icon)self) {
            auto fss = ss.__getFeatureIcon();
            if (fss !is null) {
                fss.setIcon(to);
            }
        }
    }

    void icon(T)(T self, ImageStorage!RGBA8 to) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }

    ///
    DummyRefCount!(ImageStorage!RGBA8) icon(T)(T self) if (is(T : IWindow) || is(T : IWindowCreator)) {
        if (self is null)
            return DummyRefCount!(ImageStorage!RGBA8)(null, null);

        if (Have_Icon ss = cast(Have_Icon)self) {
            auto fss = ss.__getFeatureIcon();
            if (fss !is null) {
                auto ret = fss.getIcon();
                return DummyRefCount!(ImageStorage!RGBA8)(ret, self.allocator);
            }
        }

        return DummyRefCount!(ImageStorage!RGBA8)(null, null);
    }

    DummyRefCount!(ImageStorage!RGBA8) icon(T)(T self) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }
}
