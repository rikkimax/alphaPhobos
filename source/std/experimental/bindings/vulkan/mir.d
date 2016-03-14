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
module std.experimental.bindings.vulkan.mir;
version(none):
import std.experimental.bindings.vulkan.core;
import std.experimental.bindings.mir_toolkit.client_types;

__gshared extern(C):

enum VK_KHR_mir_surface = 1;

enum VK_KHR_MIR_SURFACE_SPEC_VERSION = 4;
enum VK_KHR_MIR_SURFACE_EXTENSION_NAME = "VK_KHR_mir_surface";

alias VkMirSurfaceCreateFlagsKHR = VkFlags;

struct VkMirSurfaceCreateInfoKHR {
	VkStructureType sType;
	const(void*) pNext;
	VkMirSurfaceCreateFlagsKHR flags;
	MirConnection* connection;
	MirSurface window;
}

alias VkMirSurfaceCreateInfoKHR = VkMirSurfaceCreateInfoKHR;

alias PFN_vkCreateMirSurfaceKHR = VkResult function(VkInstance instance, const VkMirSurfaceCreateInfoKHR* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
alias PFN_vkGetPhysicalDeviceMirPresentationSupportKHR = VkBool32 function(VkPhysicalDevice physicalDevice, uint queueFamilyIndex, MirConnection* connection);

VkResult function(
	VkInstance                                  instance,
	const VkMirSurfaceCreateInfoKHR*            pCreateInfo,
	const VkAllocationCallbacks*                pAllocator,
	VkSurfaceKHR*                               pSurface) vkCreateMirSurfaceKHR;

VkBool32 function(
	VkPhysicalDevice                            physicalDevice,
	uint                                    queueFamilyIndex,
	MirConnection*                           connection) vkGetPhysicalDeviceMirPresentationSupportKHR;