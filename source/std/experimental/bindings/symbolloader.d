/**
 * Loads shared libraries and maps them to function pointers.
 * Utility code for bindings creation.
 * 
 * This module originates from DerelictUtil. It is one of the oldest of D's libraries.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://dblog.aldacron.net/, Mike Parker)
 */
module std.experimental.bindings.symbolloader;
import std.string : toStringz;

/**
 * Represents a version for a shared library
 * Can be used as a UDA.
 */
struct SharedLibVersion {
    ///
    int major;
    ///
    int minor;
    ///
    int patch;
    
    ///
    int opCmp(ref const SharedLibVersion other) const {
        int a, b;
        
        a = major * 100_000;
        a += minor * 100;
        a += patch;
        
        b = other.major * 100_000;
        b += other.minor * 100;
        b += patch;
        
        if (a < b)
            return -(b - a);
        else if (a > b)
            return a - b;
        else
            return 0;
    }
}

/// Informs the symbol loader too look inside the host binary.
enum SELF_SYMBOL_LOOKUP = "!..SelfLookup..!";

/**
 * The return type of the MissingSymbolCallbackFunc/Dg.
 */
enum ShouldThrow {
    ///
    No,
    
    ///
    Yes
}

/**
 * The MissingSymbolCallback allows the user to prevent the throwing of SymbolLoadExceptions.
 * By default, a SymbolLoadException is thrown when a symbol cannot be found in a shared
 *  library.
 *
 * Assigning a MissingSymbolCallback to a loader allows the application to override
 *  this behavior.
 * If the missing symbol in question can be ignored, the callback should
 *  return ShouldThrow.No to prevent the exception from being thrown. Otherwise, the
 *  return value should be ShouldThrow.Yes.
 *
 * This is useful to allow a binding implemented
 *  for version N.N of a library to load older or newer versions that may be missing
 *  functions the loader expects to find, provided of course that the app does not need
 *  to use those functions.
 */
alias MissingSymbolCallbackFunc = ShouldThrow function( string symbolName );

/// Ditto
alias MissingSymbolCallbackDg = ShouldThrow delegate( string symbolName );

/// Convenient alias to use as a return value.
alias MissingSymbolCallback = MissingSymbolCallbackDg;

/**
 * A handy utility abstract class for wrapping SharedLib.
 * Extend it, implement loadSymbols and use it to manage a binding.
 */
abstract class SharedLibLoader {
    private {
        import std.array : split;
        import std.string : strip;
    
        string _libNames;
        string[] _libNames2;
        
        SharedLib _lib;
    }

    /**
     * Constructs a new instance of shared lib loader with a string of one
     * or more shared library names to use as default.
     *
     * If SELF_SYMBOL_LOOKUP is provided as a library name, it will look up
     * symbols inside of the host binary.
     *
     * Params:
     *      libNames    =   A string containing one or more comma-separated shared
     *                       library names.
     */
    public this( string libNames ) {
        _libNames = libNames;
    }
    
    /// Ditto
    public this( string[] libNames ...) {
        _libNames2 = libNames;
    }

