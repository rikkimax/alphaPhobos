/**
 * Rotation manipulation feature
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 *
 * Supplys rotation manipulation upon images and PixelPoint input ranges.
 */
module std.experimental.graphic.image.manipulation.rotation;
import std.experimental.graphic.image.interfaces;
import std.experimental.graphic.image.primitives : isImage, ImageColor, isPixelRange, PixelRangeColor;
import std.experimental.graphic.color : isColor;
import std.experimental.allocator : make, theAllocator, IAllocator;

///
enum RotateDirection : bool {
    ///
    ClockWise,

    ///
    AntiClockWise
}

/*
 * Set rotation 90
 */

/**
 * Rotates an image 90 degrees in place.
 * 
 * Params:
 *      from        =   The image to rotate
 *      direction   =   The direction to rotate
 * 
 * Returns:
 *      The input image for chainability reasons.
 */
Image rotate90(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise) if (isImage!Image) {
    // 0 => 1
    // 1 => 2
    // 2 => 3
    // 3 => 0
    
    return perform4WaySwap(from, direction, 1);
}

/**
 * Rotates an image 90 degrees
 * 
 * Wraps the input range varient of this to take an image instead.
 * 
 * Params:
 *      image       =   The image to rotate
 *      direction   =   The direction to rotate
 *      allocator   =   The allocator to allocate an input range from
 * 
 * Returns:
 *      An input range that has an ElementType of PixelPoint.
 */
auto rotate90Range(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise, IAllocator allocator = theAllocator()) if (isImage!Image) {
    return rotate90Range(from.rangeOf(allocator), direction);
}

/**
 * Rotates an image 90 degrees
 * 
 * Params:
 *      from        =   Input range to take pixels from
 *      direction   =   The direction to rotate
 *      allocator   =   The allocator to allocate an input range from
 * 
 * Returns:
 *      An input range that has an ElementType of PixelPoint.
 */
auto rotate90Range(IR)(IR from, RotateDirection direction = RotateDirection.ClockWise) if (isPixelRange!IR) {
    return RotateN!(PixelRangeColor!IR, IR)(from, 1, direction);
}

/*
 * Set rotation 180
 */

/**
 * Rotates an image 180 degrees in place.
 * 
 * Params:
 *      from        =   The image to rotate
 *      direction   =   The direction to rotate
 * 
 * Returns:
 *      The input image for chainability reasons.
 */
Image rotate180(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise) if (isImage!Image) {
    // 0 => 2
    // 1 => 3
    // 2 => 0
    // 3 => 1

    return perform4WaySwap(from, direction, 2);
}

/**
 * Rotates an image 180 degrees
 * 
 * Wraps the input range varient of this to take an image instead.
 * 
 * Params:
 *      image       =   The image to rotate
 *      direction   =   The direction to rotate
 *      allocator   =   The allocator to allocate an input range from
 * 
 * Returns:
 *      An input range that has an ElementType of PixelPoint.
 */
auto rotate180Range(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise, IAllocator allocator = theAllocator()) if (isImage!Image) {
    return rotate180Range(from.rangeOf(allocator), direction);
}

/**
 * Rotates an image 180 degrees
 * 
 * Params:
 *      from        =   Input range to take pixels from
 *      direction   =   The direction to rotate
 *      allocator   =   The allocator to allocate an input range from
 * 
 * Returns:
 *      An input range that has an ElementType of PixelPoint.
 */
auto rotate180Range(IR)(IR from, RotateDirection direction = RotateDirection.ClockWise) if (isPixelRange!IR) {
    return RotateN!(PixelRangeColor!IR, IR)(from, 2, direction);
}

/*
 * Set rotation 270
 */

/**
 * Rotates an image 270 degrees in place.
 * 
 * Params:
 *      from        =   The image to rotate
 *      direction   =   The direction to rotate
 * 
 * Returns:
 *      The input image for chainability reasons.
 */
Image rotate270(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise) if (isImage!Image) {
    // 0 => 3
    // 1 => 0
    // 2 => 1
    // 3 => 2
    
    return perform4WaySwap(from, direction, 3);
}

