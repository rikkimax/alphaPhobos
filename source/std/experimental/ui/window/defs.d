module std.experimental.ui.window.defs;
import std.datetime : Duration, seconds;
import std.experimental.graphic.image.interfaces : SwappableImage;
import std.experimental.graphic.color.rgb : RGB8, RGBA8;

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

shared interface IPlatform {
	IWindowCreator createWindow();
	IWindow createAWindow(); // completely up to platform implementation to what the defaults are
	
	@property {
		immutable(IDisplay) primaryDisplay();
		immutable(IDisplay[]) displays();
		immutable(IWindow[]) windows();
	}
	
	void optimizedEventLoop(Duration timeout = 0.seconds, bool delegate() callback=null);
	bool eventLoopIteration(Duration timeout = 0.seconds, bool untilEmpty=false);
	
	final void setAsDefault() {
		thePlatform_ = this;
	}
}

interface IWindowCreator {
	@property {
		void size(Point);
		void location(Point);
		void display(IDisplay);
	}

	IWindow init();
}

private {
	import std.experimental.ui.window.internal : ImplPlatform;
	shared(IPlatform) defaultPlatform_;
	shared(IPlatform) thePlatform_;

	shared static this() {
		defaultPlatform_ = new shared ImplPlatform();
		thePlatform_ = defaultPlatform_;
	}
}

shared(IPlatform) thePlatform() {
	return thePlatform_;
}

shared(IPlatform) defaultPlatform() {
	return defaultPlatform_;
}