module std.experimental.bindings.x11;
public import std.experimental.bindings.x11.X;
import std.experimental.bindings.magic;

///
__gshared static X11Loader = new MagicalSharedLibLoader!([`std.experimental.bindings.x11.X`])("X11");
