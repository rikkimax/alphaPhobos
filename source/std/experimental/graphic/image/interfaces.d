/**
 * This module is a submodule of std.experimental.graphic.image
 *
 * Provides optional interfaces which declares an class based image as well as reusable concepts such as a swappable image implementation dependent upon a provided image implementation.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.graphic.image.interfaces;
import std.experimental.graphic.image.primitives;
import std.experimental.graphic.color;
import std.experimental.allocator : IAllocator, ISharedAllocator, theAllocator, processAllocator;
import std.traits : isPointer, PointerTarget, isUnsigned;

/**
 * Interface that defines the root methods required for a class/struct to be an image storage type.$(BR)
 * Similar in purpose as InputRange is to ranges.
 * 
 * Must have a constructor that takes in the width and height as arguments.
 * ------------
 *  this(size_t x, size_t y, IAllocator allocator = theAllocator())
 * ------------
 * Optionally may receive an allocator for allocating the pixel data from. The default is via the garbage collector.
 *
 * The width and height should not be 0. Instead for dummy test code use 1.$(BR)
 * Fields cannot be used in place of methods.
 */
interface ImageStorage(Color) if (isColor!Color) {
    @property {
        /// Gets the width of the image
		size_t width() @nogc nothrow @safe;
		/// Ditto
		size_t width() @nogc nothrow @safe shared;
        
        /// Gets the height of the image
		size_t height() @nogc nothrow @safe;
		/// Ditto
		size_t height() @nogc nothrow @safe shared;
    }    

    /**
     * Get a pixel given the position.
     *
     * Params:
     *      x   =   X position in image
     *      y   =   Y position in image
     *
     * Throws:
     *      If $(D x) or $(D y) coordinate is outside of the image boundries.
     *
     * Returns:
     *      The pixel color at point.
     */
	Color getPixel(size_t x, size_t y) @nogc @safe;
	/// Ditto
	Color getPixel(size_t x, size_t y) @nogc @safe shared;

    /**
     * Sets a pixel given the position.
     *
     * Params:
     *      x       =   X position in image
     *      y       =   Y position in image
     *      value   =   The color to assign to the pixel
     *
     * Throws:
     *      If $(D x) or $(D y) coordinate is outside of the image boundries.
     */
	void setPixel(size_t x, size_t y, Color value) @nogc @safe;
	/// Ditto
	void setPixel(size_t x, size_t y, Color value) @nogc @safe shared;

    /**
     * Get a pixel given the position.
     *
     * Params:
     *      x   =   X position in image
     *      y   =   Y position in image
     *
     * Throws:
     *      If $(D x) or $(D y) coordinate is outside of the image boundries.
     *
     * Returns:
     *      The pixel color at point.
     *
     * See_Also:
     *      getPixel
     */
	Color opIndex(size_t x, size_t y) @nogc @safe;
	/// Ditto
	Color opIndex(size_t x, size_t y) @nogc @safe shared;

    /**
     * Sets a pixel given the position.
     *
     * Params:
     *      x       =   X position in image
     *      y       =   Y position in image
     *      value   =   The color to assign to the pixel
     *
     * Throws:
     *      If $(D x) or $(D y) coordinate is outside of the image boundries.
     *
     * See_Also:
     *      setPixel
     */
	void opIndexAssign(Color value, size_t x, size_t y) @nogc @safe;
	/// Ditto
	void opIndexAssign(Color value, size_t x, size_t y) @nogc @safe shared;

    /**
     * Resizes the data store.
     *
     * Will not scale and $(U may) lose data in the process.
     *
     * Params:
     *      newWidth    =   The width the data store will become
     *      newHeight   =   The height the data store will become
     *
     * Returns:
     *      If the data store was successfully resized
     */
	bool resize(size_t newWidth, size_t newHeight) @safe;
	/// Ditto
	bool resize(size_t newWidth, size_t newHeight) @safe shared;
}

