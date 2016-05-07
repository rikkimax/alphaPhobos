/**
 * Primitive aspects for an image
 *
 * This module is a submodule of std.experimental.graphic.image.
 * 
 * Provides determinance upon if a type is an image and respective optional functionality.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.graphic.image.primitives;
import std.experimental.graphic.image.interfaces;
import std.experimental.graphic.color;
import std.traits : isPointer, PointerTarget;
import std.experimental.allocator : IAllocator, theAllocator;
import std.experimental.memory.managed : managed;

/**
 * Determine if a type is an image.
 * 
 * Use ImageStorage as the definition to compare against.
 *
 * See_Also:
 *      ImageStorage
 */
bool isImage(Image)() pure if (isPointer!Image && !__traits(compiles, {alias T = Image.PayLoadType;})) {
    return isImage!(PointerTarget!Image)();
}

///
bool isImage(Image)() pure if (__traits(compiles, {alias T = Image.PayLoadType;})) {
	return isImage!(Image.PayLoadType)();
}

///
bool isImage(Image)() pure if (!isPointer!Image && !__traits(compiles, {alias T = Image.PayLoadType;})) {
    import std.traits : ReturnType;
    import std.experimental.graphic.color : isColor;

    static if (__traits(compiles, {Image image = Image.init;}) && is(Image == class) || is(Image == interface) || is(Image == struct)) {
        // check that we can get the color type
        static if (!__traits(compiles, {alias Color = ReturnType!(Image.getPixel);}))
            return false;
        else {
            // make the color type easily worked on
            alias Color = ReturnType!(Image.getPixel);

            static if (!isColor!Color)
                return false;
            else {
                static if (!__traits(compiles, {
                    Image image = void;
                    size_t width = image.width;
                    size_t height = image.height;
                })) {
                    // can we get access to basic elements of the image?
                    return false;
                } else static if (!__traits(compiles, {
                    Image image = void;
                    Color c = image.getPixel(0, 0);
                    image.setPixel(0, 0, c);
                    c = image[0, 0];
                    image[0, 0] = c;

                    bool didResize = image.resize(2, 2);
                })) {
                    // mutation, is it possible?
                    return false;
                } else static if (!__traits(compiles, {
                    import std.experimental.allocator : theAllocator;
                    auto theImage = new Image(1, 1, theAllocator());
                }) && !(is(SwappableImage!Color == Image) || is(ImageStorage!Color == Image))) {
                    // check the constructor is valid
                    return false;
                } else {
                    // ok, is an image
                    return true;
                }
            }
        }
    } else {
        return false;
    }
}

