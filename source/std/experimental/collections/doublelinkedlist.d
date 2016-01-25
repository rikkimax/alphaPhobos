module std.experimental.collections.linkedlist;
import std.experimental.allocator : IAllocator, theAllocator, make, dispose, shrinkArray, expandArray;
import std.experimental.memory.managed;

struct DoubleLinkedList(T) {
    private {
        IAllocator allocator;
        SelfMemManager memmgr;

        final class SelfMemManager {
            uint refCount;
            managed!(DoubleLinkedList!T)* self;
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

        struct Element {
            uint refCount;
            Element* next, last;
            T value;
        }

        size_t lastElementIndex;
        Element[] elements;
    }

    ~this() {
        if (allocator !is null) {
            allocator.dispose(memmgr);
        }
    }

    void add(T value) {
        auto index = nextAvailableIndex();

        if (index == -1) {
            index = elements.length;
            allocator.expandArray(elements, 1);
        } else {
            elements[index].next = null;
            elements[index].last = null;
        }

        elements[index].value = value;
        elements[index].refCount = 1;

        if (index > 0) {
            elements[index].last = &elements[lastElementIndex];

            elements[lastElementIndex].next = &elements[index];
            lastElementIndex = index;
        }
    }

    void remove(T value) {
        Element* ele = elements.length > 0 ? elements.ptr : null;

        while (ele !is null) {
            if (ele.value == value) {
                ele.refCount--;

                if (ele.last !is null) {
                    ele.last.next = ele.next;
                }

                if (ele.next !is null) {
                    ele.next.last = ele.last;
                }
            }

            ele = ele.next;
        }
    }

    int opApply(int delegate(ref T) del) {
        Element* ele = elements.length > 0 ? elements.ptr : null;
        
        while (ele !is null) {
            int r = del(ele.value);
            if (r)
                return r;
            
            ele = ele.next;
        }
        
        return 0;
    }

    int opApply(int delegate(size_t, ref T) del) {
        Element* ele = elements.length > 0 ? elements.ptr : null;

        size_t i;
        while (ele !is null) {
            int r = del(i, ele.value);
            if (r)
                return r;
            
            ele = ele.next;
            i++;
        }

        return 0;
    }

    private {
        ptrdiff_t nextAvailableIndex() {
            foreach(i, v; elements) {
                if (v.refCount == 0)
                    return i;
            }

            return -1;
        }
    }

    static managed!(DoubleLinkedList!T) opCall(IAllocator alloc=theAllocator()) {
        SelfMemManager mgr = alloc.make!(SelfMemManager);
        auto ret = managed!(DoubleLinkedList!T)(managers(mgr), alloc);

        ret.allocator = alloc;
        ret.memmgr = mgr;

        mgr.alloc = alloc;
        mgr.self = alloc.makeArray!(managed!(DoubleLinkedList!T))(1).ptr;
        *mgr.self = ret;

        return ret;
    }
}

unittest {
    import core.memory;
    GC.disable;
    managed!(DoubleLinkedList!int) value = DoubleLinkedList!int();
    value.add(10);

    import std.stdio;
    // FIXME: that pointer to a value really shouldn't be needed...
    foreach(v; *value) {
        writeln("V: ", v);
    }
}