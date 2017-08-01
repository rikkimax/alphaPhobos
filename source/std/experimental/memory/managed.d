/**
 * Managed memory is a safe wrapper around existing heap allocated memory.
 * Safe heap allocated memory ensures that it cannot be deallocated until such time
 *  it is no longer used.
 * 
 * This has similar usages with refcounting and duplication.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.memory.managed;
import std.experimental.allocator : ISharedAllocator, IAllocator, make, dispose, processAllocator, theAllocator;
import std.typecons : Tuple;
import std.traits : CopyConstness, isBasicType, isPointer, ForeachType, isArray, isDynamicArray, Unqual;

version(Windows) {
	import core.sys.windows.com : IUnknown;
}

/**
 * Defaults to using ReferenceCountedManager as memory manager
 * 
 * See_Also:
 *      ReferenceCountedManager
 */
auto managers() {
	MemoryManagerS!(Tuple!(ReferenceCountedManager)) ret;
	return ret;
}

/**
 * Puts together a group of managers for use with managed!T
 * 
 * See_Also:
 *      managed
 */
auto managers(U...)(U args) if (U.length > 0) {
	return MemoryManagerS!(Tuple!U)(Tuple!U(args));
}

/**
 * Implements a managed memory model representation for heap allocated data.
 * 
 * Ensures all memory allocated is accessed in a safe manner but may result in unsafe data usage. $(BR)
 * Original concept was for language support $(WEB http://cattermole.co.nz/article/managed_memory, link).
 * 
 * This can be thought of in terms of c++ const which is a head only const. A head const is where the pointer may not
 *  not change but the data is modifiable. For example an element in array may be changed but it may not be changed to
 *  another array.
 * 
 * Compatibility with allocators are a requirement, using IAllocator to represent it. This is a optional element and
 *  will by default use theAllocator(). This allows fine grain control over how it allocates on the $(B heap).
 * 
 * When using a COM object as the source, it will assume the responsiblity of AddRef and Releaseing instead
 *  of opInc + opDec. Ensuring deallocation when all references are removed. Rule: has secondary ownership and
 *  will not attempt to deallocate. But may deallocate at any time.
 * 
 * A managed type is compatible with $(D @safe), "$(D @nogc)" and $(D nothrow). However only on the type being represented
 *  all of the methods upon $(D managed!T) itself is @trusted because of how allocators work.
 * 
 * You may not cast away $(D managed!T) or get the real instance of the type. For classes you may cast to a more generic
 * interface/class but not to a more specialised one. For basic types it may be done to another if its size is the same.
 * If the usage will not escape it may be freely used as the real type without casting.
 * 
 * When the managed type is an array, it will wrap all slice actions into returning a $(D managed!T) value.
 * This means that all slices are always safe to use and will keep the entirety of the array around until dealloation.
 * Otherwise in normal operations it will act as if it was a normal D array
 *  only using allocators for expanding and shrinking.
 * 
 * To retrieve a null version, just use $(D (managed!T).init). It will directly compare to $(D null) as true.
 *  Since internally it will be comparing to a pointer while using $(D is).
 * 
 * See_Also:
 *      IMemoryManager, ISharedMemoryManager, managers, ReferenceCountedManager, NeverDeallocateManager
 */
struct managed(Type) {
	static assert(!is(Type==union), "managed!T does not support unions as head type");
	static assert(!isPointer!Type, "managed!T does not support pointers");
	
	static if (ManagedIsShared) {
		alias AllocatorType = shared(ISharedAllocator);
		alias __managedAllocator = processAllocator;
	} else {
		alias AllocatorType = IAllocator;
		alias __managedAllocator = theAllocator;
	}
	
	/// Has this instance been initialized?
	bool isNull() {
		return __managedInternal.managers is null;
	}
	
	// \/ Construction \/
	