/**
 * Adds the ability to get a pixel based upon its offset.
 *
 * X and Y coordinate can be calculate using:
 * -----------------
 * ImageStorage!Color image = ...;
 * size_t offset = ...;
 * size_t x = offset % image.height;
 * size_t y = offset / image.height;
 * -----------------
 * 
 * Offset from X and Y coordinate can be calculated as:
 * -----------------
 * ImageStorage!Color image = ...;
 * size_t x, y = ...;
 * size_t offset = x + (y * image.width);
 * -----------------
 *
 * See_Also:
 *      ImageStorage
 */
interface ImageStorageOffset(Color) {
    @property {
        /// The number of pixels in total
		size_t count() @nogc nothrow @safe;
		/// Ditto
		size_t count() @nogc nothrow @safe shared;
    }

    /**
     * Get a pixel given the position.
     *
     * Params:
     *      offset  =   The offset of the pixel
     *
     * Throws:
     *      If $(D offset) coordinate is outside of the image boundary.
     *
     * Returns:
     *      The pixel color at point.
     */
	Color getPixelAtOffset(size_t offset) @nogc @safe;
	/// Ditto
	Color getPixelAtOffset(size_t offset) @nogc @safe shared;

    /**
     * Set a pixel given the position.
     *
     * Params:
     *      offset  =   The offset of the pixel
     *      value   =   The color to assign to the pixel
     *
     * Throws:
     *      If $(D offset) coordinate is outside of the image boundary.
     */
	void setPixelAtOffset(size_t offset, Color value) @nogc @safe;
	/// Ditto
	void setPixelAtOffset(size_t offset, Color value) @nogc @safe shared;

    /**
     * Get a pixel given the position.
     *
     * Params:
     *      offset  =   The offset of the pixel
     *
     * Throws:
     *      If $(D offset) coordinate is outside of the image boundary.
     *
     * Returns:
     *      The pixel color at point.
     *
     * See_Also:
     *      getPixelAtOffset
     */
	Color opIndex(size_t offset) @nogc @safe;
	/// Ditto
	Color opIndex(size_t offset) @nogc @safe shared;

    /**
     * Set a pixel given the position.
     *
     * Params:
     *      offset  =   The offset of the pixel
     *      value   =   The color to assign to the pixel
     *
     * Throws:
     *      If $(D offset) coordinate is outside of the image boundary.
     *
     * See_Also:
     *      setPixelAtOffset
     */
	void opIndexAssign(Color value, size_t offset) @nogc @safe;
	/// Ditto
	void opIndexAssign(Color value, size_t offset) @nogc @safe shared;
}

/**
 * Wraps an image implementation up so that the exact implementation doesn't matter.
 * As long as the color type is known it can be passed around freely.
 * It does $(I not) allocate to perform its functions and can be safely used on the stack.
 */
struct SwappableImage(Color) if (isColor!Color) {
    this() @disable;
    this(size_t width, size_t height, IAllocator alloc=theAllocator()) @disable;

    ~this() @safe {
        if (destroyerDel !is null) {
            destroyerDel();
        }
    }

