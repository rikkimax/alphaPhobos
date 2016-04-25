/**
 * Provides the basic manipulation functions of images.
 * 
 * This is a submodule of std.experimental.graphic.image.manipulation.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.graphic.image.manipulation.base;
import std.experimental.graphic.image.interfaces;
import std.experimental.graphic.image.primitives : isImage, ImageColor, isPixelRange;
import std.experimental.graphic.color : isColor;
import std.experimental.allocator : IAllocator, theAllocator;
import std.traits : isPointer;

/**
 * Fills an image storage instance with a single color
 *
 * Can be used to initialize an image with a set color.
 *
 * Params:
 *      image   =   The image to fill into
 *      value   =   The color to fill as
 *
 * Returns:
 *      The image instance for composability
 *
 * Examples:
 * -------------
 *  SwappableImage!RGB8 image = ...;
 *  image.fill(RGB8(77, 82, 31));
 * -------------
 */
ref Image fillOn(Image, Color = ImageColor!Image)(ref Image image, Color value) @nogc @safe if (isImage!Image && is(Image == struct) && !isPointer!Image) {
	return *fillOn(&image, value);
}

// Ditto
Image fillOn(Image, Color = ImageColor!Image)(Image image, Color value) @nogc @safe if (isImage!Image) {
	foreach(x; 0 .. image.width) {
		foreach(y; 0 .. image.height) {
			image.setPixel(x, y, value);
		}
	}
	
	return image;
}

///
unittest {
    import std.experimental.graphic.color;
    enum RGB8 TheColor = RGB8(78, 82, 11);

    MyTestImage!RGB8 test = new MyTestImage!RGB8(2, 2);
    test.fillOn(TheColor);
    
    assert(test[0, 0] == TheColor);
    assert(test[0, 1] == TheColor);
    assert(test[1, 0] == TheColor);
    assert(test[1, 1] == TheColor);
}

/**
 * Fills a range as replacement for an image size.
 *
 * Can be used to initialize an image with a set color.
 *
 * Params:
 *      image   =   The image to fill as
 *      value   =   The color to fill as
 *
 * Returns:
 *      An input range that returns value for each pixel in the image
 *
 * Examples:
 * -------------
 *  SwappableImage!RGB8 image = ...;
 *  foreach(pixel; image.fillRange(RGB8(77, 82, 31))) {
 *      writeln(pixel, " at x:", pixel.x, " y:", pixel.y);
 *      writeln("\tImage has size width:", pixel.imageWidth, " height:", pixel.imageHeight);
 *  }
 * -------------
 */
auto fillRange(Image, Color = ImageColor!Image)(Image image, Color value) @nogc nothrow @safe if (isImage!Image) {
    return FillRange!Color(image, value);
}

/**
 * Fills a range as replacement for an image size.
 *
 * Can be used to initialize an image with a set color.
 *
 * Params:
 *      image   =   An input range for color to fill as
 *      value   =   The color to fill as
 *
 * Returns:
 *      An input range that returns value for each pixel in the image
 *
 * Examples:
 * -------------
 *  SwappableImage!RGB8 image = ...;
 *  foreach(pixel; image.fillRange(RGB8(77, 82, 31))) {
 *      writeln(pixel, " at x:", pixel.x, " y:", pixel.y);
 *      writeln("\tImage has size width:", pixel.imageWidth, " height:", pixel.imageHeight);
 *  }
 * -------------
 */
auto fillRange(IRImage, ET = ElementType!IRImage, Color)(IRImage image, Color value) @nogc nothrow @safe if (isPixelRange!IRImage && is(ET == PixelPoint!Color)) {
    return FillRange!Color(value, 0, 0, image.front.imageWidth, image.front.imageHeight);
}

