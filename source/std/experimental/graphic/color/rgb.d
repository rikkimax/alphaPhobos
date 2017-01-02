// Written in the D programming language.

/**
This module implements the $(LINK2 https://en.wikipedia.org/wiki/RGB_color_space, RGB) _color type.

RGB is the most common expression of colors used in computing, where a _color is specified as some
amount of red, green and blue primaries.

RGB is highly parametric, and comes in many shapes and sizes, with the most common being
$(LINK2 https://en.wikipedia.org/wiki/SRGB, sRGB), which is conventionally used on
computer monitors, and standard for use on the web.

RGB colors require the RGB _color space parameters to be defined to be considered 'absolute' colors.

Authors:    Manu Evans
Copyright:  Copyright (c) 2015, Manu Evans.
License:    $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source:     $(PHOBOSSRC std/experimental/color/_rgb.d)
*/
module std.experimental.graphic.color.rgb;

import std.experimental.graphic.color;
import std.experimental.graphic.color.colorspace;
import std.experimental.graphic.color.xyz : XYZ, isXYZ;
import std.experimental.normint;

import std.traits : isInstanceOf, isNumeric, isIntegral, isFloatingPoint, isSomeChar, Unqual;
import std.typetuple : TypeTuple;
import std.typecons : tuple;

@safe pure nothrow @nogc:


/**
Detect whether $(D_INLINECODE T) is an RGB color.
*/
enum isRGB(T) = isInstanceOf!(RGB, T);

///
unittest
{
    static assert(isRGB!(RGB!("bgr", ushort)) == true);
    static assert(isRGB!LA8 == true);
    static assert(isRGB!int == false);
}


// DEBATE: which should it be?
template defaultAlpha(T)
{
/+
    enum defaultAlpha = isFloatingPoint!T ? T(1) : T.max;
+/
    enum defaultAlpha = T(0);
}


