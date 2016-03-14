﻿/*
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
module std.experimental.bindings.vulkan.wayland;
version(none):
import std.experimental.bindings.vulkan.core;
import std.experimental.bindings.wayland_client;

__gshared extern(C):

enum VK_KHR_wayland_surface = 1;

enum VK_KHR_WAYLAND_SURFACE_SPEC_VERSION = 5;
enum VK_KHR_WAYLAND_SURFACE_EXTENSION_NAME = "VK_KHR_wayland_surface";

alias VkWaylandSurfaceCreateFlagsKHR = VkFlags;

struct VkWaylandSurfaceCreateInfoKHR {
	VkStructureType sType;
	const(void*) pNext;
	VkWaylandSurfaceCreateFlagsKHR flags;
	wl_display* display;
	wl_surface* surface;
}

alias VkWaylandSurfaceCreateInfoKHR = VkWaylandSurfaceCreateInfoKHR;

alias PFN_vkCreateWaylandSurfaceKHR = VkResult function(VkInstance instance, const VkWaylandSurfaceCreateInfoKHR* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
alias PFN_vkGetPhysicalDeviceWaylandPresentationSupportKHR = VkBool32 function(VkPhysicalDevice physicalDevice, uint queueFamilyIndex, wl_display* display);

VkResult function(
	VkInstance                                  instance,
	const VkWaylandSurfaceCreateInfoKHR*            pCreateInfo,
	const VkAllocationCallbacks*                pAllocator,
	VkSurfaceKHR*                               pSurface) vkCreateWaylandSurfaceKHR;

VkBool32 function(
	VkPhysicalDevice                            physicalDevice,
	uint                                    queueFamilyIndex,
	wl_display*                           display) vkGetPhysicalDeviceWaylandPresentationSupportKHR;