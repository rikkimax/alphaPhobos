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
 * A fairly simple image storage type using a horizontal scan line memory order.
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
    
    @property {
        ///
        size_t width() @nogc nothrow @safe { return width_; }

        ///
        size_t height() @nogc nothrow @safe { return height_; }
    }

    ///
    Color getPixel(size_t x, size_t y) @nogc @safe { return data[(y * width) + x]; }

    ///
    void setPixel(size_t x, size_t y, Color value) @nogc  @safe{ data[(y * width) + x] = value; }

    ///
    Color opIndex(size_t x, size_t y) @nogc  @safe{ return getPixel(x, y); }

    ///
    void opIndexAssign(Color value, size_t x, size_t y) @nogc @safe { setPixel(x, y, value); }
    
    ///
    bool resize(size_t newWidth, size_t newHeight) @trusted
    in {
        assert(newWidth > 0);
        assert(newHeight > 0);
    } body {
        import std.experimental.allocator : dispose;
        import std.algorithm : min;
        Color[] newData = allocator.makeArray!(Color)(width * height);
        
        size_t minWidth = min(width, newWidth);
        size_t offsetOld, offsetNew;
        foreach(y; 0 .. min(height, newHeight)) {
            newData[offsetNew .. offsetNew + minWidth] = data[offset .. offset + minWidth];
            
            offsetOld += width;
            offsetNew += newWidth;
        }
        
        allocator.dispose(data);
        
        width = newWidth;
        height = newHeight;
        data = newData;
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
