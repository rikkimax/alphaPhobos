module std.experimental.collections.linkedlist;
import std.experimental.allocator : IAllocator, theAllocator, make, dispose, shrinkArray, expandArray;
import std.experimental.memory.managed;

struct LinkedList(T) {
    private {
        IAllocator allocator;
        SelfMemManager memManager;

        final class SelfMemManager {

        }
    }



    static managed!(LinkedList!T) opCast(IAllocator alloc=theAllocator()) {
        SelfMemManager mgr = alloc.make!SelfMemManager;
        auto ret = managed!(LinkedList!T)(managers(mgr), alloc);

        ret.allocator = alloc;
        ret.memManager = mgr;

        return ret;
    }
}

unittest {
    managed!(LinkedList!int) value = LinkedList!int(theAllocator());

}