    /**
     * Constructs a swappable image using a specific image storage type as its value.
     *
     * If the image storage type does not support ImageStorageOffset it will add support.$(BR)
     * If the color type specified is not the same type for the image storage instance then it'll auto convert. It is the responsiblity of the user to check for precision gain/lost.$(BR)
     * Supports deallocating of the image provided, using the allocator, when the destructor is called. If the allocator is not provided it will not deallocate it.
     *
     * Params:
     *      fromImage   =   The instance to take delegates from
     *      allocator   =   Allocator to deallocate the image if provided when destructor is called
     * 
     * See_Also:
     *      ImageStorage, ImageStorageOffset
     */
	this(T)(T from, IAllocator allocator = null) @nogc @trusted if (((!isPointer!T && isImage!T) || (isPointer!T && isImage!(PointerTarget!T))) &&
		isUnsigned!(ImageIndexType!T) && (ImageIndexType!T).sizeof <= (void*).sizeof)
    in {
        static if (is(T == class))
            assert(from !is null);
    } body {
        static if (isPointer!T && isImage!(PointerTarget!T))
            alias ImageRealType = PointerTarget!T;
        else
            alias ImageRealType = T;

        static if (!isPointer!T && is(ImageRealType == struct))
            origin_ = cast(void*)&from;
        else
            origin_ = cast(void*)from;

        this.allocator = allocator;
        if (allocator !is null) {
            static if (!isPointer!T && is(T == struct))
                destroyerDel = &destroyerHandler!(ImageRealType*);
            else
                destroyerDel = &destroyerHandler!T;
        }

        widthDel = &from.width;
        heightDel = &from.height;
        resizeDel = cast(bool delegate(size_t, size_t) @safe)&from.resize;

        pixelAt_ = cast(void delegate())&from.getPixel;
        pixelAtDel = &pixelAtCompatFunc!(ImageColor!ImageRealType);

        pixelStoreAt_ = cast(void delegate())&from.setPixel;
        pixelStoreAtDel = &pixelStoreAtCompatFunc!(ImageColor!ImageRealType);

        static if (supportsImageOffset!ImageRealType) {
            countDel = &from.count;

            pixelAtOffset_ = cast(void delegate())&from.getPixelAtOffset;
            pixelAtOffsetDel = &pixelAtOffsetCompatFunc!(ImageColor!ImageRealType);
            
            pixelStoreAtOffset_ = cast(void delegate())&from.setPixelAtOffset;
            pixelStoreAtOffsetDel = &pixelStoreAtOffsetCompatFunc!(ImageColor!ImageRealType);
        } else {
            countDel = &countNotSupported;
            pixelAtOffsetDel = &pixelAtOffsetNotSupported;
            pixelStoreAtOffsetDel = &pixelStoreAtOffsetNotSupported;
        }
    }

    @property {
        // Gets the width of the image
        size_t width() @nogc nothrow @safe { return widthDel(); }

        /// Gets the height of the image
        size_t height() @nogc nothrow @safe { return heightDel(); }

        /// Gets the number of pixels the image contains
        size_t count() @nogc nothrow @safe { return countDel(); }

        /**
         * A pointer to the original image storage type.
         * Use at your own risk.
         */
        void* original() @nogc nothrow @safe { return origin_; }
    }

    /**
     * Get a pixel given the position.
     *
     * Params:
     *      x   =   X position in image
     *      y   =   Y position in image
     *
     * Throws:
     *      If $(D x) or $(D y) coordinate is outside of the image boundries.
     *
     * Returns:
     *      The pixel color at point.
     */
    Color getPixel(size_t x, size_t y) @nogc @safe { return pixelAtDel(x, y); }

    /**
     * Sets a pixel given the position.
     *
     * Params:
     *      x       =   X position in image
     *      y       =   Y position in image
     *      value   =   The color to assign to the pixel
     *
     * Throws:
     *      If $(D x) or $(D y) coordinate is outside of the image boundries.
     */
    void setPixel(size_t x, size_t y, Color value) @nogc @safe { pixelStoreAtDel(x, y, value); }

    /**
     * Get a pixel given the position.
     *
     * Params:
     *      offset  =   The offset of the pixel
     *
     * Throws:
     *      If $(D offset) coordinate is outside of the image boundary.
     *
     * Returns:
     *      The pixel color at point.
     */
    Color getPixelAtOffset(size_t offset) @nogc @safe { return pixelAtOffsetDel(offset); };

    /**
     * Set a pixel given the position.
     *
     * Params:
     *      offset  =   The offset of the pixel
     *      value   =   The color to assign to the pixel
     *
     * Throws:
     *      If $(D offset) coordinate is outside of the image boundary.
     */
    void setPixelAtOffset(size_t offset, Color value) @nogc @safe { pixelStoreAtOffsetDel(offset, value); }

    /**
     * Get a pixel given the position.
     *
     * Params:
     *      x   =   X position in image
     *      y   =   Y position in image
     *
     * Throws:
     *      If $(D x) or $(D y) coordinate is outside of the image boundries.
     *
     * Returns:
     *      The pixel color at point.
     *
     * See_Also:
     *      getPixel
     */
    Color opIndex(size_t x, size_t y) @nogc @safe { return getPixel(x, y); }

    /**
     * Sets a pixel given the position.
     *
     * Params:
     *      x       =   X position in image
     *      y       =   Y position in image
     *      value   =   The color to assign to the pixel
     *
     * Throws:
     *      If $(D x) or $(D y) coordinate is outside of the image boundries.
     *
     * See_Also:
     *      setPixel
     */
    void opIndexAssign(Color value, size_t x, size_t y) @nogc @safe { setPixel(x, y, value); }

