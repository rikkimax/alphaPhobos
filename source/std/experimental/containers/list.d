module std.experimental.containers.list;
import std.experimental.allocator : IAllocator, ISharedAllocator, theAllocator, processAllocator, make, dispose, makeArray, shrinkArray, expandArray;
import std.experimental.memory.managed;
import std.traits : isArray, isPointer;
import core.atomic : atomicOp, atomicLoad;

final class List(T) {
	private {
		IAllocator allocator;
		T[] values_raw, values_real;
		SelfMemManager memmgr;
		managed!(T[]) manslice;
		
		size_t offsetAlloc;
	}
	
	~this() @trusted {
		if (memmgr !is null && memmgr.refCount == 0) {
			allocator.dispose(memmgr);
			allocator.dispose(values_raw);
		}
	}
	
	T opIndex(size_t i) @trusted
	in {
		assert(i < values_raw.length);
	} body {
		return values_raw[i];
	}
	
	size_t length() @trusted {
		return values_raw.length-offsetAlloc;
	}
	
	void length(size_t newlen) @trusted {
		import std.traits : isPointer;
		
		if (newlen < offsetAlloc) {
			offsetAlloc -= newlen;
			values_real = values_raw[0 .. newlen];
			return;
		} else if (newlen == 0) {
			offsetAlloc = 1;
			
			if (values_raw.length > 1) {
				allocator.shrinkArray(values_raw, values_raw.length-1);
			}
			
			static if (isPointer!T) {
				allocator.dispose(values_raw[0]);
				values_raw[0] = null;
			}
			
			values_real = values_raw[0 .. newlen];
			return;
		}
		
		if (newlen > values_raw.length) {
			allocator.expandArray(values_raw, newlen - values_raw.length);
		} else if (newlen < values_raw.length) {
			allocator.shrinkArray(values_raw, values_raw.length - newlen);
		}
		
		values_real = values_raw[0 .. newlen];
	}
	
	void opIndexAssign(T value, size_t i) @trusted
	in {
		assert(i < values_raw.length);
	} body {
		values_raw[i] = value;
	}
	
	static if (is(T == class) || is(T == interface) || isArray!T) {
		int opApply(int delegate(ref managed!T) dg) @trusted {
			int result = 0;
			
			foreach(i, v; values_raw[0 .. $-offsetAlloc]) {
				auto ret = managed!T(v, managers(memmgr, NeverDeallocateManager()), allocator);
				result = dg(ret);
				if (result)
					break;
			}
			return result;
		}
		
		int opApply(int delegate(size_t i, ref managed!T) dg) @trusted {
			int result = 0;
			
			foreach(i, v; values_raw[0 .. $-offsetAlloc]) {
				auto ret = managed!T(v, managers(memmgr, NeverDeallocateManager()), allocator);
				result = dg(i, ret);
				if (result)
					break;
			}
			return result;
		}
	} else {
		int opApply(int delegate(ref T) dg) @trusted {
			int result = 0;
			
			foreach(i, v; values_raw[0 .. $-offsetAlloc]) {
				result = dg(v);
				if (result)
					break;
			}
			return result;
		}
		
		int opApply(int delegate(size_t i, ref T) dg) @trusted {
			int result = 0;
			
			foreach(i, v; values_raw[0 .. $-offsetAlloc]) {
				result = dg(i, v);
				if (result)
					break;
			}
			return result;
		}
	}
	
	void opOpAssign(string OP)(T value) @trusted if (OP == "~") {
		if (offsetAlloc == 0)
			allocator.expandArray(values_raw, 1);
		else
			offsetAlloc--;
		
		values_raw[$-(offsetAlloc+1)] = value;
	}
	
	static managed!(List!T) opCall(IAllocator alloc=theAllocator()) @trusted {
		SelfMemManager mgr = alloc.make!(SelfMemManager);
		
		List!T ret2 = alloc.make!(List!T);
		ret2.allocator = alloc;
		ret2.memmgr = mgr;
		
		ret2.offsetAlloc = 1;
		ret2.values_raw = alloc.makeArray!T(1);
		ret2.manslice = managed!(T[])(&ret2.values_real, managers(mgr), alloc);
		
		auto ret = managed!(List!T)(ret2, managers(mgr, NeverDeallocateManager()), alloc);
		
		return ret;
	}
	
	void remove(T value) {
		size_t i, toShrink;
		for(size_t j = 0; j < values_raw.length; j++) {
			if (values_raw[j] == value) {
				// deallocate
				static if (is(T == class) || is(T == interface) || isArray!T) {
					allocator.dispose(values_raw[j]);
				}
				
				values_raw[j] = T.init;
				toShrink++;
			} else
				values_raw[i++] = values_raw[j];
		}
		
		this.length = values_real.length - toShrink;
	}
	
	managed!(T[]) opSlice() @safe {
		return manslice;
	}
}

unittest {
	auto list = List!int(theAllocator());
	assert((cast(size_t)list.values_raw.ptr) > 0);
	
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
	assert((cast(size_t)list.values_raw.ptr) > 0);
	assert(list.offsetAlloc == 1);
}

final class SharedList(T) {
	private {
		shared(ISharedAllocator) allocator;
		
		shared(T[]) values_raw, values_real;
		
		shared(SelfMemManager) memmgr;
		managed!(shared(T[])) manslice;
		
		size_t offsetAlloc;
	}
	
	~this() @trusted {
		if (memmgr !is null && memmgr.refCount == 0) {
			allocator.dispose(memmgr);
			allocator.dispose(cast(void[])values_raw);
		}
	}
	
