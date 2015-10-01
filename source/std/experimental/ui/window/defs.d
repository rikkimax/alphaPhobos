module std.experimental.ui.window.defs;
import std.experimental.graphic.image.interfaces : SwappableImage;
import std.experimental.graphic.color.rgb : RGB8, RGBA8;
import std.experimental.platform : IPlatform, IDisplay;
import std.experimental.math.linearalgebra.vector : vec2;
import std.experimental.allocator : IAllocator;

alias UIPoint = vec2!int;

interface IWindow {
    @property {
        string title();
        void title(string);

        UIPoint size();
        void location(UIPoint);

        UIPoint location();
        void size(UIPoint);

        IDisplay display();
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
<<<<<<< HEAD
		void display(IDisplay); // default platform().primaryDisplay
        void allocator(IAllocator); // default std.experimental.allocator.theAllocator()
	}
=======
        void display(IDisplay);
    }
>>>>>>> 48b36328698cc6dd8e995b639cf8ae8d315e497e

    IWindow init();
}