version(unittest) private {
    /*
     * Tests isImage with a class that inherits from Image storage.
     * Confirming that it works with that interface.
     */

    class MyImageStorageUnit(Color) : ImageStorage!Color {
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
            size_t width() @nogc nothrow @trusted { return width_; }
            size_t height() @nogc nothrow @trusted { return height_; }
        }

        Color getPixel(size_t x, size_t y) @nogc @trusted { return data[x][y]; }
        void setPixel(size_t x, size_t y, Color value) @nogc @trusted { data[x][y] = value; }
        Color opIndex(size_t x, size_t y) @nogc @trusted { return getPixel(x, y); }
        void opIndexAssign(Color value, size_t x, size_t y) @nogc @trusted { setPixel(x, y, value); }

        bool resize(size_t, size_t) @nogc @safe { return false; }
    }

    struct NotAColor {}

    // implicitly checks if it is an image

    static assert(!__traits(compiles, { alias Type = MyImageStorageUnit!NotAColor; }));
    static assert(__traits(compiles, { alias Type = MyImageStorageUnit!RGB8; }));
    static assert(isImage!(MyImageStorageUnit!RGB8));

    // while we are at it, lets just test that the image color is gettable.
    static assert(is(ImageColor!(MyImageStorageUnit!RGB8) == RGB8));

    /*
     * Check if the class still works if it does not inherit from ImageStorage interface.
     */

    class MyImageStorageUnitNoInheritance(Color) {
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
            size_t width() @nogc nothrow @trusted { return width_; }
            size_t height() @nogc nothrow @trusted { return height_; }
        }

        Color getPixel(size_t x, size_t y) @nogc @trusted { return data[x][y]; }
        void setPixel(size_t x, size_t y, Color value) @nogc @trusted { data[x][y] = value; }
        Color opIndex(size_t x, size_t y) @nogc @trusted { return getPixel(x, y); }
        void opIndexAssign(Color value, size_t x, size_t y) @nogc @trusted { setPixel(x, y, value); }

        bool resize(size_t, size_t) @nogc @safe { return false; }
    }

    // no implcit checks for if it is an image

    static assert(!isImage!(MyImageStorageUnitNoInheritance!NotAColor));
    static assert(isImage!(MyImageStorageUnitNoInheritance!RGB8));

    // while we are at it, lets just test that the image color is gettable.
    static assert(is(ImageColor!(MyImageStorageUnitNoInheritance!RGB8) == RGB8));

    /*
     * Check if as a struct it still works.
     */

    struct MyImageStorageUnitStruct(Color) {
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
            size_t width() @nogc nothrow @trusted { return width_; }
            size_t height() @nogc nothrow @trusted { return height_; }
        }

        Color getPixel(size_t x, size_t y) @nogc @trusted { return data[x][y]; }
        void setPixel(size_t x, size_t y, Color value) @nogc @trusted { data[x][y] = value; }
        Color opIndex(size_t x, size_t y) @nogc @trusted { return getPixel(x, y); }
        void opIndexAssign(Color value, size_t x, size_t y) @nogc @trusted { setPixel(x, y, value); }

        bool resize(size_t, size_t) @nogc @safe { return false; }
    }

    // no implcit checks for if it is an image

    static assert(!isImage!(MyImageStorageUnitStruct!NotAColor));
    static assert(isImage!(MyImageStorageUnitStruct!RGB8));

    // while we are at it, lets just test that the image color is gettable.
    static assert(is(ImageColor!(MyImageStorageUnitStruct!RGB8) == RGB8));
}

/**
 * The color type that an image storage type complies with.
 */
template ImageColor(Image) if (isImage!Image) {
    import std.traits : ReturnType;
    alias ImageColor = ReturnType!(Image.getPixel);
}

/**
 * Determine if an image supports the pixel offset extension.
 * 
 * Use ImageStorageOffset as the definition to compare against.
 *
 * See_Also:
 *      ImageStorage, ImageStorageOffset
 */
bool supportsImageOffset(Image)() if (isImage!Image) {
    import std.traits : ReturnType;

    static if (is(Image == class) || is(Image == struct)) {
        Image image;

        // make the color type easily worked on

        alias Color = ReturnType!(Image.getPixel);

        if (!__traits(compiles, {
            size_t count = image.count;
        })) {
            // can we get access to basic elements of the image?            
            return false;
        } else if (!__traits(compiles, {
            Color c = image.getPixelAtOffset(0);
            image.setPixelAtOffset(0, c);
            c = image[0];
            image[0] = c;
        })) {
            // mutation, is it possible?
            return false;
        } else {
            // ok, supports pixel offset
            return true;
        }
    } else
        return false;
}

