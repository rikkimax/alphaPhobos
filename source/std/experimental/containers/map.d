module std.experimental.containers.map;
import std.experimental.allocator : IAllocator, ISharedAllocator, theAllocator, processAllocator, make, dispose, makeArray, shrinkArray, expandArray;
import std.experimental.memory.managed;
import std.traits : isArray, isPointer;
import core.atomic : atomicOp, atomicLoad;

final class Map(K, V) {
	private {
		IAllocator allocator;
		
		K[] keys_, keys_real;
		V[] values_, values_real;
		
		SelfMemManager memmgr;
		managed!(K[]) mankslice;
		managed!(V[]) manvslice;
		
		size_t offsetAlloc;
	}
	
	~this() @trusted {
		if (memmgr !is null && memmgr.refCount == 0) {
			allocator.dispose(memmgr);
			allocator.dispose(keys_);
			allocator.dispose(values_);
		}
	}
	
	V opIndex(K key) @trusted {
		foreach(i, k; keys_[0 .. $-offsetAlloc]) {
			if (k == key)
				return values_[i];
		}
		
		return V.init;
	}
	
	private {
		size_t length() @trusted {
			return keys_.length-offsetAlloc;
		}
		
		void length(size_t newlen) @trusted {
			import std.traits : isPointer;
			
			if (newlen > keys_real.length && newlen - keys_real.length <= offsetAlloc) {
				offsetAlloc -= newlen - keys_real.length;
				
				keys_real = keys_[0 .. newlen];
				values_real = values_[0 .. newlen];
				
				return;
			} else if (newlen == 0) {
				if (values_.length > 1) {
					offsetAlloc = 1;
					
					allocator.shrinkArray(keys_, keys_.length-1);
					allocator.shrinkArray(values_, values_.length-1);
				}
				
				static if (is(K == class) || is(K == interface)) {
					allocator.dispose(keys_[0]);
				} else static if (isArray!K) {
					allocator.dispose(cast(void[])keys_[0]);
				}
				
				static if (is(V == class) || is(V == interface)) {
					allocator.dispose(values_[0]);
				} else static if (isArray!V) {
					allocator.dispose(cast(void[])values_[0]);
				}
				
				keys_real = keys_[0 .. 0];
				values_real = values_[0 .. 0];
				
				return;
			} else if (newlen > keys_.length) {
				allocator.expandArray(keys_, newlen - keys_.length);
				allocator.expandArray(values_, newlen - values_.length);
			} else if (newlen < keys_.length) {
				allocator.shrinkArray(keys_, keys_.length - newlen);
				allocator.shrinkArray(values_, values_.length - newlen);
			}
			
			keys_real = keys_[0 .. newlen];
			values_real = values_[0 .. newlen];
		}
	}
	
	void opIndexAssign(V value, K key) @trusted {
		foreach(i, k; keys_[0 .. $-offsetAlloc]) {
			if (k == key) {
				values_[i] = value;
				return;
			}
		}
		
		this.length = keys_real.length + 1;
		keys_[length-1] = key;
		values_[length-1] = value;
	}
	
	static if ((is(K == class) || is(K == interface) || isArray!K) && (is(V == class) || is(V == interface) || isArray!V)) {
		int opApply(int delegate(ref managed!K, ref managed!V) dg) @trusted {
			int result = 0;
			
			foreach(i, ref k; keys_[0 .. $-offsetAlloc]) {
				auto retk = managed!K(k, managers(memmgr, NeverDeallocateManager()), allocator);
				auto retv = managed!V(values_[i], managers(memmgr, NeverDeallocateManager()), allocator);
				result = dg(retk, retv);
				if (result)
					break;
			}
			return result;
		}
	} else static if (is(K == class) || is(K == interface) || isArray!K) {
		int opApply(int delegate(ref managed!K, ref V) dg) @trusted {
			int result = 0;
			
			foreach(i, ref k; keys_[0 .. $-offsetAlloc]) {
				auto retk = managed!K(k, managers(memmgr, NeverDeallocateManager()), allocator);
				result = dg(retk, values_[i]);
				if (result)
					break;
			}
			return result;
		}
	} else static if (is(V == class) || is(V == interface) || isArray!V) {
		int opApply(int delegate(ref K, ref managed!V) dg) @trusted {
			int result = 0;
			
			foreach(i, ref k; keys_[0 .. $-offsetAlloc]) {
				auto retv = managed!V(values_[i], managers(memmgr, NeverDeallocateManager()), allocator);
				result = dg(k, retv);
				if (result)
					break;
			}
			return result;
		}
	} else {
		int opApply(int delegate(ref K, ref V) dg) @trusted {
			int result = 0;
			
			foreach(i, ref k; keys_[0 .. length]) {
				result = dg(k, values_[i]);
				if (result)
					break;
			}
			return result;
		}
	}
	