    /**
     * Get a pixel given the position.
     *
     * Params:
     *      offset  =   The offset of the pixel
     *
     * Throws:
     *      If $(D offset) coordinate is outside of the image boundary.
     *
     * Returns:
     *      The pixel color at point.
     *
     * See_Also:
     *      getPixelAtOffset
     */
    Color opIndex(size_t offset) @nogc @safe { return getPixelAtOffset(offset); }

    /**
     * Set a pixel given the position.
     *
     * Params:
     *      offset  =   The offset of the pixel
     *      value   =   The color to assign to the pixel
     *
     * Throws:
     *      If $(D offset) coordinate is outside of the image boundary.
     *
     * See_Also:
     *      setPixelAtOffset
     */
    void opIndexAssign(Color value, size_t offset) @nogc @safe { setPixelAtOffset(offset, value); }

    /**
     * Resizes the data store.
     *
     * Will not scale and $(U may) lose data in the process.$(BR)
     * If the resize operation puts the image into a potentially errornous state, it should throw an exception.
     *
     * Params:
     *      newWidth    =   The width the data store will become
     *      newHeight   =   The height the data store will become
     *
     * Returns:
     *      If the data store was successfully resized
     */
    bool resize(size_t newWidth, size_t newHeight) @safe {
        return resizeDel(newWidth, newHeight);
    }

    private {
        size_t delegate() @nogc @safe nothrow widthDel;
        size_t delegate() @nogc @safe nothrow heightDel;
        size_t delegate() @nogc @safe nothrow countDel;

        Color delegate(size_t x, size_t y) @nogc @safe pixelAtDel;
        void delegate(size_t x, size_t y, Color value) @nogc @safe pixelStoreAtDel;
        Color delegate(size_t offset) @nogc @safe pixelAtOffsetDel;
        void delegate(size_t offset, Color value) @nogc @safe pixelStoreAtOffsetDel;

        bool delegate(size_t, size_t) @safe resizeDel;

        void* origin_;

        IAllocator allocator;
        void delegate() @trusted destroyerDel;

        void delegate() pixelAt_;
        void delegate() pixelStoreAt_;
        void delegate() pixelAtOffset_;
        void delegate() pixelStoreAtOffset_;

        void destroyerHandler(T)() @trusted {
            import std.experimental.allocator : dispose;
            allocator.dispose(cast(T)origin_);
        }

        Color pixelAtCompatFunc(FROM)(size_t x, size_t y) @nogc @trusted {
            auto del = cast(FROM delegate(size_t x, size_t y) @nogc @safe) pixelAt_;
            auto got = del(x, y);           

            static if (is(FROM == Color)) {
                return got;
            } else {
                return convertColor!Color(got);
            }
        }

        void pixelStoreAtCompatFunc(FROM)(size_t x, size_t y, Color value) @nogc @trusted {
            auto del = cast(void delegate(size_t x, size_t y, FROM value) @nogc @safe) pixelStoreAt_;

            static if (is(FROM == Color)) {
                del(x, y, value);
            } else {
                del(x, y, convertColor!FROM(value));
            }
        }

        Color pixelAtOffsetCompatFunc(FROM)(size_t offset) @nogc @trusted {
            auto del = cast(FROM delegate(size_t offset) @nogc @safe) pixelAtOffset_;
            
            static if (is(FROM == Color)) {
                return del(offset);
            } else {
                return convertColor!Color(del(offset));
            }
        }

        void pixelStoreAtOffsetCompatFunc(FROM)(size_t offset, Color value) @nogc @trusted {
            auto del = cast(void delegate(size_t offset, FROM value) @nogc @safe) pixelStoreAtOffset_;

            static if (is(FROM == Color)) {
                del(offset, value);
            } else {
                del(offset, convertColor!FROM(value));
            }
        }

        size_t countNotSupported() @nogc nothrow @safe {
            return width() * height();
        }

        Color pixelAtOffsetNotSupported(size_t offset) @nogc @trusted {
            return getPixel(offset % height(), offset / (height() + 1));
        }

        void pixelStoreAtOffsetNotSupported(size_t offset, Color value) @nogc @trusted {
            setPixel(offset % height(), offset / (height() + 1), value);
        }
    }
}