    public final {
        /**
         * Finds and loads a shared library, using this loader's default shared library
         * names and default supported shared library version.
         *
         * If multiple library names are specified as default, a SharedLibLoadException
         *  will only be thrown if all of the libraries fail to load. It will be the head
         *  of an exceptin chain containing one instance of the exception for each library
         *  that failed.
         *
         * Examples:
         *      If this loader supports versions 2.0 and 2.1 of a shared libary,
         *       this method will attempt to load 2.1 and will fail if only 2.0
         *       is present on the system.
         *
         * Throws:
         *      SharedLibLoadException if the shared library or one of its
         *       dependencies cannot be found on the file system.
         *      SymbolLoadException if an expected symbol is missing from the
         *       library.
         */
        void load() {
            if (_libNames !is null)
                load( _libNames );
            else if (_libNames2 !is null)
                load( _libNames2);
            else assert(0);
        }

        /**
         * Finds and loads any version of a shared library greater than or equal to
         *  the required mimimum version, using this loader's default shared library
         *  names.
         *
         * If multiple library names are specified as default, a SharedLibLoadException
         *  will only be thrown if all of the libraries fail to load. It will be the head
         *  of an exceptin chain containing one instance of the exception for each library
         *  that failed.
         *
         * Examples:
         *      If this loader supports versions 2.0 and 2.1 of a shared library,
         *       passing a SharedLibVersion with the major field set to 2 and the
         *       minor field set to 0 will cause the loader to load version 2.0
         *       if version 2.1 is not available on the system.
         *
         * Params:
         *      minRequiredVersion  =   The minimum version of the library that is acceptable.
         *                              Subclasses are free to ignore this.
         * Throws:
         *      SharedLibLoadException if the shared library or one of its
         *       dependencies cannot be found on the file system.
         *       SymbolLoadException if an expected symbol is missing from the
         *       library.
         */
        void load( SharedLibVersion minRequiredVersion ) {
            configureMinimumVersion( minRequiredVersion );
            load();
        }

        /**
         * Finds and loads a shared library, using libNames to find the library
         *  on the file system.
         *
         * If multiple library names are specified in libNames, a SharedLibLoadException
         *  will only be thrown if all of the libraries fail to load. It will be the head
         *  of an exceptin chain containing one instance of the exception for each library
         *  that failed.
         *
         * If SELF_SYMBOL_LOOKUP is provided as a library name, it will look up
         * symbols inside of the host binary.
         *
         * Examples:
         *      If this loader supports versions 2.0 and 2.1 of a shared libary,
         *       this method will attempt to load 2.1 and will fail if only 2.0
         *       is present on the system.
         * Params:
         *      libNames    =   A string containing one or more comma-separated shared
         *                       library names.
         *
         * Throws:
         *      SharedLibLoadException if the shared library or one of its
         *       dependencies cannot be found on the file system.
         *       SymbolLoadException if an expected symbol is missing from the
         *       library.
         */
        void load( string libNames ) {
            assert( libNames !is null );

            auto lnames = libNames.split( "," );
            foreach( ref string l; lnames )
                l = l.strip();

            load( lnames );
        }

        /**
         * Finds and loads any version of a shared library greater than or equal to
         *  the required mimimum version, using libNames to find the library
         *  on the file system.
         *
         * If multiple library names are specified as default, a SharedLibLoadException
         *  will only be thrown if all of the libraries fail to load. It will be the head
         *  of an exceptin chain containing one instance of the exception for each library
         *  that failed.
         *
         * If SELF_SYMBOL_LOOKUP is provided as a library name, it will look up
         * symbols inside of the host binary.
         *
         * Examples:
         *      If this loader supports versions 2.0 and 2.1 of a shared library,
         *       passing a SharedLibVersion with the major field set to 2 and the
         *       minor field set to 0 will cause the loader to load version 2.0
         *       if version 2.1 is not available on the system.
         *
         * Params:
         *      libNames    =   A string containing one or more comma-separated shared
         *                       library names.
         *  minRequiredVersion = The minimum version of the library that is acceptable.
         *                       Subclasses are free to ignore this.
         *
         * Throws:
         *      SharedLibLoadException if the shared library or one of its
         *       dependencies cannot be found on the file system.
         *      SymbolLoadException if an expected symbol is missing from the
         *       library.
         */
        void load( string libNames, SharedLibVersion minRequiredVersion ) {
            configureMinimumVersion( minRequiredVersion );
            load( libNames );
        }

        /**
         * Finds and loads a shared library, using libNames to find the library
         *  on the file system.
         *
         * If multiple library names are specified in libNames, a SharedLibLoadException
         *  will only be thrown if all of the libraries fail to load. It will be the head
         *  of an exceptin chain containing one instance of the exception for each library
         *  that failed.
         *
         * If SELF_SYMBOL_LOOKUP is provided as a library name, it will look up
         * symbols inside of the host binary.
         *
         * Params:
         *      libNames    =   An array containing one or more shared library names,
         *                       with one name per index.
         * Throws:
         *      SharedLibLoadException if the shared library or one of its
         *       dependencies cannot be found on the file system.
         *      SymbolLoadException if an expected symbol is missing from the
         *       library.
         */
        void load( string[] libNames ) {
            _lib.load( libNames );
            loadSymbols();
        }

        /**
         * Finds and loads any version of a shared library greater than or equal to
         * the required mimimum version, , using libNames to find the library
         * on the file system.
         *
         * If multiple library names are specified in libNames, a SharedLibLoadException
         *  will only be thrown if all of the libraries fail to load. It will be the head
         *  of an exceptin chain containing one instance of the exception for each library
         *  that failed.
         *
         * If SELF_SYMBOL_LOOKUP is provided as a library name, it will look up
         * symbols inside of the host binary.
         *
         * Examples:
         *      If this loader supports versions 2.0 and 2.1 of a shared library,
         *       passing a SharedLibVersion with the major field set to 2 and the
         *       minor field set to 0 will cause the loader to load version 2.0
         *       if version 2.1 is not available on the system.
         *
         * Params:
         *      libNames            =   An array containing one or more shared library names,
         *                               with one name per index.
         *      minRequiredVersion  =   The minimum version of the library that is acceptable.
         *                              Subclasses are free to ignore this.
         * Throws:  
         *      SharedLibLoadException if the shared library or one of its
         *       dependencies cannot be found on the file system.
         *      SymbolLoadException if an expected symbol is missing from the
         *       library.
         */
        void load( string[] libNames, SharedLibVersion minRequiredVersion ) {
            configureMinimumVersion( minRequiredVersion );
            load( libNames );
        }

        /**
         * Unloads the shared library from memory, invalidating all function pointers
         *  which were assigned a symbol by one of the load methods.
         */
        void unload() {
            _lib.unload();
        }

        @property {
            /// Returns: true if the shared library is loaded, false otherwise.
            bool isLoaded() {
                return _lib.isLoaded;
            }

            /**
             * Sets the callback that will be called when an expected symbol is
             * missing from the shared library.
             *
             * Params:
             *      callback    =   A delegate that returns a value of type
             *                       ShouldThrow and accepts a string as the sole parameter.
             */
            void missingSymbolCallback( MissingSymbolCallbackDg callback ) {
                _lib.missingSymbolCallback = callback;
            }

            /**
             * Sets the callback that will be called when an expected symbol is
             *  missing from the shared library.
             *
             * Params:
             *      callback    =   A pointer to a function that returns a value of type
             *                       ShouldThrow and accepts a string as the sole parameter.
             */
            void missingSymbolCallback( MissingSymbolCallbackFunc callback ) {
                _lib.missingSymbolCallback = callback;
            }

            /**
             * Returns the currently active missing symbol callback.
             *
             * This exists primarily as a means to save the current callback before
             *  setting a new one. It's useful, for example, if the new callback needs
             *  to delegate to the old one.
             */
            MissingSymbolCallback missingSymbolCallback() {
                return _lib.missingSymbolCallback;
            }
        }
    }

