module std.experimental.bindings.x11;
public import std.experimental.bindings.x11.keysym;
public import std.experimental.bindings.x11.keysymdef;
public import std.experimental.bindings.x11.X;
// most likely not needed and does redefine things == error
//public import std.experimental.bindings.x11.Xdefs;
public import std.experimental.bindings.x11.Xlib;
public import std.experimental.bindings.x11.Xmd;
public import std.experimental.bindings.x11.Xproto;
public import std.experimental.bindings.x11.Xprotostr;
public import std.experimental.bindings.x11.Xresource;
public import std.experimental.bindings.x11.Xutil;

public import std.experimental.bindings.x11.extensions;

import std.experimental.bindings.autoloader;
import std.experimental.bindings.symbolloader : SELF_SYMBOL_LOOKUP;

///
__gshared static X11Loader = new SharedLibAutoLoader!([
	`std.experimental.bindings.x11.Xlib`,
	`std.experimental.bindings.x11.Xresource`,
	`std.experimental.bindings.x11.Xutil`
])("X11", SELF_SYMBOL_LOOKUP);
