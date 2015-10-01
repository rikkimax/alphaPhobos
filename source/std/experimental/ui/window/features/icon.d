module std.experimental.ui.window.features.icon;
import std.experimental.ui.window.defs;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGBA8;

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
    void icon(T)(T self, ImageStorage!RGBA8 to) if (is(T : IWindow) || is(T : IWindowCreator)) {
        if (self is null)
            return;
        if (Feature_Icon ss = cast(Feature_Icon)self) {
            auto fss = ss.__getFeatureIcon();
            if (fss !is null) {
                fss.setIcon(to);
            }
        }
    }

    void icon(T)(T self, ImageStorage!RGBA8 to) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }

    ImageStorage!RGBA8 icon(T)(T self) if (is(T : IWindow) || is(T : IWindowCreator)) {
        if (self is null)
            return null;
        if (Feature_Icon ss = cast(Feature_Icon)self) {
            auto fss = ss.__getFeatureIcon();
            if (fss !is null) {
                return fss.getIcon();
            }
        }
    }

    ImageStorage!RGBA8 icon(T)(T self) if (!(is(T : IWindow) || is(T : IWindowCreator))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IWindowCreator.");
    }
}