    protected {
        /**
         * Must be implemented by subclasses to load all of the symbols from a
         * shared library.
         * This method is called by the load methods.
         */
        abstract void loadSymbols();

        /**
         * Allows a subclass to install an exception handler for specific versions
         *  of a library before loadSymbols is called.
         *
         * This method is optional. If the subclass does not implement it, calls to
         *  any of the overloads of the load method that take a SharedLibVersion will
         *  cause a compile time assert to fire.
         */
        void configureMinimumVersion( SharedLibVersion minVersion ) {
            assert( 0, "SharedLibVersion is not supported by this loader." );
        }

        /**
         * Subclasses can use this as an alternative to bindFunc, but must bind
         * the returned symbol manually.
         * 
         * bindFunc calls this internally, so it can be overloaded to get behavior
         *  different from the default.
         *
         * Params:
         *      name    =   The name of the symbol to load.
         *      doThrow =   If true, a SymbolLoadException will be thrown if the symbol
         *                   is missing. If false, no exception will be thrown and the
         *                   ptr parameter will be set to null.
         * Throws:
         *      SymbolLoadException if doThrow is true and a the symbol
         *       specified by funcName is missing from the shared library.
         * Returns:
         *      The symbol matching the name parameter.
         */
        void* loadSymbol( string name, bool doThrow = true ) {
            return _lib.loadSymbol( name, doThrow );
        }

        /// Returns a reference to the shared library wrapped by this loader.
        final ref SharedLib lib() @property {
            return _lib;
        }

        /**
         * Subclasses can use this to bind a function pointer to a symbol in the
         *  shared library.
         *
         * Params:
         *      ptr         =   Pointer to a function pointer that will be used
         *                       as the bind point.
         *      funcName    =   The name of the symbol to be bound.
         *      doThrow     =   If true, a SymbolLoadException will be thrown
         *                       if the symbol is missing.
         *                      If false, no exception will be thrown and the
         *                       ptr parameter will be set to null.
         * Throws:
         *      SymbolLoadException if doThrow is true and a the symbol
         *       specified by funcName is missing from the shared library.
         */
        final void bindFunc( void** ptr, string funcName, bool doThrow = true ) {
            void* func = loadSymbol( funcName, doThrow );
            *ptr = func;
        }
    }
}