private {
    import std.range.interfaces : ElementType;

    struct FillRange(Color) {
        private {
            Color color;
            size_t x_, y_, image_width, image_height;
        }

        this(Image)(Image image, Color value) @nogc nothrow @safe {
            this.color = value;
            image_width = image.width;
            image_height = image.height;
        }

        private this(Color value, size_t x, size_t y, size_t width, size_t height) @nogc nothrow @safe {
            this.color = value;
            this.x_ = x;
            this.y_ = y;
            this.image_width = width;
            this.image_height = height;
        }

        @property {
            PixelPoint!Color front() @nogc nothrow @safe {
                return PixelPoint!Color(color, x_, y_, image_width, image_height);
            }

            bool empty() @nogc nothrow @safe {
                return x_ >= image_width && y_ >= image_height - 1;
            }

            FillRange!Color save() @nogc nothrow @safe {
                return FillRange!Color(color, x_, y_, image_width, image_height);
            }
        }

        void popFront() @nogc nothrow @safe {
            x_++;

            if (empty()) {
            } else {
                if (x_ == image_width) {
                    x_ = 0;
                    y_++;
                }
            }
        }
    }
}

///
unittest {
    import std.experimental.graphic.color;
    enum RGB8 TheColor = RGB8(78, 82, 11);
    enum RGB8 TheColor2 = RGB8(6, 93, 11);

    MyTestImage!RGB8 test = new MyTestImage!RGB8(2, 2);
    
    size_t count;
    foreach(pixel; fillRange(test, TheColor)) {
        assert(pixel.value == TheColor);
        count++;
    }
    assert(count == 4);

    count = 0;
    foreach(pixel; fillRange(test, TheColor).fillRange(TheColor2)) {
        assert(pixel.value == TheColor2);
        count++;
    }
    assert(count == 4);
}

/**
 * Flips an image horiztonally
 *
 * Params:
 *      image   =   The image to flip
 *
 * Returns:
 *      The image for composibility reasons
 */
ref Image flipHorizontal(Image)(ref Image image) if (isImage!Image && is(Image == struct) && !isPointer!Image) {
	return *flipHorizontal(&image);
}

/// Ditto
Image flipHorizontal(Image)(Image image) if (isImage!Image) {
    alias Color = ImageColor!Image;

    size_t height = image.height;
    size_t width = image.width;   
    size_t h2width = width / 2; // is floored as it is an integer not floating point. 

    foreach(y; 0 .. height) {
        size_t x2 = width;
        foreach(x; 0 .. h2width) {
            x2--;
            Color temp;
            temp = image.getPixel(x, y);

			image.setPixel(x, y, image.getPixel(x2, y));
			image.setPixel(x2, y, temp);
        }
    }

    return image;
}

///
unittest {
    import std.experimental.graphic.color;
    MyTestImage!RGB8 test = new MyTestImage!RGB8(2, 2);
    test.flipHorizontal();
}

/**
 * Flips an image horizontally
 *
 * Will allocate a new range as the input image.
 *
 * Params:
 *      image       =   The image to flip
 *      allocator   =   Allocator to allocate the wrapper range for
 *
 * Returns:
 *      An input range that returns value for each pixel in the image
 *
 * See_Also:
 *      rangeOf
 */

auto flipHorizontalRange(Image)(ref Image image, IAllocator allocator=theAllocator()) @safe if (isImage!Image) {
    return flipHorizontalRange(image.rangeOf(allocator));
}

/**
 * Flips an image horizontally
 *
 * Params:
 *      image       =   The image to flip
 *      allocator   =   The allocator to deallocate the image 
 *      ptrToFree   =   The point to free upon destructor call
 *
 * Returns:
 *      An input range that returns value for each pixel in the image
 */
auto flipHorizontalRange(IRImage, ET = ElementType!IRImage)(IRImage image) @nogc @safe if (isPixelRange!IRImage) {
    alias Color = typeof(ET.value);

    struct Result {
        private {
            IRImage input;
            size_t h2width;
        }

        this(IRImage input) @nogc @safe {
            this.input = input;
            h2width = input.front.imageWidth / 2;
        }

        @property {
            PixelPoint!Color front() @nogc @safe {
                auto got = input.front;
                return PixelPoint!Color(got.value, got.imageWidth - got.x, got.y, got.imageWidth, got.imageHeight);
            }

            bool empty() @safe {
                return input.empty;
            }
        }

        void popFront() @nogc nothrow @safe {
            input.popFront;
        }
    }

    return Result(image);
}