version(unittest) private {
    /*
     * Tests supportsImageOffset with a class that inherits from Image storage.
     * Confirming that it works with that interface.
     */

    class MyImageStorageUnit3(Color) : ImageStorage!Color, ImageStorageOffset!Color {
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
            size_t width() @nogc nothrow @trusted { return width_; }
            size_t height() @nogc nothrow @trusted { return height_; }
            size_t count() @nogc nothrow @trusted { return width_ * height_; }
        }

        Color getPixel(size_t x, size_t y) @nogc @trusted { return data[x][y]; }
        void setPixel(size_t x, size_t y, Color value) @nogc @trusted { data[x][y] = value; }
        Color opIndex(size_t x, size_t y) @nogc @trusted { return getPixel(x, y); }
        void opIndexAssign(Color value, size_t x, size_t y) @nogc @trusted { setPixel(x, y, value); }

        Color getPixelAtOffset(size_t offset) @nogc @trusted { return getPixel(offset % height_, offset / height_);}
        void setPixelAtOffset(size_t offset, Color value) @nogc @trusted { setPixel(offset % height_, offset / height_, value); }
        Color opIndex(size_t offset) @nogc @trusted { return getPixelAtOffset(offset); }
        void opIndexAssign(Color value, size_t offset) @nogc @trusted { setPixelAtOffset(offset, value); }

        bool resize(size_t, size_t) @nogc @safe { return false; }
    }

    // implicitly checks if it is an image

    static assert(__traits(compiles, { alias Type = MyImageStorageUnit3!RGB8; }));
    static assert(isImage!(MyImageStorageUnit3!RGB8));
    static assert(supportsImageOffset!(MyImageStorageUnit3!RGB8));

    /*
     * Check if the class still works if it does not inherit from ImageStorage interface.
     */

    class MyImageStorageUnit2NoInheritance(Color) {
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
            size_t width() @nogc nothrow @trusted { return width_; }
            size_t height() @nogc nothrow @trusted { return height_; }
            size_t count() @nogc nothrow @trusted { return width_ * height_; }
        }

        Color getPixel(size_t x, size_t y) @nogc @trusted { return data[x][y]; }
        void setPixel(size_t x, size_t y, Color value) @nogc @trusted { data[x][y] = value; }
        Color opIndex(size_t x, size_t y) @nogc @trusted { return getPixel(x, y); }
        void opIndexAssign(Color value, size_t x, size_t y) @nogc @trusted { setPixel(x, y, value); }

        Color getPixelAtOffset(size_t offset) @nogc @trusted { return getPixel(offset % height_, offset / height_);}
        void setPixelAtOffset(size_t offset, Color value) @nogc @trusted { setPixel(offset % height_, offset / height_, value); }
        Color opIndex(size_t offset) @nogc @trusted { return getPixelAtOffset(offset); }
        void opIndexAssign(Color value, size_t offset) @nogc @trusted { setPixelAtOffset(offset, value); }

        bool resize(size_t, size_t) @nogc @safe { return false; }
    }

    // no implcit checks for if it is an image

    static assert(__traits(compiles, { alias Type = MyImageStorageUnit2NoInheritance!RGB8; }));
    static assert(isImage!(MyImageStorageUnit2NoInheritance!RGB8));
    static assert(supportsImageOffset!(MyImageStorageUnit2NoInheritance!RGB8));

    /*
     * Check if as a struct it still works.
     */

    struct MyImageStorageUnit2Struct(Color) {
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
            size_t width() @nogc nothrow @trusted { return width_; }
            size_t height() @nogc nothrow @trusted { return height_; }
            size_t count() @nogc nothrow @trusted { return width_ * height_; }
        }

        Color getPixel(size_t x, size_t y) @nogc @trusted { return data[x][y]; }
        void setPixel(size_t x, size_t y, Color value) @nogc @trusted { data[x][y] = value; }
        Color opIndex(size_t x, size_t y) @nogc @trusted { return getPixel(x, y); }
        void opIndexAssign(Color value, size_t x, size_t y) @nogc @trusted { setPixel(x, y, value); }

        Color getPixelAtOffset(size_t offset) @nogc @trusted { return getPixel(offset % height_, offset / height_);}
        void setPixelAtOffset(size_t offset, Color value) @nogc @trusted { setPixel(offset % height_, offset / height_, value); }
        Color opIndex(size_t offset) @nogc @trusted { return getPixelAtOffset(offset); }
        void opIndexAssign(Color value, size_t offset) @nogc @trusted { setPixelAtOffset(offset, value); }

        bool resize(size_t, size_t) @nogc @safe { return false; }
    }

    // no implcit checks for if it is an image

    static assert(__traits(compiles, { alias Type = MyImageStorageUnit2Struct!RGB8; }));
    static assert(isImage!(MyImageStorageUnit2Struct!RGB8));
    static assert(supportsImageOffset!(MyImageStorageUnit2Struct!RGB8));
}

/**
 * Is the type an input range that uses a PixelPoint as element type.
 *
 * See_Also:
 *      PixelPoint
 */
bool isPixelRange(T)() pure {
    import std.range.interfaces : isInputRange, ElementType;

    static if (isInputRange!T) {
        alias ET = ElementType!T;
        return __traits(hasMember, ET, "value") && is(ET == PixelPoint!(typeof(ET.value))) && isColor!(typeof(ET.value));
    } else
        return false;
}

