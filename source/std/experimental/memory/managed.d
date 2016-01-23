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
import std.experimental.allocator : IAllocator, theAllocator, make, dispose, makeArray;
import std.traits : isArray;

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
 * 
 */
auto managers() {
    import std.typecons : Tuple;
    
    MemoryManagerS!(Tuple!()) ret;
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
    return MemoryManagerS!U(args);
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
 * You may not cast away $(D managed!T) or get the real instance of the type. If the usage will not escape it may
 *  be freely used as if $(managed!T) was not used.
 * 
 * When the managed type is an array, it will wrap all slice actions into returning a $(D managed!T) value.
 * This means that all slices are always safe to use and will keep the entirety of the array around until dealloation.
 * Otherwise in normal operations it will act as if it was a normal D array
 *  only using allocators for expanding and shrinking.
 * 
 * See_Also:
 *      IMemoryManager, managers, Ownership
 */
struct managed(MyType) {
@trusted:
    private {
        version(Windows) {
            import core.sys.windows.com : IUnknown;
        }
        
        struct __Internal {
            static if (is(MyType == class) || isArray!MyType) {
                MyType self;
            } else {
                MyType* self;
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
            __internal.allocator.dispose(__internal.self);
        } else {
            // do nothing
            // the default behaviour from opShouldDeallocate if it does not on call is true
        }
    }
    
    auto opCast(T)() {
        static assert(0, "Managed memory may not be casted from");
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

        ret.__internal.self = alloc.make!MyType;
        ret.__internal.memmgrs.opInc();
        return ret;
    }
    
    static if (isArray!MyType) {
        static managed!MyType opCall(MemoryManagerST)(MyType from, Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
            return opCall(from, managers(), ownership, alloc);
        }
        
        static managed!MyType opCall(MemoryManagerST)(MyType from, MemoryManagerST memmgr, Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
            import std.traits : ForeachType;
            
            managed!MyType ret;
            ret.__internal.allocator = alloc;
            static if (is(MemoryManagerST : IMemoryManager)) {
                ret.__internal.memmgrs = memmgr.dup(alloc);
            } else {
                ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
            }
            
            // duplicates if needed
            if (ownership) {
                ret.__internal.self = alloc.makeArray!(ForeachType!MyType)(from.length, from);
            } else {
                ret.__internal.self = from;
            }
            
            ret.__internal.memmgrs.opInc();
            return ret;
        }
    } else static if (is(MyType == class)) {
        version(Windows) {
            // FIXME: MyType != real type
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
            import std.typecons : Tuple;
            
            static managed!MyType opCall(MemoryManagerST)(Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
                return opCall(null, managers(), ownership, alloc);
            }
            
            static managed!MyType opCall(MemoryManagerST)(MyType from, Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
                return opCall(from, managers(), ownership, alloc);
            }
            
            static managed!MyType opCall(MemoryManagerST, ArgsT)(MemoryManagerST memmgr, Tuple!ArgsT args, IAllocator alloc=theAllocator()) {
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
                    if (from is null) {
                        ret.__internal.self = alloc.make!MyType;
                    } else if (ownership) {
                        ret.__internal.self = from.dup(alloc);
                    } else {
                        ret.__internal.self = from;
                    }
                    
                    ret.__internal.memmgrs.opInc();
                    return ret;
                }
            } else {
                static managed!MyType opCall(T...)(MyType from, T t) {
                    static assert(0, MyType.stringof ~ " does not support .dup(IAllocator)"); }
            }
        }
    } else static if (is(MyType == struct) || is(MyType == union)) {
        static managed!MyType opCall(MemoryManagerST)(MyType* from, Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
            return opCall(*from, managers(), ownership, alloc);
        }
        
        static managed!MyType opCall(MemoryManagerST)(MyType* from, MemoryManagerST memmgr, Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
            return opCall(from, memmgr, ownership, alloc);
        }
        
        static managed!MyType opCall(MemoryManagerST)(MyType from, Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
            return opCall(from, managers(), ownership, alloc);
        }
        
        static managed!MyType opCall(MemoryManagerST)(MyType from, MemoryManagerST memmgr, Ownership ownership = Ownership.Primary, IAllocator alloc=theAllocator()) {
            import std.traits : ForeachType;
            
            managed!MyType ret;
            ret.__internal.allocator = alloc;
            static if (is(MemoryManagerST : IMemoryManager)) {
                ret.__internal.memmgrs = memmgr.dup(alloc);
            } else {
                ret.__internal.memmgrs = alloc.make!(MemoryManager!(MyType, MemoryManagerST))(alloc, memmgr);
            }
            
            // duplicates if needed
            if (ownership) {
                ret.__internal.self = alloc.make!MyType;
                *ret.__internal.self = from;
            } else {
                ret.__internal.self = from;
            }
            
            ret.__internal.memmgrs.opInc();
            return ret;
        }
    }
    
    // lazy but perhaps that auto can change to scope?
    // would work still since opScopeAssign would be nullified
    
    @property auto __self() {
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
        bool[typeof(S.managers).length] __doDeAllocateMemMgrs;
        
        this(IAllocator alloc, S s) {
            __origMgrs = s;
            __mgrs = s;
            
            foreach(i, ref mgr; __mgrs.managers) {
                static if (is(typeof(mgr) == class)) {
                    if (mgr is null) {
                        mgr = __alloc.make!(typeof(mgr));
                        __doDeAllocateMemMgrs[i] = true;
                    }
                }
                
                static if (__traits(compiles, {mgr.init(alloc);})) {
                    mgr.init(alloc);
                }
            }
        }
        
        bool opShouldDeallocate() {
            bool hadOne;
            
            foreach(ref mgr; __mgrs.managers) {
                static if (__traits(compiles, {bool ret = mgr.opShouldDeallocate();})) {
                    bool ret = mgr.opShouldDeallocate();
                    hadOne = true;
                    
                    if (ret)
                        return ret;
                }
            }
            
            return !hadOne;
        }
        
        void opInc() {
            foreach(ref mgr; __mgrs.managers) {
                static if (__traits(compiles, {mgr.opInc();})) {
                    mgr.opInc();
                }
            }
        }
        
        void opDec() {
            foreach(ref mgr; __mgrs.managers) {
                static if (__traits(compiles, {mgr.opDec();})) {
                    mgr.opDec();
                }
            }
        }
        
        ~this() {
            foreach(i, ref mgr; __mgrs.managers) {
                static if (is(typeof(mgr) == class)) {
                    if (__doDeAllocateMemMgrs[i]) {
                        mgr = __alloc.dispose(mgr);
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
        
        static if (Type.length > 0) {
            this(Type v) {
                managers = v;
            }
        }
    }
}
