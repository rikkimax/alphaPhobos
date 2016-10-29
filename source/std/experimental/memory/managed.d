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
public import std.typecons : tuple;
import std.experimental.allocator : IAllocator, theAllocator, make, dispose, makeArray;
import std.typecons : Tuple;
import std.traits : isArray, isBasicType;
import std.range : ForeachType;

/**
 * Do you own this memory?
 * 
 * If no this implys you should not deallocate unless told otherwise and prevents duplication
 */
enum Ownership : bool {
    ///
    Primary = true,
    ///
    Secondary = false
}

/**
 * Defaults to using ManagedRefCount as memory manager
 * 
 * See_Also:
 *      ManagedRefCount
 */
auto managers() {
    import std.typecons : Tuple;
    
    MemoryManagerS!(Tuple!(ManagedRefCount)) ret;
    return ret;
}

/**
 * 
 */
auto managers(MyType, T...)() if (T.length > 0) {
    import std.typecons : Tuple;
    
    mixin(managersAliasFixUp!(MyType, T));
    
    return MemoryManagerS!O.init;
}

/**
 * 
 */
auto managers(U...)(U args) if (U.length > 0) {
    import std.typecons : Tuple;
    return MemoryManagerS!(Tuple!U)(Tuple!U(args));
}

/**
 * 
 * 
 * See_Also:
 *      managers
 */
interface IMemoryManager {
    ///
    IMemoryManager dup(IAllocator);
    
    /**
     * on ~this() call
     */
    bool opShouldDeallocate();
    
    /**
     * this()
     */
    void opInc();
    /**
     * ~this()
     */
    void opDec();
}

/**
 * Implements a managed memory model representation for heap allocated data.
 * 
 * Ensures all memory allocated is accessed in a safe manner but may result in unsafe data usage. $(BR)
 * Original concept was for language support $(WEB wiki.dlang.org/User:Alphaglosined/ManagedMemory, link).
 * 
 * This can be thought of in terms of c++ const which is a head only const. A head const is where the pointer may not
 *  not change but the data is modifiable. For example an element in array may be changed but it may not be changed to
 *  another array.
 * 
 * Compatibility with allocators are a requirement, using IAllocator to represent it. This is a optional element and
 *  will by default use theAllocator(). This allows fine grain control over how it allocates on the $(B heap).
 * 
 * Managed memory may not be allocated upon the stack. It is passed around on the stack using at most 3 pointers to
 *  represent the real type.
 * 
 * When using a COM object as the source, it will assume the responsiblity of AddRef and Releaseing instead
 *  of opInc + opDec. Ensuring deallocation when all references are removed. Rule: has secondary ownership and
 *  will not attempt to deallocate. But may deallocate at any time.
 * 
 * A managed type is compatible with $(D @safe), $(D @nogc) and $(D nothrow). However only on the type being represented
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
 *      IMemoryManager, managers, Ownership
 */
struct managed(MyType) {
    // this exists for support for e.g. std.experimental.image
    alias PayLoadType = MyType;

@trusted:
    private {
        final class SPointer {
            MyType __self = void;
            alias __self this;
        }

        version(Windows) {
            import core.sys.windows.com : IUnknown;
        }
        
        struct __Internal {
			MyType* selfReUpdate;

			static if (is(MyType == class) || is(MyType == interface) || isArray!MyType) {
            	MyType self;
            } else {
                SPointer self;
            }
            
            IAllocator allocator;
            IMemoryManager memmgrs;
        }
        
        __Internal __internal;
    }

    this(this) {
        // opInc
        __internal.memmgrs.opInc();
        
        static if (__traits(compiles, {__internal.self.opInc();})) {
            __internal.self.opInc();
        }
        version(Windows) {
            static if (is(MyType == class) && is(MyType : IUnknown)) {
                __internal.self.AddRef();
            }
        }
    }