/// The pixel input range color type
template PixelRangeColor(T) if (isPixelRange!T) {
    alias PixelColor = typeof((ElementType!T).value);
    static assert(isColor!PixelColor);
}

/**
 * Copies an image into another image
 *
 * Params:
 *      input       =   The input image
 *      destination =   The output image
 *
 * Returns:
 *      The destination image for composibility reasons
 */
Image2 copyTo(Image1, Image2)(ref Image1 input, Image2 destination) @trusted if (is(Image1 == struct) && !is(Image2 == struct) && !isPointer!Image1 && isImage!Image1 && isImage!Image2)  {
	return copyTo(&input, destination);
}

/// Ditto
ref Image2 copyTo(Image1, Image2)(Image1 input, ref Image2 destination) @trusted if (is(Image2 == struct) && !isPointer!Image2 && isImage!Image1 && isImage!Image2)  {
	return *copyTo(input, &destination);
}

/// Ditto
Image2 copyTo(Image1, Image2)(Image1 input, Image2 destination) /+@nogc+/ @safe if (isImage!Image1 && isImage!Image2) {
    assert(input.width <= destination.width);
    assert(input.height <= destination.height);
    
    foreach(x; 0 .. destination.width) {
        foreach(y; 0 .. destination.height) {
            destination.setPixel(x, y, input.getPixel(x, y));
        }
    }
    
    return destination;
}

/**
 * Copies an pixel image range into an image
 *
 * Auto converts the color to the destination one.
 *
 * Params:
 *      input       =   The pixel input range
 *      destination =   The output image
 *
 * Returns:
 *      The destination image for composibility reasons
 */
Image copyInto(IRRange, Image)(ref IRRange input, ref Image destination) @nogc @safe if (isPixelRange!IRRange && isImage!Image) {
    alias Color = PixelRangeColor!IRRange;
    
    foreach(pixel; input) {
		destination.setPixel(pixel.x, pixel.y, pixel.value.convertTo!Color2);
	}

    return destination;
}

/**
 * Copies an pixel image range into an image
 *
 * Params:
 *      input       =   The pixel input range
 *      destination =   The output image
 *
 * Returns:
 *      The destination image for composibility reasons
 */
Image copyInto(IRRange, Image)(ref IRRange input, ref Image destination) @nogc @safe if (isPixelRange!IRRange && isImage!Image && is(ImageColor!Image == PixelRangeColor!(PixelRangeColor!IRRange))) {
    foreach(pixel; input) {
		destination.setPixel(pixel.x, pixel.y, pixel.value);
	}

    return destination;
}

/**
 * Copies an pixel image range into a new image
 * 
 * Params:
 *      input       = The pixel input range
 *      destination = The output image that will be created, determines type to create as
 *      allocator   = The allocator to allocate the new image by
 * 
 * Returns:
 *      The pixel input range for composibility reasons
 */
IR createImageFrom(ImageImpl, IR)(IR input, out ImageImpl destination, IAllocator allocator=theAllocator()) @safe if (isImage!ImageImpl && isPixelRange!IR) {
    import std.experimental.allocator : make;

    size_t width = input.front.width;
    size_t height = input.front.height;

    destination = allocator.make!ImageImpl(width, height, allocator);

    return input;
}

/**
 * Copies an input ranges buffer into an image, ahead of time assigns all pixels to a specific color
 * 
 * Params:
 *      input       = The pixel input range
 *      destination = The output image that will be created, determines type to create as
 *      fillAs      = The color to assign to each pixel
 * 
 * See_Also:
 *      createImageFrom, copyInto, fillOn
 * 
 * Returns:
 *      The destination image for composibility reasons
 */
Image assignTo(IR, Image, Color)(IR input, ref Image destination, Color fillAs) @nogc @safe if (isImage!ImageImpl && isPixelRange!IR && isColor!Color) {
    return input.copyInto(destination.fillOn(fillAs));
}

// TODO: unittests for copyInto, isPixelRange, PixelRangeColor, createImageFrom, assignTo
