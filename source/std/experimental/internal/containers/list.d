module std.experimental.internal.containers.list;
import std.experimental.allocator : IAllocator, theAllocator, expandArray, shrinkArray, dispose, makeArray;

struct AllocList(T) {
	private {
		IAllocator alloc;
		T[] values;
	}

	~this() @trusted {
		alloc.dispose(values);
	}

    this(IAllocator alloc) @trusted {
		this.alloc = alloc;
		values = alloc.makeArray!T(0);
	}

    T opIndex(size_t i) @trusted
	in {
		assert(i < values.length);
	} body {
		return values[i];
	}

    size_t length() @trusted {
		return values.length;
	}

    void length(size_t newlen) @trusted {
		if (newlen > values.length) {
			alloc.expandArray(values, newlen - values.length);
		} else if (newlen < values.length) {
			alloc.shrinkArray(values, values.length - newlen);
		}
	}

    void opIndexAssign(T value, size_t i) @trusted
	in {
		assert(i < values.length);
	} body {
		values[i] = value;
	}

    int opApply(int delegate(ref T) dg) @trusted {
		int result = 0;
		
		foreach(i, v; values) {
			result = dg(v);
			if (result)
				break;
		}
		return result;
	}

    int opApply(int delegate(size_t i, ref T) dg) @trusted {
		int result = 0;

		foreach(i, v; values) {
			result = dg(i, v);
			if (result)
				break;
		}
		return result;
	}

    void opOpAssign(string OP)(T value) @trusted if (OP == "~") {
		alloc.expandArray(values, 1);
		values[$-1] = value;
	}
}

unittest {
	AllocList!int list = AllocList!int(theAllocator());
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
}