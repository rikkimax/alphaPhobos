module std.experimental.ui.window.features.screenshot;
import std.experimental.ui.window.defs;

interface Have_ScreenShot {
	Feature_ScreenShot __getFeatureScreenShot();
}

interface Feature_ScreenShot {
	SwappableImage!RGB8* screenshot();
}

@property {
	SwappableImage!RGB8* screenshot(T)(T self) if (is(T : IWindow) || is(T : IDisplay) || is(T : IPlatform)) {
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

	SwappableImage!RGB8* screenshot(T)(T self) {
		static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow, IDisplay or IPlatform types.");
	}
}