module std.experimental.ui.rendering;
import std.experimental.internal.dummyRefCount;
import std.experimental.allocator : IAllocator;

interface IRenderPoint {
    @property {
        DummyRefCount!IDisplay display();
        IContext context();
        IAllocator allocator();
    }
    
    void close();
}

interface IRenderPointCreator {
    @property {
        void display(IDisplay); // default platform().primaryDisplay
        void allocator(IAllocator); // default std.experimental.allocator.theAllocator()
    }
    
    IRenderPoint create();
}

interface IContext {
    void swapBuffers();
}

interface IDisplay {
    import std.experimental.math.linearalgebra.vector : vec2;
    import std.experimental.ui.window.defs : IWindow;

    @property {
        string name();
        vec2!ushort size();
        uint refreshRate();
        DummyRefCount!(IWindow[]) windows();
        void* __handle();
    }
}
