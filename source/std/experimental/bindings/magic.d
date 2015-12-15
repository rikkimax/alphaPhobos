/**
 * Maps function pointers to shared library symbols.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz/, Richard Andrew Cattermole)
 */
module std.experimental.bindings.magic;
public import std.experimental.bindings.symbolloader : SharedLibVersion;
import std.experimental.bindings.symbolloader;

/// Symbol mangled name, used as a UDA.
struct SymbolName {
    ///
    string name;
}

///
alias MagicalSharedLibLoader(string mod = __MODULE__) = MagicalSharedLibLoader!([mod]);

///
final class MagicalSharedLibLoader(StructWrappers...) : SharedLibLoader {
    private {
        import std.traits : isFunctionPointer, hasUDA, getUDAs;
        SharedLibVersion minVersion;
    }
    
    /// The structs that contain the function pointers
    StructWrappers structs;
    
    public this( string libNames ) {
        super(libNames);
    }
    
    public this( string[] libNames ...) {
        super(libNames);
    }
    
    protected {
        override void loadSymbols() {
            foreach(i, ST; StructWrappers){
                mixin(handleContainer("ST", "structs[i]"));
            }
        }
                
        override void configureMinimumVersion( SharedLibVersion minVersion ) {
            this.minVersion = minVersion;
        }
    }
}

///
final class MagicalSharedLibLoader(string[] modules) : SharedLibLoader {
    private {
        import std.traits : isFunctionPointer, hasUDA, getUDAs;
        SharedLibVersion minVersion;
    }
    
    public this( string libNames ) {
        super(libNames);
    }
    
    public this( string[] libNames ...) {
        super(libNames);
    }
    
    protected {
        override void loadSymbols() {
            mixin(generateForImports(modules));
        }
        
        override void configureMinimumVersion( SharedLibVersion minVersion ) {
            this.minVersion = minVersion;
        }
    }
}

private {
    string generateForImports(string[] modules) pure {
        import std.conv : text;
        string ret;
        
        foreach(i; 0 .. modules.length){
            if (modules[i].length == 0)
                continue;
            string moduleName = "theModule" ~ i.text;
            ret ~= "static import " ~ moduleName ~ " = " ~ modules[i] ~ ";\n";
            ret ~= handleContainer(moduleName, moduleName);
        }
        
        return ret;
    }
    
    string handleContainer(string gettype, string getvar) pure {
        return """
foreach(sym; __traits(allMembers, " ~ gettype ~ ")) {
    static if (mixin(\"__traits(compiles, { bool b = isFunctionPointer!(" ~ gettype ~ ".\" ~ sym ~ \"); })\") &&
               mixin(\"isFunctionPointer!(" ~ gettype ~ ".\" ~ sym ~ \")\")){
               
        string symbolName;
        SharedLibVersion introducedVersion;
        
        static if (hasUDA!(__traits(getMember, " ~ gettype ~ ", sym), SymbolName))
            symbolName = getUDAs!(__traits(getMember, " ~ gettype ~ ", sym), SymbolName)[0].name;
        else
            symbolName = sym;
            
        static if (hasUDA!(__traits(getMember, " ~ gettype ~ ", sym), SharedLibVersion))
            introducedVersion = getUDAs!(__traits(getMember, " ~ gettype ~ ", sym), SharedLibVersion)[0];
        else
            introducedVersion = SharedLibVersion.init;
            
        bindFunc(cast(void**)mixin(\"&" ~ getvar ~ ".\" ~ sym), symbolName, introducedVersion <= minVersion);
    }
}""";
    }
}