/**
 * This exception is thrown when a shared library cannot be loaded
 *  because it is either missing or not on the system path.
 */
class SharedLibLoadException : Exception
{
    private string _sharedLibName;

    public {
        static void throwNew( string[] libNames, string[] reasons ) {
            string msg = "Failed to load one or more shared libraries:";
            foreach( i, n; libNames ) {
                msg ~= "\n\t" ~ n ~ " - ";
                if( i < reasons.length )
                    msg ~= reasons[i];
                else
                    msg ~= "Unknown";
            }
            throw new SharedLibLoadException( msg );
        }

        this( string msg ) {
            super( msg );
            _sharedLibName = "";
        }

        this( string msg, string sharedLibName ) {
            super( msg );
            _sharedLibName = sharedLibName;
        }

        string sharedLibName() {
            return _sharedLibName;
        }
    }
}

/**
 * This exception is thrown when a symbol cannot be loaded from a shared library,
 *  either because it does not exist in the library or because the library is corrupt.
 */
class SymbolLoadException : Exception
{
    private string _symbolName;

    public {
        this( string msg ) {
            super( msg );
        }

        this( string sharedLibName, string symbolName ) {
            super( "Failed to load symbol " ~ symbolName ~ " from shared library " ~ sharedLibName );
            _symbolName = symbolName;
        }

        string symbolName() {
            return _symbolName;
        }
    }
}

/**
 * Low-level wrapper of the even lower-level operating-specific shared library
 *  loading interface.
 * 
 * While this interface can be used directly in applications, it is recommended
 *  to use the interface specified by SharedLibLoader or SymbolLoader
 *  to implement bindings. SharedLib is designed to be the base of a higher-level
 *  loader, but can be used in a program if only a handful of functions need to
 *  be loaded from a given shared library.
 */
struct SharedLib {
    private {
        string _name;
        SharedLibHandle _hlib;
        private MissingSymbolCallbackDg _onMissingSym;
    }

