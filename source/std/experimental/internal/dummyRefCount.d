module std.experimental.internal.dummyRefCount;
import std.experimental.allocator : IAllocator;

/// When std.typecons.RefCounted adds support for allocators this will be replaced by it
struct DummyRefCount(T) {
    ///
    T bytes;
    alias bytes this;
    
    private IAllocator allocator;
    
    ~this() {
        import std.experimental.allocator : dispose;
        allocator.dispose(cast(T)bytes);
    }
}