/**
 * A flat image storage type.
 * Useful for your underlying contextual needs.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.graphic.image.storage.flat;
import std.experimental.graphic.color : isColor;
import std.experimental.allocator : IAllocator, theAllocator;

/**
 * Represents an image using a flat array.
 *
 * Because the usage of multiplication is required to index and assign,
 * it is not recommend to be used outside of drawing contexts.
 * Where this is the least expensive option for a buffer to draw upon.
 * 
 * Will automatically deallocate its memory when it goes out of scope.
 * Should not be copied or moved around.
 * 
 * See_Also:
 *      ImageStorage
 */
struct FlatImageStorage(Color) if (isColor!Color) {
    private {
        size_t width_, height_;
        IAllocator allocator;
        Color[] data;
    }
    
    ///
    this(size_t width, size_t height, IAllocator allocator = theAllocator()) @trusted {
        import std.experimental.allocator : makeArray;
        this.allocator = allocator;

        width_ = width;
        height_ = height;
        
        data = allocator.makeArray!(Color)(width * height);
    }

	~this() @trusted {
		import std.experimental.allocator : dispose;

		if (!__ctfe && data !is null)
			allocator.dispose(data);
	}
    
    @property {
        ///
        size_t width() @nogc nothrow @safe { return width_; }

        ///
        size_t height() @nogc nothrow @safe { return height_; }
    }

    ///
    Color getPixel(size_t x, size_t y) @nogc @safe { return data[(y * width) + x]; }

    ///
    void setPixel(size_t x, size_t y, Color value) @nogc @safe { data[(y * width) + x] = value; }

    ///
    Color opIndex(size_t x, size_t y) @nogc  @safe{ return getPixel(x, y); }

    ///
    void opIndexAssign(Color value, size_t x, size_t y) @nogc @safe { setPixel(x, y, value); }
    
    ///
    bool resize(size_t newWidth, size_t newHeight) @trusted {
        import std.experimental.allocator : dispose, makeArray;
        import std.algorithm : min;

        scope(failure)
            return false;

        Color[] newData;

        if (newWidth == 0 || newHeight == 0) {
        } else {
            newData = allocator.makeArray!(Color)(newWidth * newHeight);
            
            size_t minWidth = min(width, newWidth);
            size_t offsetOld, offsetNew;
            foreach(y; 0 .. min(height, newHeight)) {
                newData[offsetNew .. offsetNew + minWidth] = data[offsetOld .. offsetOld + minWidth];
                
                offsetOld += width;
                offsetNew += newWidth;
            }
            
        }

        allocator.dispose(data);

        width_ = newWidth;
        height_ = newHeight;
        data = newData;

        return true;
    }
    
    /**
     * Get the array that backs this image storage type
     *
     * This is considered an unsafe operation.
     * Do not use unless you know what you are doing.
     *
     * Returns:
     *      The backing array containing the pixels
     */
    immutable(Color[]) __pixelsRawArray() {
        return cast(immutable)data;
    }
}