/**
 * Rotates an image 270 degrees
 * 
 * Wraps the input range varient of this to take an image instead.
 * 
 * Params:
 *      image       =   The image to rotate
 *      direction   =   The direction to rotate
 *      allocator   =   The allocator to allocate an input range from
 * 
 * Returns:
 *      An input range that has an ElementType of PixelPoint.
 */
auto rotate270Range(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise, IAllocator allocator = theAllocator()) if (isImage!Image) {
    return rotate270Range(from.rangeOf(allocator), direction);
}

/**
 * Rotates an image 270 degrees
 * 
 * Params:
 *      from        =   Input range to take pixels from
 *      direction   =   The direction to rotate
 *      allocator   =   The allocator to allocate an input range from
 * 
 * Returns:
 *      An input range that has an ElementType of PixelPoint.
 */
auto rotate270Range(IR)(IR from, RotateDirection direction = RotateDirection.ClockWise) if (isPixelRange!IR) {
    return RotateN!(PixelRangeColor!IR, IR)(from, 3, direction);
}

/*
 * Abituary rotation
 */

/**
 * Radians
 */
Image rotate(Impl, Image)(Image from, double by, RotateDirection direction = RotateDirection.ClockWise, IAllocator allocator = theAllocator()) if (isImage!Impl && isImage!Image)
in {
    assert(by <= D_PI);
} body {
    import std.math : cos, sin;
    import std.typecons : tuple;

    auto newSize = calculateNewSize(from.width, from.height, by);

    Impl ret = allocator.make!Impl(newSize[0], newSize[1], allocator);

    assert(0);

    foreach(toX; 0 .. newSize[0]) {
        foreach(toY; 0 .. newSize[1]) {
            auto from = oldCoord(toX, toY, by);

            // TODO: waiting on Manu Evans for blending of colors (bilienear filter)
        }
    }

    return ret;
}