	~this() {
        // check to make sure we are allocated/initialized
        if (__internal.self is null)
            return;

        // opDec
        __internal.memmgrs.opDec();
        
        bool beenReleased;
        
        static if (__traits(compiles, {__internal.self.opDec();})) {
            __internal.self.opDec();
        }
        version(Windows) {
            static if (is(MyType == class) && is(MyType : IUnknown)) {
                beenReleased = __internal.self.Release() == 0;
            }
        }
        
        if (beenReleased) {
        } else if (__internal.memmgrs.opShouldDeallocate) {
            __internal.allocator.dispose(__internal.memmgrs);
			if (__internal.selfReUpdate is null) {
				static if (isArray!MyType) {
					import std.traits : Unqual, ForeachType;
					__internal.allocator.dispose(cast(Unqual!(ForeachType!MyType)[])__internal.self);
				} else {
					__internal.allocator.dispose(cast(Object)__internal.self);
				}
			}
        } else {
            // do nothing
            // the default behaviour from opShouldDeallocate if it does not on call is true
        }
    }

    static if (is(MyType == class) || is(MyType == interface)) {
        import std.traits : isInstanceOf, moduleName;

        auto opCast(TMyType2)() if (moduleName!TMyType2 == __MODULE__ && __traits(hasMember, TMyType2, "__internal")) {
            alias MyType2 = TMyType2.PayLoadType;

            static if (is(MyType : MyType2)) {
                managed!MyType2 ret;

                ret.__internal.self = cast(MyType2)__internal.self;
                ret.__internal.memmgrs = __internal.memmgrs;
                ret.__internal.allocator = __internal.allocator;

				ret.__internal.memmgrs.opInc();
				return ret;
            } else {
                static assert(0, "A managed object may only be casted to a more generic version");
            }
        }

        auto opCast(TMyType2)() if (!(moduleName!TMyType2 == __MODULE__ && __traits(hasMember, TMyType2, "__internal"))) {
            static assert(0, "Managed memory may not be casted from");
        }
    } else static if (isArray!MyType && (is(ForeachType!MyType == class) || is(ForeachType!MyType == interface))) {
        import std.traits : moduleName;
        
        auto opCast(TMyType2)() if (moduleName!TMyType2 == __MODULE__ && __traits(hasMember, TMyType2, "__internal")) {
            alias MyType2 = TMyType2.PayLoadType;
            
            static if (is(ForeachType!MyType : ForeachType!MyType2)) {
                managed!MyType2 ret;
                
                ret.__internal.self = cast(MyType2)__internal.self;
                ret.__internal.memmgrs = __internal.memmgrs;
                ret.__internal.allocator = __internal.allocator;
                
				ret.__internal.memmgrs.opInc();
				return ret;
            } else {
                static assert(0, "A managed object may only be casted to a more generic version");
            }
        }
        
        auto opCast(TMyType2)() if (!(moduleName!TMyType2 == __MODULE__ && __traits(hasMember, TMyType2, "__internal"))) {
            static assert(0, "Managed memory may not be casted from");
        }
    } else static if (isArray!MyType && isBasicType!(ForeachType!MyType)) {
        import std.traits : moduleName, Unqual;

        auto opCast(TMyType2)() if (moduleName!TMyType2 == __MODULE__ && __traits(hasMember, TMyType2, "__internal")) {
            alias MyType2 = Unqual!(TMyType2.PayLoadType);

            static if ((ForeachType!MyType2).sizeof == (ForeachType!MyType).sizeof) {
                managed!MyType2 ret;
                
                ret.__internal.self = cast(MyType2)__internal.self;
                ret.__internal.memmgrs = __internal.memmgrs;
                ret.__internal.allocator = __internal.allocator;
                
				ret.__internal.memmgrs.opInc();
				return ret;
            } else {
                static assert(0, "Managed memory may only be cast from if resulting size is identical to original");
            }
        }

        auto opCast(TMyType2)() if (!(moduleName!TMyType2 == __MODULE__ && __traits(hasMember, TMyType2, "__internal"))) {
            static assert(0, "Managed memory may not be casted from");
        }
    } else {
        auto opCast(TMyType2)() {
            static assert(0, "Managed memory may not be casted from");
        }
    }
    