version(unittest) package {
    class MyTestImage(Color) : ImageStorage!Color {
        private {
            const size_t width_, height_;
            IAllocator allocator;
            Color[][] data;
        }

        this(size_t width, size_t height, IAllocator allocator = theAllocator()) {
            import std.experimental.allocator : makeArray;
            this.allocator = allocator;

            width_ = width;
            height_ = height;
            
            data = allocator.makeArray!(Color[])(width);
            
            foreach(_; 0 .. width) {
                data[_] = allocator.makeArray!Color(height);
            }
        }

        @property {
            size_t width() @nogc nothrow @safe{ return width_; }
            size_t height() @nogc nothrow @safe { return height_; }
        }

        Color getPixel(size_t x, size_t y) @nogc @safe { return data[x][y]; }
        void setPixel(size_t x, size_t y, Color value) @nogc  @safe { data[x][y] = value; }
        Color opIndex(size_t x, size_t y) @nogc  @safe{ return getPixel(x, y); }
        void opIndexAssign(Color value, size_t x, size_t y) @nogc @safe { setPixel(x, y, value); }

        bool resize(size_t, size_t) @nogc @safe { return false; }
    }
}

unittest {
    import std.experimental.allocator : make, theAllocator;

    SwappableImage!RGB8 image = SwappableImage!(RGB8)(theAllocator.make!(MyTestImage!RGB8)(8, 3));
    RGB8 value = image[0, 0];
}

unittest {
    import std.experimental.allocator : make, theAllocator;

    SwappableImage!RGBA8 image = SwappableImage!(RGBA8)(theAllocator.make!(MyTestImage!RGB8)(8, 3));
    RGBA8 value = image[0, 0];
}

unittest {
    import std.experimental.allocator : make, theAllocator;

    SwappableImage!RGB8 image = SwappableImage!(RGB8)(theAllocator.make!(MyTestImage!RGB8)(8, 3));
    size_t count = image.count();
    assert(count == 24);
}

/**
 * Constructs an input range over an image
 * For every pixel get x + y and the color value
 *
 * TODO: Scan line version of this?
 *
 * Params:
 *      from    =    The image to create a range upon
 * 
 * Returns:
 *      An input range to get every pixel along with its X and Y coordinates.
 */
auto rangeOf(Color)(SwappableImage!Color* from) @nogc nothrow @safe {
    return RangeOf!Color(from, 0, 0);
}

/**
 * Constructs an input range over an image
 * For every pixel get x + y and the color value
 *
 * Will $(B allocate) a new SwappableImage to wrap around the image given on the heap.
 * The returned input range will auto deallocate the SwappableImage that was allocated when it becomes empty.
 *
 * TODO: Scan line version of this?
 *
 * Params:
 *      from        =   The image to create a range upon
 *      allocator   =   The allocator to allocate the SwappableImage instance on the heap. Will auto free it when destructed.
 *
 * Returns:
 *      An input range to get every pixel along with its X and Y coordinates.
 */
auto rangeOf(Image)(Image from, IAllocator allocator = theAllocator()) @trusted if (isImage!Image) {
    import std.experimental.allocator : make;
    alias Color = ImageColor!Image;

    SwappableImage!Color* inst = allocator.make!(SwappableImage!Color)(from);
    return RangeOf!Color(inst, 0, 0, allocator);
}

private {
    struct RangeOf(Color) {
        private {
            SwappableImage!Color* input;
            size_t offsetX;
            size_t offsetY;
            IAllocator allocator;
        }

        private this(SwappableImage!Color* input, size_t offsetX, size_t offsetY, IAllocator allocator = null) @nogc nothrow @trusted {
            this.input = input;
            this.offsetX = offsetX;
            this.offsetY = offsetY;
            this.allocator = allocator;
        }
        
        @property {
            auto front() @nogc @safe {
                return PixelPoint!Color(input.getPixel(offsetX, offsetY), offsetX, offsetY, input.width, input.height);
            }

            bool empty() @trusted {
                bool ret = offsetX == 0 && offsetY == input.height();
                
                if (ret) {
                    import std.experimental.allocator : dispose;
                    // deallocates the input, if the allocator is provided

                    if (this.allocator !is null && input !is null) {
                        allocator.dispose(input);
                        input = null;
                    }
                }

                return ret;
            }
        }

        void popFront() @nogc nothrow @safe {
            if (offsetX == input.width() - 1) {
                offsetY++;
                offsetX = 0;
            } else {
                offsetX++;
            }
        }
    }
}

