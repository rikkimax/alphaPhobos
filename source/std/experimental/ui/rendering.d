/**
 * Rendering generic interfaces.
 * Includes context and display support.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.ui.rendering;
import std.experimental.internal.dummyRefCount;
import std.experimental.allocator : IAllocator;

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
         * Get the display that the render is on.
         *
         * Returns:
         *      The display that the render point is on.
         */
        DummyRefCount!IDisplay display();
        
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

///
alias EventOnForcedDrawDel = void delegate();
///
alias EventOnForcedDrawFunc = void function();

///
alias EventOnCursorMoveDel = void delegate(short x, short y);
///
alias EventOnCursorMoveFunc = void function(short x, short y);

///
alias EventOnCursorActionDel = void delegate(ushort action);
///
alias EventOnCursorActionFunc = void function(ushort action);

///
alias EventOnScrollDel = void delegate(short amount);
///
alias EventOnScrollFunc = void function(short amount);

/**
 * Group of hookable events for rendering upon
 */
interface IRenderEvents {
    import std.experimental.math.linearalgebra.vector : vec2;
    import std.functional : toDelegate;

    @property {
        /**
         * When the OS informs the program that the window must be redrawn
         *  this callback will be called.
         *
         * This could be because of movement, resizing of a window or 
         *  the computer has come out of hibernation.
         *
         * Params:
         *      del     =   The callback to call
         */
        void onForcedDraw(EventOnForcedDrawDel del);
        
        ///
        final void onForcedDraw(EventOnForcedDrawFunc func) { onForcedDraw(func.toDelegate); }
        
        /**
         * When the cursor moves within the window the callback is called.
         *
         * Commonly this is will be a mouse.
         * The values passed will be relative to the render point.
         *
         * Params:
         *      del     =   The callback to call
         */
        void onCursorMove(EventOnCursorMoveDel del);
        
        ///
        final void onCursorMove(EventOnCursorMoveFunc func) { onCursorMove(func.toDelegate); }
        
        /**
         * When an action associated with a cursor occurs, the callback is called.
         *
         * When the cursor is backed by a mouse:
         *  - The left mouse button will be mapped to 0
         *  - The right mouse button will be mapped to 1 
         *  - The middle mouse button will be mapped to 2
         *
         * Params:
         *      del     =   The callback to call
         */
        void onCursorAction(EventOnCursorActionDel del);
        
        ///
        final void onCursorAction(EventOnCursorActionFunc func) { onCursorAction(func.toDelegate); }
        
        /**
         * When an action associated with a cursor no longer occurs, the callback is called.
         *
         * When the cursor is backed by a mouse:
         *  - The left mouse button will be mapped to 0
         *  - The right mouse button will be mapped to 1 
         *  - The middle mouse button will be mapped to 2
         *
         * Params:
         *      del     =   The callback to call
         */
        void onCursorActionEnd(EventOnCursorActionDel del);
        
        ///
        final void onCursorActionEnd(EventOnCursorActionFunc func) { onCursorActionEnd(func.toDelegate); }
        
        /**
         * When a scroll event occurs the callback is called.
         *
         * Most of the time this is only implemented for mouses.
         *
         * Params:
         *      del     =   The callback to call
         */
        void onScroll(EventOnScrollDel del);
        
        ///
        final void onScroll(EventOnScrollFunc func) { onScroll(func.toDelegate); }
        
        // TODO: onClose
        // TODO: onKeyDown
        // TODO: onKeyUp
    }
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
    import std.experimental.math.linearalgebra.vector : vec2;
    import std.experimental.ui.window.defs : IWindow;

    @property {
        /**
         * The name of the display.
         * This could be a computed name that is not meant for human consumption.
         *
         * Returns:
         *      The name of the display.
         */
        string name();
        
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
        DummyRefCount!(IWindow[]) windows();
        
        /**
         * Handle to the underlying representation of this display.
         *
         * $(B You should $(I not) use this unless you know what you are doing.)
         *
         * Returns:
         *      A pointer to the underlying representation of this display.
         */
        void* __handle();
    }
}
