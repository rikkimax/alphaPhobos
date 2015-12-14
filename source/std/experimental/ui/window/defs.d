module std.experimental.ui.window.defs;
import std.experimental.graphic.image.interfaces : SwappableImage;
import std.experimental.graphic.color.rgb : RGB8, RGBA8;
import std.experimental.platform : IPlatform, IDisplay, IRenderPoint, IRenderPointCreator;
import std.experimental.math.linearalgebra.vector : vec2;
import std.experimental.allocator : IAllocator;
import std.experimental.internal.dummyRefCount;

///
alias UIPoint = vec2!short;

///
interface IWindow : IRenderPoint {
    @property {
        DummyRefCount!(char[]) title();
        void title(string);

        UIPoint size();
        void location(UIPoint);

        UIPoint location();
        void size(UIPoint);

        bool visible();

        void* __handle();
    }

    void hide();
    void show();
}

///
interface IWindowCreator : IRenderPointCreator {
    @property {
        void size(UIPoint);
        void location(UIPoint);
    }
}

/**
 * A style a window can have
 * Enables usage for fullscreen and non resizable
 */
enum WindowStyle {
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
     * Close/Minimize, non-resizable, moveable
     */
    Popup,

    /**
     * Useful for e.g. 3d games
     * No top bar, non-resiable, non-moveable
     */
    Fullscreen
}

///
interface Have_Style {
    Feature_Style __getFeatureStyle();
}

///
interface Feature_Style {
    ///
    void setStyle(WindowStyle);
    
    ///
    WindowStyle getStyle();
}

@property {
    ///
    WindowStyle style(IWindow self) {
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
    
    ///
    void style(IWindow self, WindowStyle to) {
        if (self is null)
            return;
        if (Have_Style ss = cast(Have_Style)self) {
            auto fss = ss.__getFeatureStyle();
            if (fss !is null) {
                fss.setStyle(to);
            }
        }
    }
}