	static {
		/// Constructs managed!T where T is a class
		managed!Type opCall(MemoryManagers)(Type value, MemoryManagers managers, AllocatorType allocator=__managedAllocator)
			if (is(Type==class) || is(Type==interface))
			in {
				assert(value !is null, "Class instance must not be null.");
				assert(allocator !is null, "Allocator instance must not be null");
			} body {
			managed!Type ret;
			
			ManagedInternalData.create(ret, managers, allocator);
			ret.__managedInternal.value = value;
			
			return ret;
		}
		
		/// Constructs managed!T where T is a struct or basic type
		managed!Type opCall(MemoryManagers)(Type value, MemoryManagers managers, AllocatorType allocator=__managedAllocator)
			if (isBasicType!Type || is(Type == struct))
			in {
				assert(allocator !is null, "Allocator instance must not be null");
			} body {
			managed!Type ret;
			
			ManagedInternalData.create(ret, managers, allocator);
			ret.__managedInternal.value = value;
			
			return ret;
		}
		
		/// Constructs managed!T where T is an array with elements of class/struct/basic types
		managed!Type opCall(MemoryManagers)(Type value, MemoryManagers managers, AllocatorType allocator=__managedAllocator)
			if (isArray!Type)
			in {
				assert(value.length > 0, "Value instance must not be empty.");
				assert(allocator !is null, "Allocator instance must not be null");
			} body {
			managed!Type ret;
			
			ManagedInternalData.create(ret, managers, allocator);
			ret.__managedInternal.value = value;
			
			return ret;
		}
		
		/// Constructs managed!T where T is a pointer to a class/struct/array/basic type
		managed!Type opCall(MemoryManagers)(Type* value, MemoryManagers managers, AllocatorType allocator=__managedAllocator)
		in {
			assert(value !is null, "Value instance must not be null.");
			assert(allocator !is null, "Allocator instance must not be null");
		} body {
			managed!Type ret;
			
			ManagedInternalData.create(ret, managers, allocator);
			ret.__managedInternal.selfReUpdate = value;
			
			return ret;
		}
		
		/// Constructs managed!T where T is a struct or class type with arguments
		managed!Type opCall(MemoryManagers, ArgsT...)(MemoryManagers managers, Tuple!ArgsT args, AllocatorType allocator=__managedAllocator)
			if (is(Type == class) || is(Type == struct))
			in {
				assert(allocator !is null, "Allocator instance must not be null");
			} body {
			managed!Type ret;
			
			ManagedInternalData.create(ret, managers, allocator);
			
			static if (is(Type == class)) {
				ret.__managedInternal.value = allocator.make!Type(args.expand);
			} else static if (is(Type == struct)) {
				ret.__managedInternal.value = Type(args.expand);
			}
			
			return ret;
		}
	}
	
	// /\ Construction /\
	// \/ Type conversions \/
	
	static if (!(is(Type == const) || is(Type == immutable))) {
		/// Adds const
		managed!(const(Type)) opCast(Type2)() if (is(Type2==managed!(const(Type)))) {
			managed!(immutable(Type)) ret;
			
			__managedInternal.copyInto(ret);
			
			return ret;
		}
		
		/// Adds immutable
		managed!(immutable(Type)) opCast(Type2)() if (is(Type2==managed!(immutable(Type)))) {
			managed!(immutable(Type)) ret;
			
			__managedInternal.copyInto(ret);
			
			return ret;
		}
	}
	
