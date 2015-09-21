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

# Phobos TODO list

## No dependencies
- ``std.string : indexOf`` @nogc varient
- Complete overhaul of std.math, into a package with linear algerbra support (gfm:math)

## Allocators dependency
- ``std.typecons : RefCounted`` IAllocator support to deallocate/allocate
- Some sort of list e.g. std.containers.array with IAllocator support
- Some form of AA with allocator usage
- std.zlib memory allocation fix
