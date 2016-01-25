module std.experimental.internal.dummyRefCount;
import std.experimental.allocator : IAllocator;

/// When std.typecons.RefCounted adds support for allocators this will be replaced by it
//deprecated
struct DummyRefCount(T) {
    alias PayLoadType = T;
    PayLoad* payload;

    ///
    alias bytes this;

    this(T data, IAllocator alloc) @trusted {
        import std.experimental.allocator : make;

        if (data is null || alloc is null) {}
        else
            payload = alloc.make!PayLoad(data, alloc, 1);
    }

    private {
        struct PayLoad {
            T bytes;
            IAllocator alloc;
            size_t count;
        }
    }

    ///
    @property T bytes() @trusted @nogc nothrow {
        if (payload is null)
            return null;
        else
            return payload.bytes;
    }

    this(this) @trusted @nogc nothrow {
        if (payload !is null)
            payload.count++;
    }

    ~this() @trusted {
        if (payload !is null) {
            import std.experimental.allocator : dispose;

            payload.count--;
            if (payload.count == 0)
                payload.alloc.dispose(payload);
        }
    }
}

