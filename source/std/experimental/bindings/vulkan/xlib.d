/*
** Copyright (c) 2015-2016 The Khronos Group Inc.
**
** Permission is hereby granted, free of charge, to any person obtaining a
** copy of this software and/or associated documentation files (the
** "Materials"), to deal in the Materials without restriction, including
** without limitation the rights to use, copy, modify, merge, publish,
** distribute, sublicense, and/or sell copies of the Materials, and to
** permit persons to whom the Materials are furnished to do so, subject to
** the following conditions:
**
** The above copyright notice and this permission notice shall be included
** in all copies or substantial portions of the Materials.
**
** THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
** EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
** MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
** CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
** TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
** MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
*
* Authors:
* 	$(WEB https://www.khronos.org/, Khronos), $(WEB https://github.com/Rikarin, Satoshi)
*/
module std.experimental.bindings.vulkan.xlib;
version(none):
import std.experimental.bindings.vulkan.core;
import std.experimental.bindings.x11;

__gshared extern(C):

enum VK_KHR_xlib_surface = 1;

enum VK_KHR_XLIB_SURFACE_SPEC_VERSION = 6;
enum VK_KHR_XLIB_SURFACE_EXTENSION_NAME = "VK_KHR_xlib_surface";

alias VkXlibSurfaceCreateFlagsKHR = VkFlags;

struct VkXlibSurfaceCreateInfoKHR {
	VkStructureType sType;
	const(void*) pNext;
	VkXlibSurfaceCreateFlagsKHR flags;
	Display* dpy;
	Window window;
}

alias PFN_vkCreateXlibSurfaceKHR = VkResult function(VkInstance instance, const VkXlibSurfaceCreateInfoKHR* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
alias PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR = VkBool32 function(VkPhysicalDevice physicalDevice, uint queueFamilyIndex, Display* dpy, VisualID visualID);

VkResult function(
	VkInstance                                  instance,
	const VkXlibSurfaceCreateInfoKHR*           pCreateInfo,
	const VkAllocationCallbacks*                pAllocator,
	VkSurfaceKHR*                               pSurface) vkCreateXlibSurfaceKHR;

VkBool32 function(
	VkPhysicalDevice                            physicalDevice,
	uint                                    queueFamilyIndex,
	Display*                                    dpy,
	VisualID                                    visualID) vkGetPhysicalDeviceXlibPresentationSupportKHR;