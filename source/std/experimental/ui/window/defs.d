module std.experimental.ui.window.defs;
import std.experimental.graphic.image.interfaces : SwappableImage;
import std.experimental.graphic.color.rgb : RGB8, RGBA8;
import std.experimental.platform : IPlatform;

/+
 + FIXME: remove
 +/

struct Point {
	uint x, y;
}

/+
 + FIXME: remove
 +/

interface IWindow {
	@property {
		Point size();
		Point location();
		void size(Point);
		void location(Point);
		IDisplay display();
		IContext context();
	}

	void hide();
	void show();
	void close();
}

// something feels off with IDisplay's location, can it be moved?
interface IDisplay {
	@property {
		string name();
		Point size();
		uint refreshRate();
		uint dotsPerInch();
		immutable(IWindow[]) windows();
	}
}

interface IContext {
	void swapBuffers();
}

interface IWindowCreator {
	@property {
		void size(Point);
		void location(Point);
		void display(IDisplay);
	}

	IWindow init();
}