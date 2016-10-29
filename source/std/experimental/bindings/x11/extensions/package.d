module std.experimental.bindings.x11.extensions;
public import std.experimental.bindings.x11.extensions.randr;
public import std.experimental.bindings.x11.extensions.render;
public import std.experimental.bindings.x11.extensions.Xrandr;
public import std.experimental.bindings.x11.extensions.Xrender;
import std.experimental.bindings.autoloader;
import std.experimental.bindings.symbolloader : SELF_SYMBOL_LOOKUP;

///
__gshared static XrandrLoader = new SharedLibAutoLoader!([`std.experimental.bindings.x11.extensions.Xrandr`,])("Xrandr", SELF_SYMBOL_LOOKUP);
///
__gshared static XrenderLoader = new SharedLibAutoLoader!([`std.experimental.bindings.x11.extensions.Xrender`])("Xrender", SELF_SYMBOL_LOOKUP);
