# alphaPhobos
Assume License: Boost

Just some of my to be Phobos code. Includes dependencies on e.g. not included with latest compiler version.

May require serious work before usable.

## TODO
- VFS testing
- Where does std.experimental.vfs.internal glob functions go?
- PR std.experimental.uri to std.uri

- Image abituary rotation
- Image tests
	- PNG
	- Rotation
- Image primitives unittests

- Windowing contexts

- X11 bindings
- OpenGL bindings

# Phobos TODO list

## No dependencies
- ``std.string : indexOf`` @nogc varient
- Complete overhaul of std.math, into a package with linear algerbra support (gfm:math)

## Allocators dependency
- ``std.typecons : RefCounted`` IAllocator support to deallocate/allocate
- Some sort of list e.g. std.containers.array with IAllocator support
- Some form of AA with allocator usage
- std.zlib memory allocation fix

# Feedback

Stages:
1. Initial idea + design with some example implementation and test code
2. Implementation types and design of them
3. Final scope discovery pre pull request/queue
4. Pull request and review queue

# Image library
Current completed stage 1.

Requirement for stage 2 is PNG implementation to have a comprehensive test suite.

Requirement for stage 3 is BMP implementation as well as rotation manipulation feature.

Requirement for stage 4, all dependencies are meet and in Phobos already.

# Windowing library
Currently has not been through feedback yet.

Requirement for stage 1 is image library at stage 2 and implementation fully implemented for Windows.

Requirement for stage 2 is X11 and OpenGL context.

Requirement for stage 3 is OSX + Wayland, DirectX support and image library at stage 3.

Requirement for stage 4, all dependencies are meet and in Phobos already. Image library may be concurrent with this during review queue process.