    public {
        /**
         * Finds and loads a shared library, using libNames to find the library
         *  on the file system.
         *
         * If multiple library names are specified in libNames, a SharedLibLoadException
         *  will only be thrown if all of the libraries fail to load. It will be the head
         *  of an exceptin chain containing one instance of the exception for each library
         *  that failed.
         *
         * Params:
         *      libNames    =   An array containing one or more shared library names,
         *                       with one name per index.
         * Throws:
         *      SharedLibLoadException if the shared library or one of its
         *       dependencies cannot be found on the file system.
         *      SymbolLoadException if an expected symbol is missing from the
         *       library.
         */
        void load( string[] names ) {
            if( isLoaded )
                return;

            string[] failedLibs;
            string[] reasons;

            foreach( n; names ) {
                _hlib = LoadSharedLib( n );
                if( _hlib !is null ) {
                    _name = n;
                    break;
                }

                failedLibs ~= n;
                reasons ~= GetErrorStr();
            }

            if( !isLoaded ) {
                SharedLibLoadException.throwNew( failedLibs, reasons );
            }
        }

        /**
         * Loads the symbol specified by symbolName from a shared library.
         *
         * Params:
         *      symbolName  =   The name of the symbol to load.
         *      doThrow     =   If true, a SymbolLoadException will be thrown if the symbol
         *                       is missing. If false, no exception will be thrown and the
         *                       ptr parameter will be set to null.
         *
         * Throws:
         *      SymbolLoadException if doThrow is true and a the symbol
         *       specified by funcName is missing from the shared library.
         */
        void* loadSymbol( string symbolName, bool doThrow = true ) {
            void* sym = GetSymbol( _hlib, symbolName );
            if( doThrow && !sym ) {
                auto result = ShouldThrow.Yes;
                if( _onMissingSym !is null )
                    result = _onMissingSym( symbolName );
                if( result == ShouldThrow.Yes )
                    throw new SymbolLoadException( _name, symbolName );
            }

            return sym;
        }

        /**
         * Unloads the shared library from memory, invalidating all function pointers
         *  which were assigned a symbol by one of the load methods.
         */
        void unload() {
            if( isLoaded ) {
                UnloadSharedLib( _hlib );
                _hlib = null;
            }
        }

        @property {
            /// Returns the name of the shared library.
            string name() {
                return _name;
            }

            /// Returns true if the shared library is currently loaded, false otherwise.
            bool isLoaded() {
                return ( _hlib !is null );
            }

            /**
             * Sets the callback that will be called when an expected symbol is
             *  missing from the shared library.
             *
             * Params:
             *      callback    =   A delegate that returns a value of type
             *                      ShouldThrow and accepts
             *                      a string as the sole parameter.
             */
            void missingSymbolCallback( MissingSymbolCallbackDg callback ) {
                _onMissingSym = callback;
            }

            /**
             * Sets the callback that will be called when an expected symbol is
             *  missing from the shared library.
             *
             * Params:
             *      callback    =   A pointer to a function that returns a value of type
             *                      ShouldThrow and accepts a string as the sole parameter.
             */
            void missingSymbolCallback( MissingSymbolCallbackFunc callback ) {
                import std.functional : toDelegate;
                _onMissingSym = toDelegate( callback );
            }

            /**
             * Returns the currently active missing symbol callback.
             *
             * This exists primarily as a means to save the current callback before
             * setting a new one. It's useful, for example, if the new callback needs
             * to delegate to the old one.
             */
            MissingSymbolCallback missingSymbolCallback() {
                return _onMissingSym;
            }
        }
    }
}

private {
    alias void* SharedLibHandle;

    /*
     * Helper struct to facilitate throwing a single SharedLibException after failing
     *  to load a library using multiple names.
     */
    struct FailedSharedLib {
        string name;
        string reason;
    }
    
    version(Posix){
        import core.sys.posix.dlfcn;
    
        private {
            SharedLibHandle LoadSharedLib( string libName )    {
                if (libName == SELF_SYMBOL_LOOKUP)
                    return dlopen(null, RTLD_NOW);
                else
                    return dlopen( libName.toStringz(), RTLD_NOW );
            }
    
            void UnloadSharedLib( SharedLibHandle hlib ) {
                dlclose( hlib );
            }
    
            void* GetSymbol( SharedLibHandle hlib, string symbolName ) {
                return dlsym( hlib, symbolName.toStringz() );
            }
    
            string GetErrorStr() {
                auto err = dlerror();
                if( err is null )
                    return "Unknown Error";
    
                return to!string( err );
            }
        }
    } else version(Windows) {
        import core.sys.windows.windows : LoadLibraryA, FreeLibrary, GetProcAddress, GetLastError, HMODULE, DWORD, LPCTSTR;
    
        // TODO: remove
        extern(Windows)
            bool GetModuleHandleExA(
              DWORD   dwFlags,
              LPCTSTR lpModuleName,
              HMODULE *phModule
            );
    
        private {
            SharedLibHandle LoadSharedLib( string libName ) {
                if (libName == SELF_SYMBOL_LOOKUP) {
                    HMODULE handle;
                    GetModuleHandleExA(0, null, &handle);
                    return cast(SharedLibHandle)handle;
                } else
                    return LoadLibraryA( libName.toStringz() );
            }
    
            void UnloadSharedLib( SharedLibHandle hlib ) {
                FreeLibrary( hlib );
            }
    
            void* GetSymbol( SharedLibHandle hlib, string symbolName ) {
                return GetProcAddress( hlib, symbolName.toStringz() );
            }
    
            string GetErrorStr() {
                import std.windows.syserror;
                return sysErrorString( GetLastError() );
            }
        }
    }
}