    // FIXME: should be scope only
    /+static if (is(MyType == class) || isArray!MyType) {
        MyType opScopeAssign() {
            return __internal.self;
        }
    } else {
        MyType* opScopeAssign() {
            return __internal.self;
        }
    }+/
    
    /+static if (isArray!MyType) {
        // TODO: array specific things
    } else {
        // TODO: class, struct and union specific things
        //       add method indirection as last, memory managers go first in call chain
    }+/

    static if (!isArray!MyType && __traits(compiles, {MyType v = new MyType;})) {
        static managed!MyType opCall(IAllocator alloc=theAllocator()) {
            return opCall(managers(), alloc);
        }
        
        static managed!MyType opCall(MemoryManagerST)(MemoryManagerST memmgr, IAllocator alloc=theAllocator()) {
            managed!MyType ret;
            ret.__internal.allocator = alloc;
            static if (is(MemoryManagerST : IMemoryManager)) {
                ret.__internal.memmgrs = memmgr.dup(alloc);
            } else {
                ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
            }

            static if (!isArray!MyType) {
                ret.__internal.self = alloc.make!(typeof(ret.__internal.self));
            }
            ret.__internal.memmgrs.opInc();
            return ret;
        }
    }
    
    static if (isArray!MyType) {
        static managed!MyType opCall(MemoryManagerST)(MyType from, Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
            return opCall(from, managers(), ownership, alloc);
        }
        
        static managed!MyType opCall(MemoryManagerST)(MyType from, MemoryManagerST memmgr, Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
            import std.traits : ForeachType, Unqual;
            
            managed!MyType ret;
            ret.__internal.allocator = alloc;
            static if (is(MemoryManagerST : IMemoryManager)) {
                ret.__internal.memmgrs = memmgr.dup(alloc);
            } else {
                ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
            }
            
            // duplicates if needed
            if (ownership) {
                ret.__internal.self = cast(MyType)alloc.makeArray!(Unqual!(ForeachType!MyType))(from.length);
                cast(Unqual!(ForeachType!MyType)[])ret.__internal.self[] = from[];
            } else {
                ret.__internal.self = from;
            }
            
            ret.__internal.memmgrs.opInc();
            return ret;
        }

		static managed!MyType opCall(MemoryManagerST)(MyType* from, IAllocator alloc=theAllocator()) {
			return opCall(from, managers(), ownership, alloc);
		}
		
		static managed!MyType opCall(MemoryManagerST)(MyType* from, MemoryManagerST memmgr, IAllocator alloc=theAllocator()) {
			import std.traits : ForeachType, Unqual;
			
			managed!MyType ret;
			ret.__internal.allocator = alloc;
			static if (is(MemoryManagerST : IMemoryManager)) {
				ret.__internal.memmgrs = memmgr.dup(alloc);
			} else {
				ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
			}
			
			ret.__internal.selfReUpdate = from;
			ret.__internal.memmgrs.opInc();
			return ret;
		}
    } else static if (is(MyType == class) || is(MyType == interface)) {
        version(Windows) {
            static if (is(MyType == class) && is(MyType : IUnknown)) {
                private enum ___IUKCMT = true;
                
                static managed!MyType opCall(MemoryManagerST)(MyType from, MemoryManagerST memmgr=managers(), IAllocator alloc=theAllocator()) {
                    import std.traits : ForeachType;
                    
                    managed!MyType ret;
                    ret.__internal.allocator = alloc;
                    static if (is(MemoryManagerST : IMemoryManager)) {
                        ret.__internal.memmgrs = memmgr.dup(alloc);
                    } else {
                        ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
                    }
                    
                    ret.__internal.self = from;
                    
                    ret.__internal.memmgrs.opInc();
                    return ret;
                }
            }
        }
        
        static if (!is(___IUKCMT)) {            
            static managed!MyType opCall(MemoryManagerST)(Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
                return opCall(null, managers(), ownership, alloc);
            }
            
            static managed!MyType opCall(MemoryManagerST)(MyType from, Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
                return opCall(from, managers(), ownership, alloc);
            }
            
            static managed!MyType opCall(MemoryManagerST, ArgsT...)(MemoryManagerST memmgr, Tuple!ArgsT args, IAllocator alloc=theAllocator()) {
                managed!MyType ret;
                ret.__internal.allocator = alloc;
                static if (is(MemoryManagerST : IMemoryManager)) {
                    ret.__internal.memmgrs = memmgr.dup(alloc);
                } else {
                    ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
                }

                ret.__internal.self = alloc.make!MyType(args.expand);
                
                ret.__internal.memmgrs.opInc();
                return ret;
            }
            
            static if (__traits(compiles, {IAllocator alloc; MyType v, v2; v2 = v.dup(alloc);})) {
                static managed!MyType opCall(MemoryManagerST)(MyType from, MemoryManagerST memmgr, Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
                    managed!MyType ret;
                    ret.__internal.allocator = alloc;
                    static if (is(MemoryManagerST : IMemoryManager)) {
                        ret.__internal.memmgrs = memmgr.dup(alloc);
                    } else {
                        ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
                    }
                    
                    // duplicates if needed

                    if (ownership) {
						if (from is null) {
							static if (__traits(compiles, {ret.__internal.self = alloc.make!MyType;})) {
								ret.__internal.self = alloc.make!MyType;
							} else {
								return managed!MyType.init;
							}
						} else {
                        	ret.__internal.self = from.dup(alloc);
						}
                    } else {
                        ret.__internal.self = from;
                    }
                    
                    ret.__internal.memmgrs.opInc();
                    return ret;
                }
            } else {
                static managed!MyType opCall(MemoryManagerST)(MyType from, MemoryManagerST memmgr, Ownership ownership = Ownership.Secondary, IAllocator alloc=theAllocator()) {
                    assert(ownership == Ownership.Secondary, "Secondary only for classes that do not support .dup(IAllocator)");

                    managed!MyType ret;
                    ret.__internal.allocator = alloc;
                    static if (is(MemoryManagerST : IMemoryManager)) {
                        ret.__internal.memmgrs = memmgr.dup(alloc);
                    } else {
                        ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
                    }

                    ret.__internal.self = from;
                    ret.__internal.memmgrs.opInc();
                    return ret;
                }
            }
        }
    } else static if (is(MyType == struct) || is(MyType == union)) {
        static managed!MyType opCall(MemoryManagerST)(MyType from, MemoryManagerST memmgr, IAllocator alloc=theAllocator()) {
            import std.traits : ForeachType;
            
            managed!MyType ret;
            ret.__internal.allocator = alloc;
            static if (is(MemoryManagerST : IMemoryManager)) {
                ret.__internal.memmgrs = memmgr.dup(alloc);
            } else {
                ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
            }
            
            ret.__internal.self = alloc.make!SPointer;
            ret.__internal.self.__self = from;
            
            ret.__internal.memmgrs.opInc();
            return ret;
        }

		static managed!MyType opCall(MemoryManagerST, ArgsT...)(MemoryManagerST memmgr, Tuple!ArgsT args, IAllocator alloc=theAllocator()) {
			import std.traits : ForeachType;
			
			managed!MyType ret;
			ret.__internal.allocator = alloc;
			static if (is(MemoryManagerST : IMemoryManager)) {
				ret.__internal.memmgrs = memmgr.dup(alloc);
			} else {
				ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
			}
			
			ret.__internal.self = alloc.make!SPointer;
			ret.__internal.self.__self = MyType(args.expand);
			
			ret.__internal.memmgrs.opInc();
			return ret;
		}

		static managed!MyType opCall(MemoryManagerST)(MemoryManagerST memmgr, IAllocator alloc=theAllocator()) {
			import std.traits : ForeachType;
			
			managed!MyType ret;
			ret.__internal.allocator = alloc;
			static if (is(MemoryManagerST : IMemoryManager)) {
				ret.__internal.memmgrs = memmgr.dup(alloc);
			} else {
				ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
			}
			
			ret.__internal.self = alloc.make!SPointer;
			ret.__internal.memmgrs.opInc();
			return ret;
		}
    }
    
