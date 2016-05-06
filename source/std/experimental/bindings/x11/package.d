module std.experimental.bindings.x11;
public import std.experimental.bindings.x11.X;
public import std.experimental.bindings.x11.Xlib;
public import std.experimental.bindings.x11.Xmd;
public import std.experimental.bindings.x11.Xproto;
public import std.experimental.bindings.x11.Xprotostr;
public import std.experimental.bindings.x11.Xresource;
public import std.experimental.bindings.x11.Xutil;
public import std.experimental.bindings.x11.keysym;
public import std.experimental.bindings.x11.keysymdef;

import std.experimental.bindings.autoloader;
import std.experimental.bindings.symbolloader : SELF_SYMBOL_LOOKUP;

///
__gshared static X11Loader = new SharedLibAutoLoader!([`std.experimental.bindings.x11.X`])("X11", SELF_SYMBOL_LOOKUP);