unittest {
    size_t count;

    foreach(pixel; new MyTestImage!RGB8(2, 2).rangeOf) {
        count++;        
    }

    assert(count == 4);

    auto aRange = new MyTestImage!RGB8(2, 2).rangeOf;
    auto pixel = aRange.front;
    
    assert(pixel.x == 0);
    assert(pixel.y == 0);

    aRange.popFront;
}

/**
 * A single pixel inside an image.
 * 
 * To be returned from input ranges.
 */
struct PixelPoint(Color) if (isColor!Color) {
    ///
    Color value;
    alias value this;

    ///
    size_t x, y;

    ///
    size_t imageWidth, imageHeight;
}

/// Wraps a struct image storage type into a class
final class ImageObject(Impl) : ImageStorage!(ImageColor!Impl) if (is(Impl == struct) && isUnsigned!(ImageIndexType!Impl) && (ImageIndexType!Impl).sizeof <= (void*).sizeof) {
	import std.traits : Unqual;
    alias Color = ImageColor!Impl;

    // If I could make this private, I would...
    this()(Impl* instance) @trusted {
        swpInst = instance;
    }

	static if (is(Impl == shared) && __traits(compiles, {new shared Impl(0, 0, cast(shared(ISharedAllocator))null);})) {
		// Ditto
		this(size_t width, size_t height, shared(ISharedAllocator) allocator = processAllocator()) @trusted shared {
			import std.experimental.allocator : make;
			swpInst = cast(shared)allocator.make!(Unqual!Impl)(width, height, allocator);
			_salloc = allocator;
		}
	} else static if (!is(Impl == shared) && __traits(compiles, {new Impl(0, 0, cast(IAllocator)null);})) {
		// Ditto
		this(size_t width, size_t height, IAllocator allocator = theAllocator()) @trusted {
			import std.experimental.allocator : make;
			swpInst = allocator.make!Impl(width, height, allocator);
			_alloc = allocator;
		}
	}

    @property {
		size_t width() @nogc nothrow @safe {return swpInst.width;}
		size_t width() @nogc nothrow @trusted shared {return (cast(Unqual!Impl*)swpInst).width;}
		size_t height() @nogc nothrow @safe {return swpInst.height;}
		size_t height() @nogc nothrow @trusted shared {return (cast(Unqual!Impl*)swpInst).height;}
    }    
    
	Color getPixel(size_t x, size_t y) @nogc @safe {return swpInst.getPixel(x, y);}
	Color getPixel(size_t x, size_t y) @nogc @trusted shared {return (cast(Unqual!Impl*)swpInst).getPixel(x, y);}
	void setPixel(size_t x, size_t y, Color value) @nogc @safe {swpInst.setPixel(x, y, value);}
	void setPixel(size_t x, size_t y, Color value) @nogc @trusted shared {(cast(Unqual!Impl*)swpInst).setPixel(x, y, value);}
	Color opIndex(size_t x, size_t y) @nogc @safe {return swpInst.opIndex(x, y);}
	Color opIndex(size_t x, size_t y) @nogc @trusted shared {return (cast(Unqual!Impl*)swpInst).opIndex(x, y);}
	void opIndexAssign(Color value, size_t x, size_t y) @nogc @safe {swpInst.opIndexAssign(value, x, y);}
	void opIndexAssign(Color value, size_t x, size_t y) @nogc @trusted shared {(cast(Unqual!Impl*)swpInst).opIndexAssign(value, x, y);}
	bool resize(size_t newWidth, size_t newHeight) @safe {return swpInst.resize(newWidth, newHeight);}
	bool resize(size_t newWidth, size_t newHeight) @trusted shared {return (cast(Unqual!Impl*)swpInst).resize(newWidth, newHeight);}

