/**
 * Rendering generic interfaces.
 * Includes context and display support.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.ui.rendering;
import std.experimental.ui.events;
import std.experimental.memory.managed;
import std.experimental.allocator : IAllocator;
import std.experimental.math.linearalgebra.vector : vec2;

/**
 * A platform independent representation of a place to render to.
 *
 * Unlike with a window, it does have a size per say.
 * This allows it to work happily on consoles or the web where there are no
 *  window representation at the low level.
 */
interface IRenderPoint {
    @property {
		/**
		 * The size of the render area.
		 * 
		 * For a window this is the user area.
		 * 
		 * Returns:
		 * 		The size of the render area.
		 */
		vec2!ushort size();

        /**
         * Get the display that the render is on.
         *
         * Returns:
         *      The display that the render point is on.
         */
        managed!IDisplay display();
        
        /**
         * The context applied to be rendered to.
         *
         * This is commonly either a VRAM context or OpenGL.
         *
         * The memory associated with it should not be free'd.
         * It will automatically be free'd when the render point is.
         *
         * Returns:
         *      A context that can be rendered to.
         */
        IContext context();
        
        /**
         * The allocator that allocated this render point.
         *
         * You most likely won't need to use this.
         * It is mostly for internal usage.
         *
         * Returns:
         *      The allocator that allocated this.
         */
        IAllocator allocator();
        
        /**
         * Wraps the events that are hookable.
         *
         * Returns:
         *      A class that has event callbacks or null if not available for hooking.
         */
        IRenderEvents events();
        
        /**
         * Is the current state able to be rendered to.
         *
         * This is dependent upon if it has been closed or e.g. the window was visible.
         *
         * Returns:
         *      If the render point can be rendered to right now.
         */
        bool renderable();


		/// No touchy, very dangerous!
		void* __handle();
    }
    
    /**
     * Closes the render point.
     * From this point on, this render point is useless.
     */
    void close();
}

/**
 * Allows incrementally creating a render point.
 */
interface IRenderPointCreator {
    @property {
        /**
         * The display to show the render point on.
         *
         * If it is not specified then $D(platform().primaryDisplay) will be
         *  used instead.
         *
         * Params: 
         *      disp    =   The display to show on
         */
        void display(IDisplay disp);
        
        /**
         * The allocator to allocate the resulting IRenderPoint and IContext
         *  with.
         *
         * If it is not specified then $(D theAllocator) will be used instead.
         *
         * Params:
         *      alloc   =   The allocator to allocate using.
         */
        void allocator(IAllocator alloc);
    }
    
    /**
     * Creates the resulting render point using the pre given arguments.
     *
     * May throw an exception depending upon the implementation.
     *
     * Returns:
     *      The render point or null if failed.
     */
    IRenderPoint create();
}

/**
 * A basic representation of a context to be rendered to.
 */
interface IContext {
    /**
     * Swaps the buffers and makes the being drawn buffer to current.
     * Inherently meant for double buffering.
     */
    void swapBuffers();
}

/**
 * Represents a display.
 */
interface IDisplay {
    import std.experimental.ui.window.defs : IWindow;

    @property {
        /**
         * The name of the display.
         * This could be a computed name that is not meant for human consumption.
         *
         * Returns:
         *      The name of the display.
         */
        managed!string name();
        
        /**
         * The dimensions of the display.
         *
         * Returns:
         *      The dimensions (width/height) of the display.
         */
        vec2!ushort size();
        
        /**
         * The rate the monitor/display can refresh its contents.
         * 
         * Commonly this is 50 or 60.
         *
         * Returns:
         *      The rate the monitor and display can refresh its contents.
         */
        uint refreshRate();
        
        /**
         * How bright the display is.
         *
         * Potentially a very expensive operation.
         * Perform only when you absolutely need to.
         *
         * The default value is 10 and should be considered normal.
         *
         * Returns:
         *      The brightness of the screen in lumens.
         */
        uint luminosity();
        
		/**
		 * Is this display the primary monitor?
		 * 
		 * If it is not gainable and there is only one display
		 *  it will return true; otherwise false.
		 * 
		 * Returns:
		 * 		If this display is the primary one.
		 */
		bool isPrimary();

        /**
         * How bright the display is.
         * For usage with gamma display algorithms.
         * 
         * Potentially a very expensive operation.
         * Perform only when you absolutely need to.
         *
         * The default value is 1 and should be considered normal.
         * It will usually be between 0 and 2.
         *
         * Returns:
         *      The brightness of the display.
         */
        final float gamma() {
            return luminosity() / 10f;
        }
        
        /**
         * All the windows on this display.
         *
         * Not all IDisplay's will support this.
         * It is semi-optional.
         *
         * Returns:
         *      All the windows on this display or null if none.
         */
        managed!(IWindow[]) windows();

        /// No touchy, very dangerous!
        void* __handle();
    }

	IDisplay dup(IAllocator alloc);
}
