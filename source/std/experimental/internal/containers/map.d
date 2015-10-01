module std.experimental.internal.containers.map;
import std.experimental.allocator : IAllocator, theAllocator, dispose, expandArray, makeArray;
import std.traits : isPointer;

struct AAMap(K, V) {
    private {
        IAllocator alloc;

        K[] keys;
        V[] values;
    }

    ~this() @trusted {
        if (keys.length > 0) {
            alloc.dispose(keys);
            alloc.dispose(values);
        }
    }

    this(IAllocator alloc) @trusted {
        this.alloc = alloc;
        keys = alloc.makeArray!K(0);
        values = alloc.makeArray!V(0);
    }

    V opIndex(ref K key) @trusted {
        foreach(i, ref k; keys) {
            if (k == key)
                return values[i];
        }

        static if (is(V == class) || is(V == interface) || isPointer!V)
            return null;
        else
            return V.init;
    }

    V opIndex(K key) @trusted {
        foreach(i, ref k; keys) {
            if (k == key)
                return values[i];
        }
        
        static if (is(V == class) || is(V == interface) || isPointer!V)
            return null;
        else
            return V.init;
    }

    void opIndexAssign(V value, K key) @trusted {
        size_t i;

        if (firstEmpty(i)) {
            keys[i] = key;
            values[i] = value;
        } else {
            alloc.expandArray(keys, 1);
            alloc.expandArray(values, 1);
            keys[$-1] = key;
            values[$-1] = value;
        }
    }

    void remove(K key) @trusted {
        foreach(i, k; keys) {
            if (k == key) {
                static if (is(K == class) || is(K == interface) || isPointer!K) {
                    keys[i] = null;

                    static if (is(V == class) || is(V == interface) || isPointer!V)
                        values[i] = null;
                    else
                        values[i] = V.init;
                } else {
                    keys[i] = K.init;

                    static if (is(V == class) || is(V == interface) || isPointer!V)
                        values[i] = null;
                    else
                        values[i] = V.init;
                }
            }
        }
    }

    int opApply(int delegate(ref K, ref V) dg) @trusted {
        int result = 0;

        foreach(i, ref k; keys) {
            result = dg(k, values[i]);
            if (result)
                break;
        }
        return result;
    }

    immutable(K[]) __internalKeys() @trusted {
        return cast(immutable)keys;
    }

    private {
        bool firstEmpty(out size_t idx) @trusted {
            static if (is(K == class) || is(K == interface) || isPointer!K) {
                foreach(i, ref k; keys) {
                    if (k is null) {
                        idx = i;
                        return true;
                    }
                }
            } else {
                foreach(i, ref k; keys) {
                    if (k == K.init) {
                        idx = i;
                        return true;
                    }
                }
            }

            return false;
        }
    }
}

unittest {
    AAMap!(int, string) test = AAMap!(int, string)(theAllocator());

    test[123] = "hi";
    assert(test[123] == "hi");
    test.remove(123);
    assert(test[123] is null);
    test[1234] = "boo";
    assert(test[1234] == "boo");

    assert(test.keys.length == 1);
    assert(test.values.length == 1);

    foreach(k, v; test) {
        assert(k == 1234);
        assert(v == "boo");
    }
}