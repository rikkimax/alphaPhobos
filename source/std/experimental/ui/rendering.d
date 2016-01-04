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
alias EventOnCursorActionDel = void delegate(CursorEventAction action);
///
alias EventOnCursorActionFunc = void function(CursorEventAction action);

///
enum CursorEventAction {
    /**
     * Triggered when the left mouse button is clicked when backed by a mouse.
     */
    Select,
    
    /**
     * Triggered when the right mouse button is clicked when backed by a mouse.
     */
    Alter,
    
    /**
     * Triggered when the middle mouse button is clicked when backed by a mouse.
     */
    ViewChange
}

///
alias EventOnScrollDel = void delegate(short amount);
///
alias EventOnScrollFunc = void function(short amount);

///
alias EventOnCloseDel = void delegate();
///
alias EventOnCloseFunc = void function();

///
alias EventOnKeyDel = void delegate(dchar key, SpecialKey specialKey, ushort KeyModifiers);
///
alias EventOnKeyFunc = void function(dchar key, SpecialKey specialKey, ushort KeyModifiers);

///
enum KeyModifiers : ushort {
    ///
    None = 0,
    
    ///
    Control = 1 << 1,
    ///
    LControl = Control | (1 << 2),
    ///
    RControl = Control | (1 << 3),
    
    ///
    Alt = 1 << 4,
    ///
    LAlt = Alt | (1 << 5),
    ///
    RAlt = Alt | (1 << 6),
    
    ///
    Shift = 1 << 7,
    ///
    LShift = Shift | (1 << 8),
    ///
    RShift = Shift | (1 << 9),
    
    ///
    Super = 1 << 10,
    ///
    LSuper = Super | (1 << 11),
    ///
    RSuper = Super | (1 << 12),
    
    ///
    Capslock = 1 << 13,
    
    ///
    Numlock = 1 << 14,
    
    ///
    ScrollLock = 1 << 15
}

///
enum SpecialKey {
    ///
    None,
    
    ///
    F1,
    ///
    F2,
    ///
    F3,
    ///
    F4,
    ///
    F5,
    ///
    F6,
    ///
    F7,
    ///
    F8,
    ///
    F9,
    ///
    F10,
    ///
    F11,
    ///
    F12,
    
    ///
    Escape,
    ///
    Enter,
    ///
    Backspace,
    ///
    Tab,
    ///
    PageUp,
    ///
    PageDown,
    ///
    End,
    ///
    Home,
    ///
    Insert,
    ///
    Delete,
    ///
    Pause,
    
    ///
    LeftArrow, 
    ///
    RightArrow,
    ///
    UpArrow,
    ///
    DownArrow
}

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
         *  - The left mouse button will be mapped to Select
         *  - The right mouse button will be mapped to Alter
         *  - The middle mouse button will be mapped to ViewChange
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
         *  - The left mouse button will be mapped to Select
         *  - The right mouse button will be mapped to Alter
         *  - The middle mouse button will be mapped to ViewChange
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
        
        /**
         * Upon when render point is non renderable (final) the callback will be called. 
         *
         * If the render point is a window, this will not fire when it is minimized
         *  instead it will only fire when it no longer can be restored.
         *
         * Params:
         *      del     =   The callback to call
         */
        void onClose(EventOnCloseDel del);
        
        ///
        final void onClose(EventOnCloseFunc func) { onClose(func.toDelegate); }
        
        /**
         * When the key is pressed down, the callback is called.
         *
         * Params:
         *      del     =   The callback to call
         */
        void onKeyDown(EventOnKeyDel del);
        
        ///
        final void onKeyDown(EventOnKeyFunc func) { onKeyDown(func.toDelegate); }
        
        /**
         * When the key is no longer pressed down, the callback is called.
         *
         * Params:
         *      del     =   The callback to call
         */
        void onKeyUp(EventOnKeyDel del);
        
        ///
        final void onKeyUp(EventOnKeyFunc func) { onKeyUp(func.toDelegate); }
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
