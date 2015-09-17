module std.experimental.ui.window.defs;
import std.experimental.graphic.image.interfaces : SwappableImage;
import std.experimental.graphic.color.rgb : RGB8, RGBA8;
import std.experimental.platform : IPlatform, IDisplay;
import std.experimental.math.linearalgebra.vector : vec2;

alias UIPoint = vec2!int;

interface IWindow {
	@property {
        UIPoint size();
        UIPoint location();
        void size(UIPoint);
        void location(UIPoint);
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
		void display(IDisplay);
	}

	IWindow init();
}