/**
An RGB color, parameterised with components, component type, and color space specification.

Params: components_ = Components that shall be available. Struct is populated with components in the order specified.$(BR)
                      Valid components are:$(BR)
                        "r" = red$(BR)
                        "g" = green$(BR)
                        "b" = blue$(BR)
                        "a" = alpha$(BR)
                        "l" = luminance$(BR)
                        "x" = placeholder/padding (no significant value)
        ComponentType_ = Type for the color channels. May be a basic integer or floating point type.
        linear_ = Color is stored with linear luminance.
        colorSpace_ = Color will be within the specified color space.
*/
struct RGB(string components_, ComponentType_, bool linear_ = false, RGBColorSpace colorSpace_ = RGBColorSpace.sRGB)
    if (isNumeric!ComponentType_)
{
@safe pure:

    /** Construct a color from a string. */
    this(C)(const(C)[] str) if (isSomeChar!C)
    {
        this = colorFromString!(typeof(this))(str);
    }
    ///
    unittest
    {
        static assert(RGB8("#8000FF")  == RGB8(0x80,0x00,0xFF));
        static assert(RGBA8("#908000FF") == RGBA8(0x80,0x00,0xFF,0x90));
    }

nothrow @nogc:

    // RGB colors may only contain components 'rgb', or 'l' (luminance)
    // They may also optionally contain an 'a' (alpha) component, and 'x' (unused) components
    static assert(allIn!("rgblax", components), "Invalid Color component '"d ~ notIn!("rgblax", components) ~ "'. RGB colors may only contain components: r, g, b, l, a, x"d);
    static assert(anyIn!("rgbal", components), "RGB colors must contain at least one component of r, g, b, l, a.");
    static assert(!canFind!(components, 'l') || !anyIn!("rgb", components), "RGB colors may not contain rgb AND luminance components together.");

    static if (isFloatingPoint!ComponentType_)
    {
        /** Type of the color components. */
        alias ComponentType = ComponentType_;
    }
    else
    {
        /** Type of the color components. */
        alias ComponentType = NormalizedInt!ComponentType_;
    }

    /** The color components that were specified. */
    enum string components = components_;
    /** The colors color space. */
    enum RGBColorSpace colorSpace = colorSpace_;
    /** The color space descriptor. */
    enum RGBColorSpaceDesc!F colorSpaceDesc(F = double) = rgbColorSpaceDef!F(colorSpace_);
    /** If the color is stored linearly (without gamma applied). */
    enum bool linear = linear_;


    // mixin will emit members for components
    template Components(string components)
    {
        static if (components.length == 0)
            enum Components = "";
        else
            enum Components = ComponentType.stringof ~ ' ' ~ components[0] ~ " = 0;\n" ~ Components!(components[1..$]);
    }
    mixin(Components!components);

    /** Test if a particular component is present. */
    enum bool hasComponent(char c) = mixin("is(typeof(this."~c~"))");
    /** If the color has alpha. */
    enum bool hasAlpha = hasComponent!'a';


    /** Return the RGB tristimulus values as a tuple.
        These will always be ordered (R, G, B).
        Any color channels not present will be 0. */
    @property auto tristimulus() const
    {
        static if (hasComponent!'l')
        {
            return tuple(l, l, l);
        }
        else
        {
            static if (!hasComponent!'r')
                enum r = ComponentType(0);
            static if (!hasComponent!'g')
                enum g = ComponentType(0);
            static if (!hasComponent!'b')
                enum b = ComponentType(0);
            return tuple(r, g, b);
        }
    }
    ///
    unittest
    {
        // tristimulus returns tuple of R, G, B
        static assert(BGR8(255, 128, 10).tristimulus == tuple(NormalizedInt!ubyte(255), NormalizedInt!ubyte(128), NormalizedInt!ubyte(10)));
    }

    /** Return the RGB tristimulus values + alpha as a tuple.
        These will always be ordered (R, G, B, A). */
    @property auto tristimulusWithAlpha() const
    {
        static if (!hasAlpha)
            enum a = defaultAlpha!ComponentType;
        return tuple(tristimulus.expand, a);
    }
    ///
    unittest
    {
        // tristimulusWithAlpha returns tuple of R, G, B, A
        static assert(BGRA8(255, 128, 10, 80).tristimulusWithAlpha == tuple(NormalizedInt!ubyte(255), NormalizedInt!ubyte(128), NormalizedInt!ubyte(10), NormalizedInt!ubyte(80)));
    }

    /** Construct a color from RGB and optional alpha values. */
    this(ComponentType r, ComponentType g, ComponentType b, ComponentType a = defaultAlpha!ComponentType)
    {
        foreach (c; TypeTuple!("r","g","b","a"))
            mixin(ComponentExpression!("this._ = _;", c, null));
        static if (canFind!(components, 'l'))
            this.l = toGrayscale!(linear, colorSpace)(r, g, b); // ** Contentious? I this this is most useful
    }

    /** Construct a color from a luminance and optional alpha value. */
    this(ComponentType l, ComponentType a = defaultAlpha!ComponentType)
    {
        foreach (c; TypeTuple!("l","r","g","b"))
            mixin(ComponentExpression!("this._ = l;", c, null));
        static if (canFind!(components, 'a'))
            this.a = a;
    }

    static if (!isFloatingPoint!ComponentType_)
    {
        /** Construct a color from RGB and optional alpha values. */
        this(ComponentType.IntType r, ComponentType.IntType g, ComponentType.IntType b, ComponentType.IntType a = defaultAlpha!(ComponentType.IntType))
        {
            foreach (c; TypeTuple!("r","g","b","a"))
                mixin(ComponentExpression!("this._ = ComponentType(_);", c, null));
            static if (canFind!(components, 'l'))
                this.l = toGrayscale!(linear, colorSpace)(ComponentType(r), ComponentType(g), ComponentType(b)); // ** Contentious? I this this is most useful
        }

        /** Construct a color from a luminance and optional alpha value. */
        this(ComponentType.IntType l, ComponentType.IntType a = defaultAlpha!(ComponentType.IntType))
        {
            foreach (c; TypeTuple!("l","r","g","b"))
                mixin(ComponentExpression!("this._ = ComponentType(l);", c, null));
            static if (canFind!(components, 'a'))
                this.a = ComponentType(a);
        }
    }

    /**
    Cast to other color types.

    This cast is a convenience which simply forwards the call to convertColor.
    */
    Color opCast(Color)() const if (isColor!Color)
    {
        return convertColor!Color(this);
    }

    // comparison
    bool opEquals(typeof(this) rh) const
    {
        // this is required to exclude 'x' components from equality comparisons
        return tristimulusWithAlpha == rh.tristimulusWithAlpha;
    }

    /** Unary operators. */
    typeof(this) opUnary(string op)() const if (op == "+" || op == "-" || (op == "~" && is(ComponentType == NormalizedInt!U, U)))
    {
        Unqual!(typeof(this)) res = this;
        foreach (c; AllComponents)
            mixin(ComponentExpression!("res._ = #_;", c, op));
        return res;
    }
    ///
    unittest
    {
        static assert(+UVW8(1,2,3) == UVW8(1,2,3));
        static assert(-UVW8(1,2,3) == UVW8(-1,-2,-3));

        static assert(~RGB8(1,2,3) == RGB8(0xFE,0xFD,0xFC));
        static assert(~UVW8(1,2,3) == UVW8(~1,~2,~3));
    }

    /** Binary operators. */
    typeof(this) opBinary(string op)(typeof(this) rh) const if (op == "+" || op == "-" || op == "*")
    {
        Unqual!(typeof(this)) res = this;
        foreach (c; AllComponents)
            mixin(ComponentExpression!("res._ #= rh._;", c, op));
        return res;
    }
    ///
    unittest
    {
        static assert(RGB8(10,20,30)       + RGB8(4,5,6) == RGB8(14,25,36));
        static assert(UVW8(10,20,30)       + UVW8(4,5,6) == UVW8(14,25,36));
        static assert(RGBAf32(10,20,30,40) + RGBAf32(4,5,6,7) == RGBAf32(14,25,36,47));

        static assert(RGB8(10,20,30)       - RGB8(4,5,6) == RGB8(6,15,24));
        static assert(UVW8(10,20,30)       - UVW8(4,5,6) == UVW8(6,15,24));
        static assert(RGBAf32(10,20,30,40) - RGBAf32(4,5,6,7) == RGBAf32(6,15,24,33));

        static assert(RGB8(10,20,30)       * RGB8(128,128,128) == RGB8(5,10,15));
        static assert(UVW8(10,20,30)       * UVW8(-64,-64,-64) == UVW8(-5,-10,-15));
        static assert(RGBAf32(10,20,30,40) * RGBAf32(0,1,2,3) == RGBAf32(0,20,60,120));
    }

    /** Binary operators. */
    typeof(this) opBinary(string op, S)(S rh) const if (isColorScalarType!S && (op == "*" || op == "/" || op == "%" || op == "^^"))
    {
        Unqual!(typeof(this)) res = this;
        foreach (c; AllComponents)
            mixin(ComponentExpression!("res._ #= rh;", c, op));
        return res;
    }
    ///
    unittest
    {
        static assert(RGB8(10,20,30)       * 2 == RGB8(20,40,60));
        static assert(UVW8(10,20,30)       * 2 == UVW8(20,40,60));
        static assert(RGBAf32(10,20,30,40) * 2 == RGBAf32(20,40,60,80));

        static assert(RGB8(10,20,30)       / 2 == RGB8(5,10,15));
        static assert(UVW8(-10,-20,-30)    / 2 == UVW8(-5,-10,-15));
        static assert(RGBAf32(10,20,30,40) / 2 == RGBAf32(5,10,15,20));

        static assert(RGB8(10,20,30)       * 2.0 == RGB8(20,40,60));
        static assert(UVW8(10,20,30)       * 2.0 == UVW8(20,40,60));
        static assert(RGBAf32(10,20,30,40) * 2.0 == RGBAf32(20,40,60,80));
        static assert(RGB8(10,20,30)       * 0.5 == RGB8(5,10,15));
        static assert(UVW8(-10,-20,-30)    * 0.5 == UVW8(-5,-10,-15));
        static assert(RGBAf32(5,10,15,20)  * 0.5 == RGBAf32(2.5,5,7.5,10));

        static assert(RGB8(10,20,30)       / 2.0 == RGB8(5,10,15));
        static assert(UVW8(-10,-20,-30)    / 2.0 == UVW8(-5,-10,-15));
        static assert(RGBAf32(10,20,30,40) / 2.0 == RGBAf32(5,10,15,20));
        static assert(RGB8(10,20,30)       / 0.5 == RGB8(20,40,60));
        static assert(UVW8(10,20,30)       / 0.5 == UVW8(20,40,60));
        static assert(RGBAf32(10,20,30,40) / 0.5 == RGBAf32(20,40,60,80));
    }

    /** Binary assignment operators. */
    ref typeof(this) opOpAssign(string op)(typeof(this) rh) if (op == "+" || op == "-" || op == "*")
    {
        foreach (c; AllComponents)
            mixin(ComponentExpression!("_ #= rh._;", c, op));
        return this;
    }

    /** Binary assignment operators. */
    ref typeof(this) opOpAssign(string op, S)(S rh) if (isColorScalarType!S && (op == "*" || op == "/" || op == "%" || op == "^^"))
    {
        foreach (c; AllComponents)
            mixin(ComponentExpression!("_ #= rh;", c, op));
        return this;
    }

package:

    alias ParentColor = XYZ!(FloatTypeFor!ComponentType);

    static To convertColorImpl(To, From)(From color) if (isRGB!From && isRGB!To)
    {
        alias ToType = To.ComponentType;
        alias FromType = From.ComponentType;

        auto src = color.tristimulusWithAlpha;

        static if (From.colorSpace == To.colorSpace && From.linear == To.linear)
        {
            // color space is the same, just do type conversion
            return To(cast(ToType)src[0], cast(ToType)src[1], cast(ToType)src[2], cast(ToType)src[3]);
        }
        else
        {
            // unpack the working values
            alias WorkType = WorkingType!(FromType, ToType);
            WorkType r = cast(WorkType)src[0];
            WorkType g = cast(WorkType)src[1];
            WorkType b = cast(WorkType)src[2];

            static if (From.linear == false)
            {
                r = toLinear!(From.colorSpace)(r);
                g = toLinear!(From.colorSpace)(g);
                b = toLinear!(From.colorSpace)(b);
            }
            static if (From.colorSpace != To.colorSpace)
            {
                enum toXYZ = rgbToXyzMatrix(From.colorSpaceDesc!WorkType);
                enum toRGB = xyzToRgbMatrix(To.colorSpaceDesc!WorkType);
                enum mat = multiply(toXYZ, toRGB);
                WorkType[3] v = multiply(mat, [r, g, b]);
                r = v[0]; g = v[1]; b = v[2];
            }
            static if (To.linear == false)
            {
                r = toGamma!(To.colorSpace)(r);
                g = toGamma!(To.colorSpace)(g);
                b = toGamma!(To.colorSpace)(b);
            }

            // convert and return the output
            static if (To.hasAlpha)
                return To(cast(ToType)r, cast(ToType)g, cast(ToType)b, cast(ToType)src[3]);
            else
                return To(cast(ToType)r, cast(ToType)g, cast(ToType)b);
        }
    }
    unittest
    {
        // test RGB format conversions
        alias UnsignedRGB = RGB!("rgb", ubyte);
        alias SignedRGBX = RGB!("rgbx", byte);
        alias FloatRGBA = RGB!("rgba", float);

        static assert(convertColorImpl!(UnsignedRGB)(SignedRGBX(0x20,0x30,-10)) == UnsignedRGB(0x40,0x60,0));
        static assert(convertColorImpl!(UnsignedRGB)(FloatRGBA(1,0.5,0,1)) == UnsignedRGB(0xFF,0x80,0));
        static assert(convertColorImpl!(FloatRGBA)(UnsignedRGB(0xFF,0x80,0)) == FloatRGBA(1,float(0x80)/float(0xFF),0,0));
        static assert(convertColorImpl!(FloatRGBA)(SignedRGBX(127,-127,-128)) == FloatRGBA(1,-1,-1,0));

        static assert(convertColorImpl!(UnsignedRGB)(convertColorImpl!(FloatRGBA)(UnsignedRGB(0xFF,0x80,0))) == UnsignedRGB(0xFF,0x80,0));

        // test greyscale conversion
        alias UnsignedL = RGB!("l", ubyte);
        static assert(cast(UnsignedL)UnsignedRGB(0xFF,0x20,0x40) == UnsignedL(82));

        // TODO: we can't test this properly since DMD can't CTFE the '^^' operator! >_<

        alias sRGBA = RGB!("rgba", ubyte, false, RGBColorSpace.sRGB);

        // test linear conversion
        alias lRGBA = RGB!("rgba", ushort, true, RGBColorSpace.sRGB);
        assert(convertColorImpl!(lRGBA)(sRGBA(0xFF, 0xFF, 0xFF, 0xFF)) == lRGBA(0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF));

        // test gamma conversion
        alias gRGBA = RGB!("rgba", byte, false, RGBColorSpace.sRGB_Gamma2_2);
        assert(convertColorImpl!(gRGBA)(sRGBA(0xFF, 0x80, 0x01, 0xFF)) == gRGBA(0x7F, 0x3F, 0x03, 0x7F));
    }

    static To convertColorImpl(To, From)(From color) if (isRGB!From && isXYZ!To)
    {
        alias ToType = To.ComponentType;
        alias FromType = From.ComponentType;
        alias WorkType = WorkingType!(FromType, ToType);

        // unpack the working values
        auto src = color.tristimulus;
        WorkType r = cast(WorkType)src[0];
        WorkType g = cast(WorkType)src[1];
        WorkType b = cast(WorkType)src[2];

        static if (From.linear == false)
        {
            r = toLinear!(From.colorSpace)(r);
            g = toLinear!(From.colorSpace)(g);
            b = toLinear!(From.colorSpace)(b);
        }

        // transform to XYZ
        enum toXYZ = rgbToXyzMatrix(From.colorSpaceDesc!WorkType);
        WorkType[3] v = multiply(toXYZ, [r, g, b]);
        return To(v[0], v[1], v[2]);
    }
    unittest
    {
        // TODO: needs approx ==
    }

    static To convertColorImpl(To, From)(From color) if (isXYZ!From && isRGB!To)
    {
        alias ToType = To.ComponentType;
        alias FromType = From.ComponentType;
        alias WorkType = WorkingType!(FromType, ToType);

        enum toRGB = xyzToRgbMatrix(To.colorSpaceDesc!WorkType);
        WorkType[3] v = multiply(toRGB, [ WorkType(color.X), WorkType(color.Y), WorkType(color.Z) ]);

        static if (To.linear == false)
        {
            v[0] = toGamma!(To.colorSpace)(v[0]);
            v[1] = toGamma!(To.colorSpace)(v[1]);
            v[2] = toGamma!(To.colorSpace)(v[2]);
        }

        return To(cast(ToType)v[0], cast(ToType)v[1], cast(ToType)v[2]);
    }
    unittest
    {
        // TODO: needs approx ==
    }

private:
    alias AllComponents = TypeTuple!("l","r","g","b","a");
}


