/**
 * Common scan line storage implementations
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.graphic.image.storage.base;
import std.experimental.graphic.color : isColor;
import std.experimental.allocator : IAllocator, ISharedAllocator, theAllocator, processAllocator;

/**
 * A fairly simple image storage type using a horizontal scan line memory order.
 * 
 * Will automatically deallocate its memory when it goes out of scope.
 * Should not be copied or moved around.
 * 
 * See_Also:
 *      ImageStorage
 */
struct ImageStorageHorizontal(Color) if (isColor!Color) {
    private {
        size_t width_, height_;
        IAllocator allocator;
        Color[][] data;
    }

	@disable
	this(this);

    ///
    this(size_t width, size_t height, IAllocator allocator = theAllocator()) @trusted {
        import std.experimental.allocator : makeArray;
        this.allocator = allocator;

        width_ = width;
        height_ = height;
        
        data = allocator.makeArray!(Color[])(width);
        
        foreach(_; 0 .. width) {
            data[_] = allocator.makeArray!Color(height);
        }
    }

	///
	this(size_t width, size_t height, shared(ISharedAllocator) allocator) @trusted shared {
		/+import std.experimental.allocator : makeArray;
		this.allocator = allocator;
		
		width_ = width;
		height_ = height;
		
		data = allocator.makeArray!(Color[])(width);
		
		foreach(_; 0 .. width) {
			data[_] = allocator.makeArray!Color(height);
		}+/
	}

	~this() @trusted {
		import std.experimental.allocator : dispose;

		foreach(_; 0 .. width_) {
			allocator.dispose(data[_]);
		}

		allocator.dispose(data);
	}

    @property {
        ///
		size_t width() @nogc nothrow @safe { return width_; }
		///
		size_t width() @nogc nothrow @safe shared { return width_; }

        ///
		size_t height() @nogc nothrow @safe { return height_; }
		///
		size_t height() @nogc nothrow @safe shared { return height_; }
    }

    ///
	Color getPixel(size_t x, size_t y) @nogc @safe { return data[x][y]; }
	///
	Color getPixel(size_t x, size_t y) @nogc @safe shared { return data[x][y]; }

    ///
	void setPixel(size_t x, size_t y, Color value) @nogc @safe { data[x][y] = value; }
	///
	void setPixel(size_t x, size_t y, Color value) @nogc @safe shared { data[x][y] = value; }

    ///
	Color opIndex(size_t x, size_t y) @nogc @safe { return getPixel(x, y); }
	Color opIndex(size_t x, size_t y) @nogc @safe shared { return getPixel(x, y); }

    ///
	void opIndexAssign(Color value, size_t x, size_t y) @nogc @safe { setPixel(x, y, value); }
	void opIndexAssign(Color value, size_t x, size_t y) @nogc @safe shared { setPixel(x, y, value); }

	bool resize(size_t newWidth, size_t newHeight) @trusted shared
	{ return (cast()this).resize(newWidth, newHeight); }

    ///
    bool resize(size_t newWidth, size_t newHeight) @trusted
    in {
        assert(newWidth > 0);
        assert(newHeight > 0);
    } body { 
        import std.experimental.allocator : expandArray, shrinkArray, makeArray;

        if (newWidth == width_ && newHeight == height_) return true;
        size_t deltaHeight;

        if (width_ < newWidth) {
            assert(allocator.expandArray!(Color[])(data, newWidth - width_));
        } else if (width_ == newWidth) {
        } else {
            assert(allocator.shrinkArray!(Color[])(data, width_ - newWidth));
        }

        if (height_ < newHeight)
            deltaHeight = newHeight - height_;
        else
            deltaHeight = height_ - newHeight;

        foreach(_; 0 .. width_) {
            if (height_ < newHeight) {
                assert(allocator.expandArray!Color(data[_], deltaHeight));
            } else if (height_ == newHeight) {
            } else {
                assert(allocator.shrinkArray!Color(data[_], deltaHeight));
            }
        }
        
        if (width_ < newWidth) {
            foreach(_; width_-1 .. newWidth) {
                auto got = allocator.makeArray!Color(newHeight);
                assert(got !is null);
                data[_] = got;
            }
        }

        width_ = newWidth;
        height_ = newHeight;
        return true;
    }
}

///
unittest {
    import std.experimental.graphic.color;
    ImageStorageHorizontal!RGB8 image = ImageStorageHorizontal!RGB8(1, 1);
    image.resize(2, 2);

    assert(image.width == 2);
    assert(image.height == 2);
    assert(image[1, 1] == image[0, 0]);
}

/**
 * A fairly simple image storage type using a vertical scan line memory order.
 * 
 * Will automatically deallocate its memory when it goes out of scope.
 * Should not be copied or moved around.
 * 
 * See_Also:
 *      ImageStorage
 */
struct ImageStorageVertical(Color) if (isColor!Color) {
    private {
        size_t width_, height_;
        IAllocator allocator;
        Color[][] data;
    }

    ///
    this(size_t width, size_t height, IAllocator allocator = theAllocator()) @trusted {
        import std.experimental.allocator : makeArray;
        this.allocator = allocator;

        width_ = width;
        height_ = height;
        
        data = allocator.makeArray!(Color[])(height);
        
        foreach(_; 0 .. height) {
            data[_] = allocator.makeArray!Color(width);
        }
    }

	~this() @trusted {
		import std.experimental.allocator : dispose;

		foreach(_; 0 .. width_) {
			allocator.dispose(data[_]);
		}
		
		allocator.dispose(data);
	}

    @property {
        ///
        size_t width() @nogc nothrow @safe { return width_; }

        ///
        size_t height() @nogc nothrow @safe { return height_; }
    }

    ///
    Color getPixel(size_t x, size_t y) @nogc @safe { return data[y][x]; }

    ///
    void setPixel(size_t x, size_t y, Color value) @nogc  @safe{ data[y][x] = value; }

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
        import std.experimental.allocator : expandArray, shrinkArray, makeArray;

        if (newWidth == width_ && newHeight == height_) return true;
        size_t deltaWidth;

        if (height_ < newHeight) {
            assert(allocator.expandArray!(Color[])(data, newHeight - height_));
        } else if (height_ == newHeight) {
        } else {
            assert(allocator.shrinkArray!(Color[])(data, height_ - newHeight));
        }

        if (width_ < newWidth)
            deltaWidth = newWidth - width_;
        else
            deltaWidth = width_ - newWidth;

        foreach(_; 0 .. height_) {
            if (width_ < newWidth) {
                assert(allocator.expandArray!Color(data[_], deltaWidth));
            } else if (width_ == newWidth) {
            } else {
                assert(allocator.shrinkArray!Color(data[_], deltaWidth));
            }
        }

        if (height_ < newHeight) {
            foreach(_; height_-1 .. newHeight) {
                auto got = allocator.makeArray!Color(newWidth);
                assert(got !is null);
                data[_] = got;
            }
        }

        width_ = newWidth;
        height_ = newHeight;
        return true;
    }
}

///
unittest {
    import std.experimental.graphic.color;
    ImageStorageVertical!RGB8 image = ImageStorageVertical!RGB8(1, 1);
    image.resize(2, 2);

    assert(image.width == 2);
    assert(image.height == 2);
    assert(image[1, 1] == image[0, 0]);
}