private {
    import std.math : PI_2, PI, PI_4;
    import std.typecons : Tuple, tuple;

    enum PI_34 = 3 * PI_4;
    enum D_PI = 2 * PI;

    // TODO: unittests!
    Tuple!(size_t, size_t) calculateNewSize(size_t oldWidth, size_t oldHeight, double by) {
        import std.math : cos, sin;
        
        double newWidth, newHeight;
        
        //L * cos(t) + H
        newWidth = oldWidth * cos(by) + oldHeight;
        //L * sin(t) + H
        newHeight = oldWidth * sin(by) + oldHeight;
        
        double by2;
        if (by <= PI_2) //(90 – t)
            by2 = PI_2 - by;
        else if (by <= PI) //(180 – t)
            by2 = PI - by;
        else if (by <= PI_34) //(t – 180)
            by2 = by - PI_34;
        else if (by <= D_PI) //(360 – t)
            by2 = D_PI - by;
        
        // * cos(90 – t)
        newWidth *= cos(by2);
        // * sin(90 – t)
        newHeight *= sin(by2);

        return tuple(cast(size_t)newWidth, cast(size_t)newHeight);
    }

    // TODO: unittests!
    Tuple!(size_t, size_t) oldCoord(size_t toX, size_t toY, double by) {
        import std.math : cos, sin;

        double a = cos(by);
        double b = sin(by);
        double determinant = a*a-b*-b;

        double x = (toX * a) + (toY * b);
        double y = (toX * -b) + (toY * a);
        x /= determinant;
        y /= determinant;

        // FIXME
        assert(x >= 0);
        assert(y >= 0);
        
        return tuple(cast(size_t)x, cast(size_t)y);
    }

    size_t[4][2] coords4WaySwap(size_t width, size_t height, size_t x, size_t y, RotateDirection direction) @safe
    in {
        import std.math : floor;
        import std.exception : enforce;

        enforce(x <= floor(width / 2f));
        enforce(y <= floor(height / 2f));
    } body {
        if (direction == RotateDirection.ClockWise) {
            // 0 1 2 3
            return [[
                    x,
                    y,
                    width - (x+1),
                    width - (y+1)
                ], [
                    y,
                    x,
                    height - (y+1),
                    height - (x+1)
                ]];
        } else if (direction == RotateDirection.AntiClockWise) {
            // 2 3 0 1
            
            return [[
                    width - (x+1),
                    width - (y+1),
                    x,
                    y
                ], [
                    height - (y+1),
                    height - (x+1),
                    y,
                    x
                ]];
        }

        assert(0);
    }

    unittest {
        import std.exception : assertThrown, assertNotThrown;

        // contract checks

        assertThrown(coords4WaySwap(3, 3, 2, 1, RotateDirection.ClockWise));
        assertNotThrown(coords4WaySwap(3, 3, 1, 0, RotateDirection.ClockWise));
        assertThrown(coords4WaySwap(3, 3, 2, 1, RotateDirection.ClockWise));
    }

    unittest {
        size_t[4][2] v;

        // if condition check

        v = coords4WaySwap(3, 3, 0, 1, RotateDirection.ClockWise);
        assert(v[0][0] == 0);
        assert(v[0][1] == 1);
        assert(v[1][0] == 1);
        assert(v[1][1] == 0);

        assert(v[0][2] == 2);
        assert(v[0][3] == 1);
        assert(v[1][2] == 1);
        assert(v[1][3] == 2);
    }

    unittest {
        size_t[4][2] v;

        // clockwise

        v = coords4WaySwap(3, 3, 0, 1, RotateDirection.AntiClockWise);
        assert(v[0][2] == 0);
        assert(v[0][3] == 1);
        assert(v[1][2] == 1);
        assert(v[1][3] == 0);
        
        assert(v[0][0] == 2);
        assert(v[0][1] == 1);
        assert(v[1][0] == 1);
        assert(v[1][1] == 2);
    }

    // TODO: unittests!
    Image perform4WaySwap(Image)(Image from, RotateDirection direction, ubyte idxAdd) if (isImage!Image) {
        foreach(x; 0 .. (from.width / 2)) {
            foreach(y; 0 .. cast(size_t)(from.height / 2)) {
                size_t[4][2] coords = coords4WaySwap(from.width, from.height, x, y, direction);
                
                Color[4] temp = [
                    from[coords[0][0], coords[1][0]], from[coords[0][1], coords[1][1]],
                    from[coords[0][2], coords[1][2]], from[coords[0][3], coords[1][3]]
                ];
                
                ubyte nidx;

                nidx = (0 + idxAdd) % 4;
                from[coords[0][nidx], coords[1][nidx]] = temp[0];
                nidx = (1 + idxAdd) % 4;
                from[coords[0][nidx], coords[1][nidx]] = temp[1];
                nidx = (2 + idxAdd) % 4;
                from[coords[0][nidx], coords[1][nidx]] = temp[2];
                nidx = (3 + idxAdd) % 4;
                from[coords[0][nidx], coords[1][nidx]] = temp[3];
            }
        }
        
        return from;
    }

    // TODO: unittests
    struct RotateN(Color, IRRange) {
        IRRange input;
        PixelPoint!Color current;
        ubyte idxToAdd;
        RotateDirection direction;

        this(IRRange input, ubyte idxToAdd, RotateDirection direction) {
            this.input = input;
            this.idxToAdd = idxToAdd;
            this.direction = direction;
            popFront;
        }

        @property {
            PixelPoint!Color front() {
                return current;
            }

            bool empty() {
                return input.empty;
            }
        }

        void popFront() {
            if (!empty) {
                PixelPoint got = input.front;

                size_t[4][2] coords = coords4WaySwap(got.width, got.height, got.x, got.y, direction);
                ubyte corner;

                if (got.x < got.width / 2) {
                    if (got.y < got.height / 2) {
                        corner = 0;
                    } else {
                        corner = 3;
                    }
                } else {
                    if (got.y < got.height / 2) {
                        corner = 1;
                    } else {
                        corner = 2;
                    }
                }

                ubyte nidx;
                nidx = (corner + idxAdd) % 4;
                current = PixelPoint!Color(got.value, coords[0][nidx], coords[1][nidx], got.width, got.height);

                input.popFront;
            }
        }
    }
}