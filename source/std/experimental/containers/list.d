module std.experimental.containers.list;
import std.experimental.allocator : IAllocator, theAllocator, make, dispose, shrinkArray, expandArray;
import std.experimental.memory.managed;
import std.traits : isArray, isPointer;

struct List(T) {
    private {
        IAllocator allocator;
        T[] values;
        SelfMemManager memmgr;
        managed!(T[]) manslice = void;

        size_t offsetAlloc;

        final class SelfMemManager {
            uint refCount;
            
            void opInc() @safe {
                refCount++;
            }
            
            void opDec() @safe {
                refCount--;
            }
            
            bool opShouldDeallocate() @safe {
                return refCount == 0;
            }
        }
    }

    ~this() @trusted {
        if (memmgr !is null && memmgr.refCount == 0) {
            allocator.dispose(memmgr);
            allocator.dispose(values);
        }
    }
    
    T opIndex(size_t i) @trusted
    in {
        assert(i < values.length);
    } body {
        return values[i];
    }
    
    size_t length() @trusted {
        return values.length-offsetAlloc;
    }
    
    void length(size_t newlen) @trusted {
        import std.traits : isPointer;

        if (newlen < offsetAlloc) {
            offsetAlloc -= newlen;
            return;
        } else if (newlen == 0) {
            offsetAlloc = 1;

            if (values.length > 1) {
                allocator.shrinkArray(values, values.length-1);
            }

            static if (isPointer!T) {
                allocator.dispose(values[0]);
                values[0] = null;
            }

            return;
        }

        if (newlen > values.length) {
            allocator.expandArray(values, newlen - values.length);
        } else if (newlen < values.length) {
            allocator.shrinkArray(values, values.length - newlen);
        }
    }
    
    void opIndexAssign(T value, size_t i) @trusted
    in {
        assert(i < values.length);
    } body {
        values[i] = value;
    }

    static if (is(T == class) || is(T == interface) || isArray!T) {
        int opApply(int delegate(ref managed!T) dg) @trusted {
            int result = 0;

            foreach(i, v; values[0 .. $-offsetAlloc]) {
                auto ret = managed!T(v, managers(memmgr), Ownership.Secondary, allocator);
                result = dg(ret);
                if (result)
                    break;
            }
            return result;
        }
        
        int opApply(int delegate(size_t i, ref managed!T) dg) @trusted {
            int result = 0;
            
            foreach(i, v; values[0 .. $-offsetAlloc]) {
                auto ret = managed!T(v, managers(memmgr), Ownership.Secondary, allocator);
                result = dg(i, ret);
                if (result)
                    break;
            }
            return result;
        }
    } else {
        int opApply(int delegate(ref T) dg) @trusted {
            int result = 0;
            
            foreach(i, v; values[0 .. $-offsetAlloc]) {
                result = dg(v);
                if (result)
                    break;
            }
            return result;
        }
        
        int opApply(int delegate(size_t i, ref T) dg) @trusted {
            int result = 0;
            
            foreach(i, v; values[0 .. $-offsetAlloc]) {
                result = dg(i, v);
                if (result)
                    break;
            }
            return result;
        }
    }
    
    void opOpAssign(string OP)(T value) @trusted if (OP == "~") {
        if (offsetAlloc == 0)
            allocator.expandArray(values, 1);
        else
            offsetAlloc--;

        values[$-(offsetAlloc+1)] = value;
    }

    static managed!(List!T) opCall(IAllocator alloc=theAllocator()) @trusted {
        SelfMemManager mgr = alloc.make!(SelfMemManager);

        List!T ret2;
        ret2.allocator = alloc;
        ret2.memmgr = mgr;

        ret2.offsetAlloc = 1;
        ret2.values = alloc.makeArray!T(1);
        ret2.manslice = managed!(T[])(ret2.values, managers(mgr), Ownership.Secondary, alloc);

        auto ret = managed!(List!T)(ret2, managers(mgr), alloc);

        return ret;
    }

    void remove(T value) {
        size_t i, toShrink;
        for(size_t j = 0; j < values.length; j++) {
            if (values[j] == value) {
                // deallocate
                static if (is(T == class) || is(T == interface) || isArray!T) {
                    allocator.dispose(values[j]);
                }

                values[j] = T.init;
                toShrink++;
            } else
                values[i++] = values[j];
        }

        this.length = values.length - toShrink;
    }

    managed!(T[]) opSlice() @safe {
        return manslice;
    }
}

unittest {
    auto list = List!int(theAllocator());
    assert((cast(size_t)list.values.ptr) > 0);

    list ~= 8;
    list ~= 9;
    list ~= 7;
    
    assert(list.length == 3);
    assert(list[0] == 8);
    assert(list[1] == 9);
    assert(list[2] == 7);
    
    list.length = 2;
    assert(list.length == 2);
    assert(list[0] == 8);
    assert(list[1] == 9);
    
    list[0] = 3;
    assert(list.length == 2);
    assert(list[0] == 3);
    assert(list[1] == 9);

    list.remove(3);
    assert(list.length == 1);
    assert(list[0] == 9);

    list.length = 0;
    assert((cast(size_t)list.values.ptr) > 0);
    assert(list.offsetAlloc == 1);
}