module std.experimental.collections.linkedlist;
import std.experimental.allocator : IAllocator, theAllocator, make, dispose, shrinkArray, expandArray;
import std.experimental.memory.managed;

struct LinkedList(T) {
    private {
        IAllocator allocator = null;
        SelfMemManager!int memmgr;
    }

    ~this() {
        allocator.dispose(memmgr);
    }

    static managed!(LinkedList!T) opCall(IAllocator alloc=theAllocator()) {
        SelfMemManager!T mgr = alloc.make!(SelfMemManager!T);
        auto ret = managed!(LinkedList!T)(managers(mgr), alloc);

        ret.allocator = alloc;
        ret.memmgr = mgr;

        mgr.alloc = alloc;
        mgr.self = alloc.makeArray!(managed!(LinkedList!T))(1).ptr;
        *mgr.self = ret;

        return ret;
    }
}


final class SelfMemManager(T) {
    uint refCount;
    managed!(LinkedList!T)* self;
    IAllocator alloc;
    
    ~this() {

    }
    
    void opInc() {
        refCount++;
    }
    
    void opDec() {
        refCount--;
    }
    
    bool opShouldDeallocate() {
        return refCount == 1;
    }
}

void tester() {
    import core.memory;
    GC.disable;
    managed!(LinkedList!int) value = LinkedList!int();
}