	static if (is(Type==class) || is(Type==interface)) {
		/// Casts class to a more generic type
		managed!(CopyConstness!(Type, Type2)) opCast(Type2:managed!Type2)() if (is(Type:Type2)) {
			managed!(CopyConstness!(Type, Type2)) ret;
			
			__managedInternal.copyInto(ret);
			
			if (__managedInternal.selfReUpdate !is null) {
				ret.__managedInternal.selfReUpdate = cast(Type2*)__managedInternal.selfReUpdate;
			} else {
				ret.__managedInternal.value = cast(Type2)__managedInternal.value;
			}
			
			return ret;
		}

		/// Unsafe-ish dynamic cast, check if is null!
		managed!(CopyConstness!(Type, Type2)) opCast(Type2:managed!Type2)() if (!is(Type:Type2) && (is(Type2 == interface) || is(Type2 == class))) {
			managed!(CopyConstness!(Type, Type2)) ret;

			if (CopyConstness!(Type, Type2) v = cast(CopyConstness!(Type, Type2))__managedGet()) {
				__managedInternal.copyInto(ret);
				
				if (__managedInternal.selfReUpdate !is null) {
					ret.__managedInternal.selfReUpdate = cast(Type2*)__managedInternal.selfReUpdate;
				} else {
					ret.__managedInternal.value = cast(Type2)__managedInternal.value;
				}
			}

			return ret;
		}
	} else static if (is(Type:TypeIf_Class[], TypeIf_Class) && (is(TypeIf_Class == class) || is(TypeIf_Class==interface))) {
		/// Casts an array of classes to a more generic class type
		managed!(CopyConstness!(Type, Type2)[]) opCast(Type2:managed!(Type2[]))() if (is(Type:Type2)) {
			managed!(CopyConstness!(Type, Type2)[]) ret;
			
			__managedInternal.copyInto(ret);
			
			return ret;
		}
	} else static if (isBasicType!Type || is(Type == struct)) {
		/// Casts a basic type to a similar (aka same sized) type
		managed!(CopyConstness!(Type, Type2)) opCast(Type2:managed!Type2)()
		if ((isBasicType!Type2 || is(Type2 == struct)) && Type2.sizeof == Type.sizeof) {
			managed!(CopyConstness!(Type, Type2)) ret;
			
			__managedInternal.copyInto(ret);
			
			return ret;
		}
	} else static if (is(Type:TypeIf_StructBasic[], TypeIf_StructBasic) && (isBasicType!TypeIf_StructBasic || is(TypeIf_StructBasic == struct))) {
		/// Casts an array of structs or basic types to a similar (aka same sized) type
		managed!(CopyConstness!(TypeIf_StructBasic, Type2)[]) opCast(Type2:managed!(Type2[]))()
		if ((isBasicType!Type2 || is(Type2 == struct)) && Type2.sizeof == TypeIf_StructBasic.sizeof) {
			managed!(CopyConstness!(TypeIf_StructBasic, Type2)[]) ret;
			
			__managedInternal.copyInto(ret);
			
			return ret;
		}
	}
	
	// /\ Type convesions /\
	// \/ Reference counting stuff \/
	
	this(this) {
		if (__managedInternal.managers is null)
			return;
		
		__managedInternal.managers.onIncrement();
		
		static if (__traits(compiles, {__managedInternal.value.onIncrement();})) {
			__managedInternal.value.onIncrement();
		}
		
		version(Windows) {
			static if (is(MyType == class) && is(MyType : IUnknown)) {
				__managedInternal.value.AddRef();
			}
		}
	}
	
	~this() {
		if (__managedInternal.managers is null)
			return;
		
		__managedInternal.managers.onDecrement();
		
		static if (__traits(compiles, {__managedInternal.value.onDecrement();})) {
			__managedInternal.value.onDecrement();
		}
		
		bool beenReleased;
		version(Windows) {
			static if ((is(Type==class) || is(Type==interface)) && is(Type:IUnknown)) {
				beenReleased = __managedInternal.value.Release() == 0;
			}
		}
		
		if (beenReleased) {
			__managedInternal.allocator.dispose(__managedInternal.managers);
		} else if (__managedInternal.managers.shouldDeallocate) {
			if (__managedInternal.selfReUpdate is null && !__managedInternal.managers.typeShouldNeverDeallocate) {
				static if (is(Type==struct) || isBasicType!Type) {
				} else static if (isDynamicArray!Type) {
					__managedInternal.allocator.dispose(cast(Unqual!(ForeachType!Type)[])__managedInternal.value);
				} else static if (is(Type == class) || is(Type == interface)) {
					__managedInternal.allocator.dispose(__managedInternal.value);
				}
			}
			__managedInternal.allocator.dispose(__managedInternal.managers);
		} else {
			// do nothing
			// the default behaviour from shouldDeallocate if it does not on call is true
		}
	}
	
	// /\ Reference counting stuff /\
	// \/ Getters \/
	
	static if (isArray!Type) {
		
	}
	
	alias __managedGet this;
	scope ref Type __managedGet() {
		if (__managedInternal.selfReUpdate is null)
			return __managedInternal.value;
		else return *__managedInternal.selfReUpdate;
	}
	
	// /\ Getters /\
	// \/ Internal stuff \/
	
