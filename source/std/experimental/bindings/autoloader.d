/**
 * Maps function pointers to shared library symbols.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz/, Richard Andrew Cattermole)
 */
module std.experimental.bindings.autoloader;
public import std.experimental.bindings.symbolloader : SharedLibVersion;
import std.experimental.bindings.symbolloader;

/// Symbol mangled name, used as a UDA.
struct SymbolName {
    ///
    string name;
}

///
alias SharedLibAutoLoader(string mod = __MODULE__) = SharedLibAutoLoader!([mod]);

///
final class SharedLibAutoLoader(StructWrappers...) : SharedLibLoader {
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
final class SharedLibAutoLoader(string[] modules) : SharedLibLoader {
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

/**
 * Generates bindFunc's for usage in a SharedLibLoader loadSymbols method.
 *
 * Params:
 *      getMinVersion   =   A way to get a SharedLibVersion.
 *                          If a function cannot be loaded that is less then this value
 *                           it will throw an exception.
 *                          If it is null it will default to "SharedLibVersion.init".
 *      modules         =   The modules to look for function pointers
 *
 * Returns:
 *      A string that is usable at CTFE but predominately meant for outputting via pragma msg.
 */
string bindFuncsCodeGeneration(string getMinVersion, string[] modules)() pure {
    import std.conv : text;
    string ret;
    
    string handle() pure {
        string ret2;
        
        foreach(i; 0 .. modules.length){
            if (modules[i].length == 0)
                continue;
            string moduleName = "theModule" ~ i.text;
            ret2 ~= "static import theModule = " ~ modules[i] ~ ";\n"; 
            ret2 ~= "ret ~= bindFuncsHandleContainer!(theModule, \"" ~ moduleName ~ "\",  getMinVersion is null ? \"SharedLibVersion.init\" : getMinVersion);\n";
        }
        
        return ret2;
    }
    
    foreach(i; 0 .. modules.length){
        if (modules[i].length == 0)
            continue;
        string moduleName = "theModule" ~ i.text;
        ret ~= "static import " ~ moduleName ~ " = " ~ modules[i] ~ ";\n";
    }
    
    mixin(handle());
    return ret;
}

/**
 * Generates bindFunc's for usage in a SharedLibLoader loadSymbols method.
 *
 * Will automatically grab the minimum library version as per struct (UDA).
 * If the version does not match, it will throw an exception.
 *
 * Params:
 *      variableWithStructs =   Where the struct instances are to be assigned to.
 *      StructWrappers      =   The structs to generate from.
 *
 * Returns:
 *      A string that is usable at CTFE but predominately meant for outputting via pragma msg.
 */
string bindFuncsCodeGeneration(string variableWithStructs, StructWrappers...)() pure {
    import std.traits : hasUDA;
    string ret;
    
    foreach(i, ST; StructWrappers){
        static if (hasUDA!(ST, SharedLibVersion))
            enum getminVersion = "getUDAs!(Container, SharedLibVersion)[0]";
        else
            enum getminVersion = "SharedLibVersion.init";
    
         ret ~= bindFuncsHandleContainer!(ST, variableWithStructs ~ "[i]", getminVersion);
    }
    
    return ret;
}

/**
 * Generates bindFunc's for usage in a SharedLibLoader loadSymbols method.
 *
 * Params:
 *      variableWithStructs =   Where the struct instances are to be assigned to.
 *      getMinVersion       =   A way to get a SharedLibVersion.
 *                              If a function cannot be loaded that is less then this value
 *                               it will throw an exception.
 *                              If it is null it will default to "SharedLibVersion.init".
 *      StructWrappers      =   The structs to generate from.
 *
 * Returns:
 *      A string that is usable at CTFE but predominately meant for outputting via pragma msg.
 */
string bindFuncsCodeGeneration(string variableWithStructs, string getMinVersion, StructWrappers...)() pure {
    import std.traits : hasUDA;
    string ret;
    
    foreach(i, ST; StructWrappers){
         ret ~= bindFuncsHandleContainer!(ST, variableWithStructs ~ "[i]", getMinVersion is null ? "SharedLibVersion.init" : getMinVersion);
    }
    
    return ret;
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
        }
        
        foreach(i; 0 .. modules.length){
            if (modules[i].length == 0)
                continue;
            string moduleName = "theModule" ~ i.text;
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
    
    string bindFuncsHandleContainer(alias Container, string getvar, string getminVersion)() {
        import std.traits : isFunctionPointer, hasUDA, getUDAs;
        string ret, symbolName;
        bool haveIntroducedVersion;
        
        ret ~= "import std.traits : getUDAs;\n";

        string handle() pure {
            string ret2;
        
            foreach(sym; __traits(allMembers, Container)) {
                ret2 ~= """
static if (__traits(compiles, { bool b = isFunctionPointer!(Container." ~ sym ~ "); }) &&
    isFunctionPointer!(Container." ~ sym ~ ")) {
    static if (hasUDA!(Container." ~ sym ~ ", SymbolName))
        symbolName = getUDAs!(Container." ~ sym ~ ", SymbolName)[0].name;
    else
        symbolName = \"" ~ sym ~  "\";
    haveIntroducedVersion = hasUDA!(Container." ~ sym ~ ", SharedLibVersion);
    
    ret ~= \"bindFunc(cast(void**)&" ~ getvar ~ "." ~ sym ~ ", \\\"\" ~ symbolName ~ \"\\\", \";
    
    if (haveIntroducedVersion) {
        ret ~= \"getUDAs!(" ~ getvar ~ "." ~ sym ~ ", SharedLibVersion)[0] <= \" ~ getminVersion ~ \");\\n\";
    } else {
        ret ~= \"true);\\n\";
    }
}""";
            }
            
            return ret2;
        }
        
        mixin(handle());
        
        return ret;
    }
}
