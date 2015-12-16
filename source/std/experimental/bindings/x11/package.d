module std.experimental.bindings.x11;
public import std.experimental.bindings.x11.X;
import std.experimental.bindings.autoloader;

///
__gshared static X11Loader = new SharedLibAutoLoader!([`std.experimental.bindings.x11.X`])("X11");