	private {
		enum ManagedIsShared = is(Type == shared);
		ManagedInternalData __managedInternal;
		
		struct ManagedInternalData {
			Type value;
			Type* selfReUpdate;
			
			static if (ManagedIsShared) {
				shared(ISharedAllocator) allocator;
				shared(ISharedMemoryManager) managers;
				
				static void create(MemoryManagerST)(ref managed!Type ctx, MemoryManagerST managers, shared(ISharedAllocator) allocator) {
					ctx.__managedInternal.allocator = allocator;
					
					static if (is(MemoryManagerST : IMemoryManager)) {
						ctx.__managedInternal.managers = managers.dup(alloc);
					} else {
						ctx.__managedInternal.managers = allocator.make!(shared(MemoryManager!(Type, MemoryManagerST)))
							(allocator, managers);
					}
					
					ctx.__managedInternal.managers.onIncrement();
				}
			} else {
				IAllocator allocator;
				IMemoryManager managers;
				
				static void create(MemoryManagerST)(ref managed!Type ctx, MemoryManagerST managers, IAllocator allocator) {
					ctx.__managedInternal.allocator = allocator;
					
					static if (is(MemoryManagerST : IMemoryManager)) {
						ctx.__managedInternal.managers = managers.dup(alloc);
					} else {
						ctx.__managedInternal.managers = allocator.make!(MemoryManager!(Type, MemoryManagerST))
							(allocator, managers);
					}
					
					ctx.__managedInternal.managers.onIncrement();
				}
			}
			
			void copyInto(Into)(ref managed!Into destination) {
				destination.__managedInternal.value = cast(Into)value;
				destination.__managedInternal.selfReUpdate = cast(Into*)selfReUpdate;
				destination.__managedInternal.allocator = allocator;
				destination.__managedInternal.managers = managers;
				destination.__managedInternal.managers.onIncrement();
			}
		}
	}
	
	// /\ Internal stuff /\
}

///
interface IMemoryManager {
	IMemoryManager dup(IAllocator alloc);
	
	/**
	 * on ~this() call
	 */
	bool shouldDeallocate() @safe nothrow;
	
	/**
	 * Is the type even allowed to be deallocated?
	 */
	bool typeShouldNeverDeallocate() @safe nothrow;
	
	/**
	 * this()
	 */
	void onIncrement() @safe nothrow;
	/**
	 * ~this()
	 */
	void onDecrement() @safe nothrow;
}

///
interface ISharedMemoryManager {
	shared(ISharedMemoryManager) dup(shared(ISharedAllocator) alloc) shared;
	
	
	/**
	 * Is the type even allowed to be deallocated?
	 */
	bool typeShouldNeverDeallocate() @safe nothrow shared;
	
	/**
	 * on ~this() call
	 */
	bool shouldDeallocate() @safe nothrow shared;
	
	/**
	 * this()
	 */
	void onIncrement() @safe nothrow shared;
	/**
	 * ~this()
	 */
	void onDecrement() @safe nothrow shared;
}

///
struct ReferenceCountedManager {
	private import core.atomic : atomicOp;
	shared(int) counter;
	
	@safe nothrow {
		bool shouldDeallocate() { return counter <= 0; }
		bool shouldDeallocate() shared { return counter <= 0; }
		
		void onIncrement() { atomicOp!"+="(counter, 1); }
		void onIncrement() shared { atomicOp!"+="(counter, 1); }
		
		void onDecrement() { atomicOp!"-="(counter, 1); }
		void onDecrement() shared { atomicOp!"-="(counter, 1); }
	}
}

///
struct NeverDeallocateManager {
	bool typeShouldNeverDeallocate() @safe nothrow {
		return true;
	}
	
	bool typeShouldNeverDeallocate() @safe nothrow shared {
		return true;
	}
}

