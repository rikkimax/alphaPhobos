module std.experimental.ui.window.defs;
import std.experimental.graphic.image.interfaces : SwappableImage;
import std.experimental.graphic.color.rgb : RGB8, RGBA8;
import std.experimental.platform : IPlatform, IDisplay;
import std.experimental.math.linearalgebra.vector : vec2;
import std.experimental.allocator : IAllocator;
import std.experimental.internal.dummyRefCount;

alias UIPoint = vec2!short;

interface IWindow {
    @property {
        string title();
        void title(string);

        UIPoint size();
        void location(UIPoint);

        UIPoint location();
        void size(UIPoint);

        DummyRefCount!IDisplay display();
        IContext context();
    }

    void hide();
    void show();
    void close();
}

interface IContext {
    void swapBuffers();
}

interface IWindowCreator {
    @property {
        void size(UIPoint);
        void location(UIPoint);
		void display(IDisplay); // default platform().primaryDisplay
        void allocator(IAllocator); // default std.experimental.allocator.theAllocator()
	}

    IWindow init();
}