	static managed!(Map!(K, V)) opCall(IAllocator alloc=theAllocator()) @trusted {
		SelfMemManager mgr = alloc.make!(SelfMemManager);
		
		Map!(K, V) ret2 = alloc.make!(Map!(K, V));
		ret2.allocator = alloc;
		ret2.memmgr = mgr;
		
		ret2.offsetAlloc = 1;
		ret2.keys_ = alloc.makeArray!K(1);
		ret2.values_ = alloc.makeArray!V(1);
		ret2.mankslice = managed!(K[])(&ret2.keys_real, managers(mgr), alloc);
		ret2.manvslice = managed!(V[])(&ret2.values_real, managers(mgr), alloc);
		
		auto ret = managed!(Map!(K, V))(ret2, managers(mgr), alloc);
		
		return ret;
	}
	
	void remove(K value) {
		size_t i, toShrink;
		
		for(size_t j = 0; j < length; j++) {
			if (keys_[j] == value) {
				// deallocate
				static if (is(K == class) || is(K == interface)) {
					allocator.dispose(keys_[j]);
				} else static if (isArray!K) {
					allocator.dispose(cast(void[])keys_[j]);
				}
				
				static if (is(V == class) || is(V == interface)) {
					allocator.dispose(values_[j]);
				} else static if (isArray!V) {
					allocator.dispose(cast(void[])values_[j]);
				}
				
				keys_[j] = K.init;
				values_[j] = V.init;
				
				toShrink++;
			} else {
				keys_[i] = keys_[j];
				values_[i++] = values_[j];
			}
		}
		
		length(keys_real.length - toShrink);
	}
	
	managed!(K[]) keys() @safe {
		return mankslice; }
	managed!(V[]) values() @safe {
		return manvslice; }
}

unittest {
	auto test = Map!(int, string)(theAllocator());
	
	test[123] = "hi";
	assert(test[123] == "hi");
	test.remove(123);
	assert(test[123] is null);
	test[1234] = "boo";
	assert(test[1234] == "boo");
	
	assert(test.keys.length == 1);
	
	foreach(k, v; test) {
		assert(k == 1234);
		assert(v == "boo");
	}
}

final class SharedMap(K, V) {
	private {
		shared(ISharedAllocator) allocator;
		
		shared(K[]) keys_, keys_real;
		shared(V[]) values_, values_real;
		
		shared(SelfMemManager) memmgr;
		managed!(shared(K[])) mankslice;
		managed!(shared(V[])) manvslice;
		
		size_t offsetAlloc;
	}
	
	~this() @trusted {
		if (memmgr !is null && memmgr.refCount == 0) {
			allocator.dispose(memmgr);
			allocator.dispose(cast(K[])keys_);
			allocator.dispose(cast(V[])values_);
		}
	}
	
	shared(V) opIndex(shared(K) key) @trusted shared {
		foreach(i, k; keys_[0 .. $-offsetAlloc]) {
			if (k == key)
				return values_[i];
		}
		
		return V.init;
	}
	
	private {
		size_t length() @trusted shared {
			return keys_.length-offsetAlloc;
		}
		
		void length(size_t newlen) @trusted shared {
			import std.traits : isPointer;
			
			if (newlen > keys_real.length && newlen - keys_real.length <= offsetAlloc) {
				atomicOp!"-="(offsetAlloc, newlen - keys_real.length);
				
				keys_real = keys_[0 .. newlen];
				values_real = values_[0 .. newlen];
				
				return;
			} else if (newlen == 0) {
				if (values_.length > 1) {
					offsetAlloc = values_.length;
				}

				foreach(i; 0 .. values_.length) {
					static if (is(K == class) || is(K == interface)) {
						allocator.dispose(keys_[i]);
					} else static if (isArray!K) {
						allocator.dispose(cast(void[])keys_[i]);
					}
					
					static if (is(V == class) || is(V == interface)) {
						allocator.dispose(values_[i]);
					} else static if (isArray!V) {
						allocator.dispose(cast(void[])values_[i]);
					}
				}
				
				keys_real = keys_[0 .. 0];
				values_real = values_[0 .. 0];
				
				return;
			} else if (newlen > keys_.length) {
				K[] tempK = cast(K[])keys_;
				V[] tempV = cast(V[])values_;

				allocator.expandArray(tempK, newlen - keys_.length);
				allocator.expandArray(tempV, newlen - values_.length);

				keys_ = cast(shared)tempK;
				values_ = cast(shared)tempV;
			} else if (newlen < keys_.length) {
				K[] tempK = cast(K[])keys_;
				V[] tempV = cast(V[])values_;
				
				allocator.shrinkArray(tempK, keys_.length - newlen);
				allocator.shrinkArray(tempV, values_.length - newlen);

				keys_ = cast(shared)tempK;
				values_ = cast(shared)tempV;
			}
			
			keys_real = keys_[0 .. newlen];
			values_real = values_[0 .. newlen];
		}
	}
	