private {
	struct MemoryManagerS(Type) {
		Type managers;
		alias managers this;
		
		this(Type v) {
			managers = v;
		}
	}
	
	final class MemoryManager(UserType, UserManagers) : IMemoryManager if (!is(UserType == shared) &&
		isValidUserManagers!(UserType, UserManagers)) {
		
		UserManagers managers, originalManagers;
		bool[UserManagers.length] doDeAllocateMemMgrs;
		IAllocator allocator;
		
		this(IAllocator allocator, UserManagers managers) {
			this.allocator = allocator;
			this.managers = managers;
			this.originalManagers = managers;
			
			foreach(i, ref manager; managers) {
				static if (is(typeof(manager) == class)) {
					if (manager is null) {
						manager = allocator.make!(typeof(manager));
						doDeAllocateMemMgrs[i] = true;
					}
				}
			}
		}
		
		bool shouldDeallocate() @safe nothrow {
			bool hadOne;
			
			static if (UserManagers.length >= 1) {
				foreach(ref manager; managers) {
					static if (__traits(compiles, {bool ret = manager.shouldDeallocate();})) {
						bool ret = manager.shouldDeallocate();
						hadOne = true;
						
						if (ret)
							return ret;
					}
				}
			}
			
			return !hadOne;
		}
		
		bool typeShouldNeverDeallocate() @safe nothrow {
			bool hadOne;
			
			static if (UserManagers.length >= 1) {
				foreach(ref manager; managers) {
					static if (__traits(compiles, {bool ret = manager.typeShouldNeverDeallocate();})) {
						bool ret = manager.typeShouldNeverDeallocate();
						hadOne = true;
						
						if (!ret)
							return ret;
					}
				}
			}
			
			return hadOne;
		}
		
		void onIncrement() @safe nothrow {
			foreach(ref manager; managers) {
				static if (__traits(compiles, {manager.onIncrement();})) {
					manager.onIncrement();
				}
			}
		}
		
		void onDecrement() @safe nothrow {
			foreach(ref manager; managers) {
				static if (__traits(compiles, {manager.onDecrement();})) {
					manager.onDecrement();
				}
			}
		}
		
		IMemoryManager dup(IAllocator alloc) {
			return alloc.make!(MemoryManager!(UserType, UserManagers))(alloc, originalManagers);
		}
		
		~this() {
			foreach(i, ref manager; managers) {
				static if (is(typeof(manager) == class)) {
					if (doDeAllocateMemMgrs[i]) {
						allocator.dispose(manager);
					}
				}
			}
		}
	}
	
	final class MemoryManager(UserType, UserManagers) : ISharedMemoryManager if (is(UserType == shared) &&
		isValidUserManagers!(UserType, UserManagers)) {
		
		UserManagers managers, originalManagers;
		bool[UserManagers.length] doDeAllocateMemMgrs;
		shared(ISharedAllocator) allocator;
		
		this(shared(ISharedAllocator) allocator, UserManagers managers) shared {
			this.allocator = allocator;
			this.managers = managers;
			this.originalManagers = managers;
			
			foreach(i, ref manager; managers) {
				static if (is(typeof(manager) == class)) {
					if (manager is null) {
						manager = allocator.make!(typeof(manager));
						doDeAllocateMemMgrs[i] = true;
					}
				}
			}
		}
		
		bool shouldDeallocate() @safe nothrow shared {
			bool hadOne;
			
			static if (UserManagers.length >= 1) {
				foreach(ref manager; managers) {
					static if (__traits(compiles, {bool ret = manager.shouldDeallocate();})) {
						bool ret = manager.shouldDeallocate();
						hadOne = true;
						
						if (!ret)
							return ret;
					}
				}
			}
			
			return !hadOne;
		}
		
		
		bool typeShouldNeverDeallocate() @safe nothrow shared {
			bool hadOne;
			
			static if (UserManagers.length >= 1) {
				foreach(ref manager; managers) {
					static if (__traits(compiles, {bool ret = manager.typeShouldNeverDeallocate();})) {
						bool ret = manager.typeShouldNeverDeallocate();
						hadOne = true;
						
						if (ret)
							return ret;
					}
				}
			}
			
			return hadOne;
		}
		
		void onIncrement() @safe nothrow shared {
			foreach(ref manager; managers) {
				static if (__traits(compiles, {manager.onIncrement();})) {
					manager.onIncrement();
				}
			}
		}
		
		void onDecrement() @safe nothrow shared {
			foreach(ref manager; managers) {
				static if (__traits(compiles, {manager.onDecrement();})) {
					manager.onDecrement();
				}
			}
		}
		
		shared(ISharedMemoryManager) dup(shared(ISharedAllocator) alloc) shared {
			return alloc.make!(shared(MemoryManager!(UserType, UserManagers)))(alloc, originalManagers);
		}
		
		~this() shared {
			foreach(i, ref manager; managers) {
				static if (is(typeof(manager) == class)) {
					if (doDeAllocateMemMgrs[i]) {
						allocator.dispose(manager);
					}
				}
			}
		}
	}
	
	bool isValidUserManagers(UserType, Ts)() pure {
		bool ret = true;
		
		foreach(T; Ts.Types) {
			static if ((is(UserType == shared) == is(T == shared)) && !(is(T == class) || is(T == struct))) {
				ret = false;
			}
		}
		
		return ret;
	}
}