	shared(T) opIndex(size_t i) @trusted shared
	in {
		assert(i < values_raw.length);
	} body {
		return values_raw[i];
	}
	
	size_t length() @trusted shared {
		return values_raw.length-offsetAlloc;
	}
	
	void length(size_t newlen) @trusted shared {
		import std.traits : isPointer, Unqual;
		
		if (newlen < offsetAlloc) {
			atomicOp!"-="(offsetAlloc, newlen);
			values_real = values_raw[0 .. newlen];
			return;
		} else if (newlen == 0) {
			offsetAlloc = values_raw.length;
			
			foreach(i; 0 .. values_raw.length) {
				static if (isPointer!T) {
					allocator.dispose(values_raw[i]);
					values_raw[i] = null;
				}
			}
			
			values_real = values_raw[0 .. 0];
			return;
		}
		
		if (newlen > values_raw.length) {
			auto temp = cast(Unqual!T[])values_raw;
			allocator.expandArray(temp, newlen - values_raw.length);
			values_raw = cast(shared(T[]))temp;
		} else if (newlen < values_raw.length) {
			auto temp = cast(Unqual!T[])values_raw;
			allocator.shrinkArray(temp, values_raw.length - newlen);
			values_raw = cast(shared(T[]))temp;
		}
		
		values_real = values_raw[0 .. newlen];
	}
	
	void opIndexAssign(shared(T) value, size_t i) @trusted shared
	in {
		assert(i < values_raw.length);
	} body {
		values_raw[i] = value;
	}
	
	static if (is(T == class) || is(T == interface) || isArray!T) {
		int opApply(int delegate(ref managed!(shared(T))) dg) @trusted shared {
			int result = 0;
			
			foreach(i, v; values_raw[0 .. $-offsetAlloc]) {
				auto ret = managed!(shared(T))(v, managers(memmgr, NeverDeallocateManager()), allocator);
				result = dg(ret);
				if (result)
					break;
			}
			return result;
		}
		
		int opApply(int delegate(size_t i, ref managed!(shared(T))) dg) @trusted {
			int result = 0;
			
			foreach(i, v; values_raw[0 .. $-offsetAlloc]) {
				auto ret = managed!(shared(T))(v, managers(memmgr, NeverDeallocateManager()), allocator);
				result = dg(i, ret);
				if (result)
					break;
			}
			return result;
		}
	} else {
		int opApply(int delegate(ref shared(T)) dg) @trusted shared {
			int result = 0;
			
			foreach(i, v; values_raw[0 .. $-offsetAlloc]) {
				result = dg(v);
				if (result)
					break;
			}
			return result;
		}
		
		int opApply(int delegate(size_t i, ref shared(T)) dg) @trusted shared {
			int result = 0;
			
			foreach(i, v; values_raw[0 .. $-offsetAlloc]) {
				result = dg(i, v);
				if (result)
					break;
			}
			return result;
		}
	}
	
	void opOpAssign(string OP)(T value) @trusted shared if (OP == "~") {
		import std.traits : Unqual;

		if (offsetAlloc == 0) {
			auto temp = cast(Unqual!T[])values_raw;
			allocator.expandArray(temp, 1);
			values_raw = cast(T[])temp;
		} else
			atomicOp!"-="(offsetAlloc, 1);
		
		values_raw[$-(offsetAlloc+1)] = value;
	}
	
	static managed!(shared(SharedList!T)) opCall(shared(ISharedAllocator) alloc=processAllocator()) @trusted {
		shared(SelfMemManager) mgr = alloc.make!(shared(SelfMemManager));
		
		shared(SharedList!T) ret2 = alloc.make!(shared(SharedList!T));
		ret2.allocator = alloc;
		ret2.memmgr = mgr;
		
		ret2.offsetAlloc = 1;
		ret2.values_raw = alloc.makeArray!(shared(T))(1);
		cast()ret2.manslice = managed!(shared(T[]))(&ret2.values_real, managers(mgr), alloc);
		
		auto ret = managed!(shared(SharedList!T))(ret2, managers(mgr, NeverDeallocateManager()), alloc);
		
		return ret;
	}
	
	void remove(shared(T) value) shared {
		size_t i, toShrink;
		for(size_t j = 0; j < values_raw.length; j++) {
			if (values_raw[j] == value) {
				// deallocate
				static if (is(T == class) || is(T == interface)) {
					allocator.dispose(values_raw[j]);
				} else static if (isArray!T) {
					allocator.dispose(cast(void[])values_raw[j]);
				}
				
				values_raw[j] = T.init;
				toShrink++;
			} else
				values_raw[i++] = values_raw[j];
		}
		
		this.length = values_real.length - toShrink;
	}
	
	managed!(shared(T[])) opSlice() @safe shared {
		return manslice;
	}
}

unittest {
	auto list = SharedList!int(processAllocator());
	assert((cast(size_t)list.values_raw.ptr) > 0);
	
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
	assert((cast(size_t)list.values_raw.ptr) > 0);
	assert(list.offsetAlloc == 1);
}

private final class SelfMemManager {
	uint refCount;
	
	void onIncrement() @safe nothrow { refCount++; }
	void onIncrement() @safe nothrow shared  { atomicOp!"+="(refCount, 1); }
	
	void onDecrement() @safe nothrow { refCount--; }
	void onDecrement() @safe nothrow shared { atomicOp!"-="(refCount, 1); }
	
	bool shouldDeallocate() @safe nothrow { return refCount == 0; }
	bool shouldDeallocate() @safe nothrow shared { return atomicLoad(refCount) == 0; }
}