    // lazy but perhaps that auto can change to scope?
    // would work still since opScopeAssign would be nullified
    
    @property auto __self() {
		if (__internal.selfReUpdate !is null)
			__internal.self = *__internal.selfReUpdate;
        return __internal.self;
    }
    
    alias __self this;
}

private {
    string managersAliasFixUp(MyType, T...)() pure {
        import std.traits : moduleName;
        import std.conv : text;
        string ret, retI;
        
        ret ~= "alias O = Tuple!(";
        
        foreach(i, U; T) {
            retI ~= "static import TI_" ~ i.text ~ " = " ~ moduleName!(U) ~ ";\n";
            
            static if (__traits(compiles, U!MyType)) {
                ret ~= "TI_" ~ i.text ~ "." ~ __traits(identifier, U) ~ "!MyType, ";
            } else {
                ret ~= "TI_" ~ i.text ~ "." ~ U.stringof ~ ", ";
            }
        }
        
        return retI ~ ret ~ ");";
    }
    
    final class MemoryManager(MyType, S) : IMemoryManager {
        S __mgrs, __origMgrs;

        static if (__traits(compiles, {size_t v = S.managers.length;}) && S.managers.length > 0) {
            enum TLEN = S.managers.length;
        } else static if (!__traits(compiles, {size_t v = S.managers.length;}) && !is(S.managers == void)) {
            enum TLEN = 1;
        } else {
            enum TLEN = 0;
        }

        bool[TLEN] __doDeAllocateMemMgrs;
        IAllocator __alloc;
        
        this(IAllocator alloc, S s) {
            __origMgrs = s;
            __mgrs = s;
            __alloc = alloc;

            static if (TLEN >= 1) {
                foreach(i, ref mgr; __mgrs.managers) {
                    static if (is(typeof(mgr) == class)) {
                        if (mgr is null) {
                            mgr = alloc.make!(typeof(mgr));
                            __doDeAllocateMemMgrs[i] = true;
                        }
                    }
                    
                    static if (__traits(compiles, {mgr.init(alloc);})) {
                        mgr.init(alloc);
                    }
                }
            }
        }
        
        bool opShouldDeallocate() {
            bool hadOne;

            static if (TLEN >= 1) {
                foreach(ref mgr; __mgrs.managers) {
                    static if (__traits(compiles, {bool ret = mgr.opShouldDeallocate();})) {
                        bool ret = mgr.opShouldDeallocate();
                        hadOne = true;
                        
                        if (ret)
                            return ret;
                    }
                }
            }
            
            return !hadOne;
        }
        
        void opInc() {
            static if (TLEN >= 1) {
                foreach(ref mgr; __mgrs.managers) {
                    static if (__traits(compiles, {mgr.opInc();})) {
                        mgr.opInc();
                    }
                }
            }
        }
        
        void opDec() {
            static if (TLEN >= 1) {
                foreach(ref mgr; __mgrs.managers) {
                    static if (__traits(compiles, {mgr.opDec();})) {
                        mgr.opDec();
                    }
                }
            }
        }
        
        ~this() {
            static if (TLEN >= 1) {
                foreach(i, ref mgr; __mgrs.managers) {
                    static if (is(typeof(mgr) == class)) {
                        if (__doDeAllocateMemMgrs[i]) {
                            __alloc.dispose(mgr);
                        }
                    }
                }
            }
        }
        
        IMemoryManager dup(IAllocator alloc) {
            return alloc.make!(MemoryManager!(MyType, S))(alloc, __origMgrs);
        }
    }
    
    struct MemoryManagerS(Type) {
        Type managers;
        alias managers this;

        this(Type v) {
            managers = v;
        }
    }
}

/// Provides a basic but resonable ref counted manager
struct ManagedRefCount {
    uint refCount;
    
    void opInc() {
        refCount++;
    }
    
    void opDec() {
        refCount--;
    }
    
    bool opShouldDeallocate() {
		return refCount == 0;
    }
}

/// Provides a basic prevention mechanism for deallocation
struct ManagedNoDeallocation {
    bool opShouldDeallocate() {
        return false;
    }
}