/** Convert a value from gamma compressed space to linear. */
T toLinear(RGBColorSpace src, T)(T v) if (isFloatingPoint!T)
{
    enum ColorSpace = rgbColorSpaceDefs!T[src];
    return ColorSpace.toLinear(v);
}
/** Convert a value to gamma compressed space. */
T toGamma(RGBColorSpace src, T)(T v) if (isFloatingPoint!T)
{
    enum ColorSpace = rgbColorSpaceDefs!T[src];
    return ColorSpace.toGamma(v);
}

/** Convert a color to linear space. */
auto toLinear(C)(C color) if (isRGB!C)
{
    return cast(RGB!(C.components, C.ComponentType, true, C.colorSpace))color;
}
/** Convert a color to gamma space. */
auto toGamma(C)(C color) if (isRGB!C)
{
    return cast(RGB!(C.components, C.ComponentType, false, C.colorSpace))color;
}


package:

T toGrayscale(bool linear, RGBColorSpace colorSpace = RGBColorSpace.sRGB, T)(T r, T g, T b) pure if (isFloatingPoint!T)
{
    static if (linear)
    {
        // calculate the luminance (Y) value correctly by multiplying the Y row of the XYZ matrix with the color
        enum YAxis = rgbColorSpaceDef!T(colorSpace).rgbToXyzMatrix()[1];
        return YAxis[0]*r + YAxis[1]*g + YAxis[2]*b;
    }
    else static if (colorSpace == RGBColorSpace.Colorimetry ||
                   colorSpace == RGBColorSpace.SMPTE_C ||
                   colorSpace == RGBColorSpace.NTSC_J ||
                   colorSpace == RGBColorSpace.PAL_SECAM)
    {
        // For color spaces which are used in standard color TV and video systems such as PAL/SECAM, and
        // NTSC, a nonlinear luma component (Y') is calculated directly from gamma-compressed primary
        // intensities as a weighted sum, which can be calculated quickly without the gamma expansion and
        // compression used in colorimetric grayscale calculations.
        // The Rec.601 luma (Y') component is computed as:
        return T(0.299)*r + T(0.587)*g + T(0.114)*b;
    }
    else static if (colorSpace == RGBColorSpace.HDTV)
    {
        // The Rec.709 standard used for HDTV  uses different color coefficients.
        // These happen to be the same as sRGB, but applied to the gamma compressed signal direcetly.
        return T(0.2126)*r + T(0.7152)*g + T(0.0722)*b;
    }
    else
    {
        // Edge-case: What to do?! Approximate, or perform gamma conversions?
        // The TV standards have defined approximations, so let's continue to roll with that pattern.
        // We'll continue the Rec.709 pattern, except using appropriate coefficients for the color space.
        enum YAxis = rgbColorSpaceDef!T(colorSpace).rgbToXyzMatrix()[1];
        return YAxis[0]*r + YAxis[1]*g + YAxis[2]*b;
    }
}
T toGrayscale(bool linear, RGBColorSpace colorSpace = RGBColorSpace.sRGB, T)(T r, T g, T b) pure if (is(T == NormalizedInt!U, U))
{
    alias F = FloatTypeFor!T;
    return T(toGrayscale!(linear, colorSpace)(cast(F)r, cast(F)g, cast(F)b));
}


// helpers to parse color components from color component string
template canFind(string s, char c)
{
    static if (s.length == 0)
        enum canFind = false;
    else
        enum canFind = s[0] == c || canFind!(s[1..$], c);
}
template allIn(string s, string chars)
{
    static if (chars.length == 0)
        enum allIn = true;
    else
        enum allIn = canFind!(s, chars[0]) && allIn!(s, chars[1..$]);
}
template anyIn(string s, string chars)
{
    static if (chars.length == 0)
        enum anyIn = false;
    else
        enum anyIn = canFind!(s, chars[0]) || anyIn!(s, chars[1..$]);
}
template notIn(string s, string chars)
{
    static if (chars.length == 0)
        enum notIn = char(0);
    else static if (!canFind!(s, chars[0]))
        enum notIn = chars[0];
    else
        enum notIn = notIn!(s, chars[1..$]);
}

unittest
{
    static assert(canFind!("string", 'i'));
    static assert(!canFind!("string", 'x'));
    static assert(allIn!("string", "sgi"));
    static assert(!allIn!("string", "sgix"));
    static assert(anyIn!("string", "sx"));
    static assert(!anyIn!("string", "x"));
}
