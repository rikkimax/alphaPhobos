module std.experimental.collections.linkedlist;
import std.experimental.allocator : IAllocator, theAllocator;
import std.experimental.memory.managed;

struct LinkedList(T) {
    private {
        IAllocator allocator;

    }



    static managed!(LinkedList!T) opCast(IAllocator alloc=theAllocator()) {
        auto ret = managed!(LinkedList!T)(alloc);

        ret.allocator = alloc;

        return ret;
    }
}

unittest {
    managed!(LinkedList!int) value = LinkedList!int(theAllocator());

}