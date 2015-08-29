module std.experimental.graphic.image.manipulation.rotation;
import std.experimental.graphic.image.interfaces;
import std.experimental.graphic.image.primitives : isImage, ImageColor, isPixelRange;
import std.experimental.graphic.color : isColor;
import std.experimental.allocator : make, theAllocator, IAllocator;

enum RotateDirection : bool {
    ClockWise,
    AntiClockWise
}

/*
 * Set rotation 90
 */

Image rotate90(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise) if (isImage!Image) {
    // 0 => 1
    // 1 => 2
    // 2 => 3
    // 3 => 0
    
    return perform4WaySwap(from, direction, 1);
}

auto rotate90Range(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise, IAllocator allocator = theAllocator()) if (isImage!Image) {
    assert(0);
}

auto rotate90Range(IR)(IR from, RotateDirection direction = RotateDirection.ClockWise) if (isPixelRange!IR) {
    assert(0);
}

/*
 * Set rotation 180
 */

Image rotate180(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise) if (isImage!Image) {
    // 0 => 2
    // 1 => 3
    // 2 => 0
    // 3 => 1

    return perform4WaySwap(from, direction, 2);
}

auto rotate180Range(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise, IAllocator allocator = theAllocator()) if (isImage!Image) {
    assert(0);
}

auto rotate180Range(IR)(IR from, RotateDirection direction = RotateDirection.ClockWise) if (isPixelRange!IR) {
    assert(0);
}

/*
 * Set rotation 270
 */

Image rotate270(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise) if (isImage!Image) {
    // 0 => 3
    // 1 => 0
    // 2 => 1
    // 3 => 2
    
    return perform4WaySwap(from, direction, 3);
}

auto rotate270Range(Image)(Image from, RotateDirection direction = RotateDirection.ClockWise, IAllocator allocator = theAllocator()) if (isImage!Image) {
    assert(0);
}

auto rotate270Range(IR)(IR from, RotateDirection direction = RotateDirection.ClockWise) if (isPixelRange!IR) {
    assert(0);
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

    size_t[4][2] coords4WaySwap(size_t width, size_t height, size_t x, size_t y, RotateDirection direction)
    in {
        import std.math : ceilf;
        import std.exception : enforce;

        enforce(x < (width-1));
        enforce(y <= ceilf(height / 2));
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
        foreach(x; 0 .. (from.width-1)) {
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
}