    private {
		import std.traits : Unqual;

		IAllocator _alloc;
		shared(ISharedAllocator) _salloc;
        Impl* swpInst;

        ~this() {
            import std.experimental.allocator : dispose;
			static if (is(Impl == shared)) {
				if (_salloc !is null)
					_salloc.dispose(cast(Unqual!Impl*)swpInst);
			} else {
            	if (_alloc !is null)
             	   _alloc.dispose(swpInst);
			}
        }
    }
}

/**
 * Constructs an object around an image storage type.
 *
 * Params: 
 *      width       =   The width to assign
 *      height      =   The height to assign
 *      allocator   =   Allocator to use
 *
 * Returns:
 *      An ImageObject wrapper around the implementation specified.
 *
 * See_Also:
 *      ImageObject
 */
auto imageObject(Impl)(size_t width, size_t height, IAllocator allocator = theAllocator) @trusted
if (is(Impl == struct) && isUnsigned!(ImageIndexType!Impl) && (ImageIndexType!Impl).sizeof <= (void*).sizeof && !is(Impl==shared)) {
    import std.experimental.allocator : make;
    return allocator.make!(ImageObject!Impl)(width, height, allocator);
}

/// Ditto
auto imageObject(Impl)(size_t width, size_t height, shared(ISharedAllocator) allocator = processAllocator) @trusted
if (is(Impl == struct) && isUnsigned!(ImageIndexType!Impl) && (ImageIndexType!Impl).sizeof <= (void*).sizeof && is(Impl==shared)) {
	import std.experimental.allocator : make;
	return allocator.make!(shared(ImageObject!Impl))(width, height, allocator);
}

/**
 * Constructs an object around an image storage type.
 *
 * Params: 
 *      instance    =   Instance to wrap
 *      allocator   =   Allocator to use
 *
 * Returns:
 *      An ImageObject wrapper around the implementation specified.
 *
 * See_Also:
 *      ImageObject
 */
auto imageObject(Impl)(Impl* instance, IAllocator allocator = theAllocator) @trusted
if (is(Impl == struct) && isUnsigned!(ImageIndexType!Impl) && (ImageIndexType!Impl).sizeof <= (void*).sizeof && !is(Impl==shared)) {
    import std.experimental.allocator : make;
    return allocator.make!(ImageObject!Impl)(instance);
}

/// Ditto
auto imageObject(Impl)(Impl* instance, shared(ISharedAllocator) allocator = processAllocator) @trusted
if (is(Impl == struct) && isUnsigned!(ImageIndexType!Impl) && (ImageIndexType!Impl).sizeof <= (void*).sizeof && is(Impl==shared)) {
	import std.experimental.allocator : make;
	return allocator.make!(shared(ImageObject!Impl))(instance);
}

/**
 * Constructs an object based upon an existing image.
 *
 * Params: 
 *      from        =   Instance to wrap
 *      allocator   =   Allocator to use
 *
 * Returns:
 *      An ImageObject wrapper around the implementation specified.
 *
 * See_Also:
 *      ImageObject
 */
auto imageObjectFrom(Impl, Image)(Image from, IAllocator allocator = theAllocator) @trusted
if (is(Impl == struct) && isImage!Impl && isImage!Image && isUnsigned!(ImageIndexType!Impl) && (ImageIndexType!Impl).sizeof <= (void*).sizeof && !is(Impl==shared)) {
    import std.experimental.graphic.image.primitives : copyTo;
    import std.experimental.allocator : make;

    return from.copyTo(imageObject!Impl(from.width, from.height, allocator));
}

/// Ditto
auto imageObjectFrom(Impl, Image)(Image from, shared(ISharedAllocator) allocator = processAllocator) @trusted
if (is(Impl == struct) && isImage!Impl && isImage!Image && isUnsigned!(ImageIndexType!Impl) && (ImageIndexType!Impl).sizeof <= (void*).sizeof && is(Impl==shared)) {
	import std.experimental.graphic.image.primitives : copyTo;
	import std.experimental.allocator : make;
	
	return from.copyTo(imageObject!Impl(from.width, from.height, allocator));
}
