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
- Fix PNG/load export
	Must support < 8 bits per sample in decompression/compression

# Phobos TODO list

## No dependencies
- ``std.string : indexOf`` @nogc varient
- Linear algerbra abstraction e.g. vec2 for Point struct

## Allocators dependency
- ``std.typecons : RefCounted`` IAllocator support to deallocate/allocate
- Some sort of list e.g. std.containers.array with IAllocator support
- Some form of AA with allocator usage