	void opIndexAssign(shared(V) value, shared(K) key) @trusted shared {
		foreach(i, k; keys_[0 .. $-offsetAlloc]) {
			if (k == key) {
				values_[i] = value;
				return;
			}
		}
		
		this.length = keys_real.length + 1;
		keys_[length-1] = key;
		values_[length-1] = value;
	}
	
	static if ((is(K == class) || is(K == interface) || isArray!K) && (is(V == class) || is(V == interface) || isArray!V)) {
		int opApply(int delegate(ref managed!(shared(K)), ref managed!(shared(V))) dg) @trusted shared {
			int result = 0;
			
			foreach(i, ref k; keys_[0 .. $-offsetAlloc]) {
				auto retk = managed!K(k, managers(memmgr, NeverDeallocateManager()), allocator);
				auto retv = managed!V(values_[i], managers(memmgr, NeverDeallocateManager()), allocator);
				result = dg(retk, retv);
				if (result)
					break;
			}
			return result;
		}
	} else static if (is(K == class) || is(K == interface) || isArray!K) {
		int opApply(int delegate(ref managed!(shared(K)), ref shared(V)) dg) @trusted shared {
			int result = 0;
			
			foreach(i, ref k; keys_[0 .. $-offsetAlloc]) {
				auto retk = managed!K(k, managers(memmgr, NeverDeallocateManager()), allocator);
				result = dg(retk, values_[i]);
				if (result)
					break;
			}
			return result;
		}
	} else static if (is(V == class) || is(V == interface) || isArray!V) {
		int opApply(int delegate(ref shared(K), ref managed!(shared(V))) dg) @trusted shared {
			int result = 0;
			
			foreach(i, ref k; keys_[0 .. $-offsetAlloc]) {
				auto retv = managed!(shared(V))(values_[i], managers(memmgr, NeverDeallocateManager()), allocator);
				result = dg(k, retv);
				if (result)
					break;
			}
			return result;
		}
	} else {
		int opApply(int delegate(ref shared(K), ref shared(V)) dg) @trusted shared {
			int result = 0;
			
			foreach(i, ref k; keys_[0 .. length]) {
				result = dg(k, values_[i]);
				if (result)
					break;
			}
			return result;
		}
	}
	
	static managed!(shared(SharedMap!(K, V))) opCall(shared(ISharedAllocator) alloc=processAllocator()) @trusted {
		shared(SelfMemManager) mgr = alloc.make!(shared(SelfMemManager));
		
		shared(SharedMap!(K, V)) ret2 = alloc.make!(shared(SharedMap!(K, V)));
		ret2.allocator = alloc;
		ret2.memmgr = mgr;
		
		ret2.offsetAlloc = 1;
		ret2.keys_ = alloc.makeArray!(shared(K))(1);
		ret2.values_ = alloc.makeArray!(shared(V))(1);
		cast()ret2.mankslice = managed!(shared(K[]))(&ret2.keys_real, managers(mgr), alloc);
		cast()ret2.manvslice = managed!(shared(V[]))(&ret2.values_real, managers(mgr), alloc);
		
		auto ret = managed!(shared(SharedMap!(K, V)))(ret2, managers(mgr), alloc);
		
		return ret;
	}
	
	void remove(shared(K) value) shared {
		size_t i, toShrink;
		
		for(size_t j = 0; j < length; j++) {
			if (keys_[j] == value) {
				// deallocate
				static if (is(K == class) || is(K == interface)) {
					allocator.dispose(keys_[j]);
				} else static if (isArray!K) {
					allocator.dispose(cast(void[])keys_[j]);
				}
				
				static if (is(V == class) || is(V == interface)) {
					allocator.dispose(values_[j]);
				} else static if (isArray!V) {
					allocator.dispose(cast(void[])values_[j]);
				}
				
				keys_[j] = K.init;
				values_[j] = V.init;
				
				toShrink++;
			} else {
				keys_[i] = keys_[j];
				values_[i++] = values_[j];
			}
		}
		
		length(keys_real.length - toShrink);
	}
	
	managed!(shared(K[])) keys() @safe shared {
		return mankslice; }
	managed!(shared(V[])) values() @safe shared {
		return manvslice; }
}

unittest {
	auto test = SharedMap!(int, string)(processAllocator());
	
	test[123] = "hi";
	assert(test[123] == "hi");
	test.remove(123);
	assert(test[123] is null);
	test[1234] = "boo";
	assert(test[1234] == "boo");
	
	assert(test.keys.length == 1);
	
	foreach(k, v; test) {
		assert(k == 1234);
		assert(v == "boo");
	}
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
