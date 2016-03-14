module std.experimental.bindings.vulkan;
public import std.experimental.bindings.vulkan.core;

public import std.experimental.bindings.vulkan.android;
public import std.experimental.bindings.vulkan.mir;
public import std.experimental.bindings.vulkan.wayland;
public import std.experimental.bindings.vulkan.windows;
public import std.experimental.bindings.vulkan.xcb;
public import std.experimental.bindings.vulkan.xlib;

import std.experimental.bindings.autoloader;
import std.experimental.bindings.symbolloader : SELF_SYMBOL_LOOKUP;

/*
 * System libs (if only it makes sense)
 * Then non specific system lib0
 */

version(Android) {
	///
	__gshared static VulkanAndroidLoader = new SharedLibAutoLoader!([`std.experimental.bindings.vulkan.android`, `std.experimental.bindings.vulkan.core`])("vulkan.so", SELF_SYMBOL_LOOKUP);
} else version(Windows) {
	///
	__gshared static VulkanWindowsLoader = new SharedLibAutoLoader!([`std.experimental.bindings.vulkan.windows`, `std.experimental.bindings.vulkan.core`])("vulkan.dll", SELF_SYMBOL_LOOKUP);
} else {
	///
	__gshared static VulkanMirLoader = new SharedLibAutoLoader!([`std.experimental.bindings.vulkan.mir`, `std.experimental.bindings.vulkan.core`])("vulkan.so", SELF_SYMBOL_LOOKUP);
	///
	__gshared static VulkanWaylandLoader = new SharedLibAutoLoader!([`std.experimental.bindings.vulkan.wayland`, `std.experimental.bindings.vulkan.core`])("vulkan.so", SELF_SYMBOL_LOOKUP);
	///
	__gshared static VulkanXcbLoader = new SharedLibAutoLoader!([`std.experimental.bindings.vulkan.xcb`, `std.experimental.bindings.vulkan.core`])("vulkan.so", SELF_SYMBOL_LOOKUP);
	///
	__gshared static VulkanXlibLoader = new SharedLibAutoLoader!([`std.experimental.bindings.vulkan.xlib`, `std.experimental.bindings.vulkan.core`])("vulkan.so", SELF_SYMBOL_LOOKUP);
}
