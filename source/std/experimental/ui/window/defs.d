module std.experimental.ui.window.defs;
import std.experimental.graphic.image.interfaces : SwappableImage;
import std.experimental.graphic.color.rgb : RGB8, RGBA8;
import std.experimental.platform : IPlatform, IDisplay, IRenderPoint, IRenderPointCreator;
import std.experimental.math.linearalgebra.vector : vec2;
import std.experimental.allocator : IAllocator;
import std.experimental.internal.dummyRefCount;

alias UIPoint = vec2!short;

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

interface IWindowCreator : IRenderPointCreator {
    @property {
        void size(UIPoint);
        void location(UIPoint);
	}
}