///
unittest {
    import std.experimental.graphic.color;
    enum RGB8 TheColor = RGB8(78, 82, 11);

    MyTestImage!RGB8 test = new MyTestImage!RGB8(2, 2); 
    test.fillOn(TheColor);

    final class Foo {
        MyTestImage!RGB8 value;
        alias value this;

        this(MyTestImage!RGB8 value) {
            this.value = value;
        }
    }

    size_t count;
    foreach(pixel; flipHorizontalRange(test)) {
        assert(pixel.value == TheColor);
        count++;
    }
    assert(count == 4);

    count = 0;
    foreach(pixel; flipHorizontalRange(test).flipHorizontalRange()) {
        assert(pixel.value == TheColor);
        count++;
    }
    assert(count == 4);
}

/**
 * Flips an image vertical
 *
 * Params:
 *      image   =   The image to flip
 *
 * Returns:
 *      The image for composibility reasons
 */
ref Image flipVertical(Image)(ref Image image) if (isImage!Image && is(Image == struct) && !isPointer!Image) {
	return *flipVertical(&image);
}

/// Ditto
Image flipVertical(Image)(Image image) if (isImage!Image) {
    alias Color = ImageColor!Image;

    size_t height = image.height;
    size_t width = image.width;   
    size_t h2height = height / 2; // is floored as it is an integer not floating point. 

    foreach(x; 0 .. width) {
        size_t y2 = height;
        foreach(y; 0 .. h2height) {
            y2--;
            Color temp;
			temp = image.getPixel(x, y);

			image.setPixel(x, y, image.getPixel(x, y2));
			image.setPixel(x, y2, temp);
        }
    }

    return image;
}

///
unittest {
    import std.experimental.graphic.color;
    MyTestImage!RGB8 test = new MyTestImage!RGB8(2, 2);
    test.flipVertical();
}

/**
 * Flips an image vertical
 *
 * Will allocate a new range as the input image.
 *
 * Params:
 *      image       =   The image to flip
 *      allocator   =   Allocator to allocate the wrapper range for
 *
 * Returns:
 *      An input range that returns value for each pixel in the image
 *
 * See_Also:
 *      rangeOf
 */
auto flipVerticalRange(Image)(ref Image image, IAllocator allocator=theAllocator()) @safe if (isImage!Image) {
    return flipVerticalRange(image.rangeOf(allocator));
}

/**
 * Flips an image horizontally
 *
 * Params:
 *      image   =   The image to flip
 *
 * Returns:
 *      An input range that returns value for each pixel in the image
 */
auto flipVerticalRange(IRImage, ET = ElementType!IRImage)(IRImage image) @nogc @safe if (isPixelRange!IRImage) {
    alias Color = typeof(ET.value);

    struct Result {
        private {
            IRImage input;
        }

        this(IRImage input) @nogc @safe {
            this.input = input;
        }

        @property {
            PixelPoint!Color front() @nogc @safe {
                auto got = input.front;
                return PixelPoint!Color(got.value, got.x, got.imageHeight - got.y, got.imageWidth, got.imageHeight);
            }

            bool empty() @safe {
                return input.empty;
            }

            static if (__traits(hasMember, IRImage, "save")) {
                auto save() @nogc @safe {
                    return Result(input.save());
                }
            }
        }

        void popFront() @nogc nothrow @safe {
            input.popFront;
        }
    }

    return Result(image);
}

///
unittest {
    import std.experimental.graphic.color;
    enum RGB8 TheColor = RGB8(78, 82, 11);

    MyTestImage!RGB8 test = new MyTestImage!RGB8(2, 2); 
    test.fillOn(TheColor);

    final class Foo {
        MyTestImage!RGB8 value;
        alias value this;

        this(MyTestImage!RGB8 value) {
            this.value = value;
        }
    }

    size_t count;
    foreach(pixel; flipVerticalRange(test)) {
        assert(pixel.value == TheColor);
        count++;
    }
    assert(count == 4);

    count = 0;
    foreach(pixel; flipVerticalRange(test).flipVerticalRange()) {
        assert(pixel.value == TheColor);
        count++;
    }
    assert(count == 4);
}