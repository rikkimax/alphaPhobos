/**
 * Window representation.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.ui.window.defs;
import std.experimental.graphic.image.interfaces : SwappableImage;
import std.experimental.graphic.color.rgb : RGB8, RGBA8;
import std.experimental.platform : IPlatform;
import std.experimental.ui.rendering;
import std.experimental.ui.window.events : IWindowEvents;
import std.experimental.math.linearalgebra.vector : vec2;
import std.experimental.allocator : IAllocator;
import std.experimental.memory.managed;

///
interface IWindow : IRenderPoint {
    @property {
        /// The title of the window
        managed!(dstring) title();
        
        /// Sets the title of the window (if possible)
        void title(string);

        /// Ditto
        void title(wstring);
        
        /// Ditto
        void title(dstring);
        
        /// Moves the window on its display
        void location(vec2!short);

        /// Gets the window location relative to its display
		vec2!short location();
        
        /// Sets the size of the window (user area)
        void size(vec2!ushort);

        /// Is the window currently being displayed?
        bool visible();

		/// Windowing specific events (extends events provided for render point)
		IWindowEvents windowEvents();
    }

    ///
    void hide();
    
    ///
    void show();
}

///
interface IWindowCreator : IRenderPointCreator {
    @property {
        /// Sets a size for a window to be created in (user area)
		void size(vec2!ushort);
        
        /// The location for a window to try and spawn in
		void location(vec2!short);
    }
    
	/// Creates the window
    IWindow createWindow();
}
