// Written in the D programming language.

/**
This module implements the $(LINK2 https://en.wikipedia.org/wiki/Lab_color_space, CIE Lab) and
$(LINK2 https://en.wikipedia.org/wiki/Lab_color_space#Cylindrical_representation:__CIELCh_or_CIEHLC, LCh) _color types.

Lab is full-spectrum, absolute, vector _color space, with the specific goal of human perceptual uniformity.

Authors:    Manu Evans
Copyright:  Copyright (c) 2015, Manu Evans.
License:    $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0)
Source:     $(PHOBOSSRC std/experimental/color/_lab.d)
*/
module std.experimental.graphic.color.lab;

import std.experimental.graphic.color;
import std.experimental.graphic.color.xyz : XYZ, isXYZ;
import std.experimental.graphic.color.colorspace : WhitePoint;

import std.traits: isFloatingPoint, Unqual;
import std.typetuple: TypeTuple;
import std.math : sin, cos, sqrt, atan2, PI, M_1_PI;


@safe: pure: nothrow: @nogc:

/**
Detect whether $(D_INLINECODE T) is a L*a*b* color.
*/
enum isLab(T) = isInstanceOf!(Lab, T);

/**
Detect whether $(D_INLINECODE T) is an L*C*h° color.
*/
enum isLCh(T) = isInstanceOf!(LCh, T);


/**
A CIE L*a*b* color, parameterised for component type and white point.

Lab is a color space that describes all colors visible to the human eye and was created to serve as a device-independent model to be used as a reference.
L* represents the lightness of the color; L* = 0 yields black and L* = 100 indicates diffuse white, specular white may be higher.
a* represents the position between red/magenta and green; negative values indicate green while positive values indicate magenta.
b* represents the position between yellow and blue; negative values indicate blue and positive values indicate yellow.

Lab is often found using default white point D50, but it is also common to use D65 when interacting with sRGB images.
*/
struct Lab(F = float, alias whitePoint_ = (WhitePoint!F.D50)) if (isFloatingPoint!F)
{
@safe: pure: nothrow: @nogc:

    /** Type of the color components. */
    alias ComponentType = F;

    /** The color components that were specified. */
    enum whitePoint = whitePoint_;

    /** L* (lightness) component. */
    F L = 0;
    /** a* component. Negative values indicate green, positive values indicate magenta. */
    F a = 0;
    /** b* component. Negative values indicate blue, positive values indicate yellow. */
    F b = 0;

    /** Construct a color from L*a*b* values. */
    this(F L, F a, F b)
    {
        this.L = L;
        this.a = a;
        this.b = b;
    }

    /** Returns the perceptual distance between the specifies colors. */
    F perceptualDistance(G)(Lab!G c) const
    {
        alias WT = WorkingType!(F, G);
        return sqrt((WT(c.L) - WT(L))^^2 + (WT(c.a) - WT(a))^^2 + (WT(c.b) - WT(b))^^2);
    }

    /**
    Cast to other color types.

    This cast is a convenience which simply forwards the call to convertColor.
    */
    Color opCast(Color)() const if (isColor!Color)
    {
        return convertColor!Color(this);
    }

    /** Unary operators. */
    typeof(this) opUnary(string op)() const if (op == "+" || op == "-" || (op == "~" && is(ComponentType == NormalizedInt!U, U)))
    {
        Unqual!(typeof(this)) res = this;
        foreach (c; AllComponents)
            mixin(ComponentExpression!("res._ = #_;", c, op));
        return res;
    }
    /** Binary operators. */
    typeof(this) opBinary(string op)(typeof(this) rh) const if (op == "+" || op == "-" || op == "*")
    {
        Unqual!(typeof(this)) res = this;
        foreach (c; AllComponents)
            mixin(ComponentExpression!("res._ #= rh._;", c, op));
        return res;
    }
    /** Binary operators. */
    typeof(this) opBinary(string op, S)(S rh) const if (isColorScalarType!S && (op == "*" || op == "/" || op == "%" || op == "^^"))
    {
        Unqual!(typeof(this)) res = this;
        foreach (c; AllComponents)
            mixin(ComponentExpression!("res._ #= rh;", c, op));
        return res;
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

    alias ParentColor = XYZ!ComponentType;

    static To convertColorImpl(To, From)(From color) if (isLab!From && isLab!To)
    {
        static if (From.whitePoint == To.whitePoint)
        {
            // same whitepoint, just a format conversion
            return To(To.ComponentType(L), To.ComponentType(a), To.ComponentType(b));
        }
        else
        {
            // we'll need to pipe through XYZ to adjust the whitepoint
            auto xyz = cast(XYZ!(To.ComponentType))this;
            return cast(To)xyz;
        }
    }

    static To convertColorImpl(To, From)(From color) if (isLab!From && isXYZ!To)
    {
        alias WT = WorkingType!(From, To);

        enum w = cast(XYZ!WT)whitePoint;

        static WT f(WT v)
        {
            if (v > WT(0.206893))
                return v^^WT(3);
            else
                return (v - WT(16.0/116))*WT(1/7.787);
        }

        WT Y = (color.L + 16)*WT(1.0/116);
        WT X =  color.a*WT(1.0/500) + Y;
        WT Z = -color.b*WT(1.0/200) + Y;

        X = w.X * f(X);
        Y = w.Y * f(Y);
        Z = w.Z * f(Z);

        return To(X, Y, Z);
    }

    static To convertColorImpl(To, From)(From color) if (isXYZ!From && isLab!To)
    {
        alias WT = WorkingType!(From, To);

        enum w = cast(XYZ!WT)whitePoint;

        static WT f(WT v)
        {
            if (v > WT(0.008856))
                return v^^WT(1.0/3);
            else
                return WT(7.787)*v + WT(16.0/116);
        }

        WT X = f(color.X / w.X);
        WT Y = f(color.Y / w.Y);
        WT Z = f(color.Z / w.Z);

        return To(116*Y - 16, 500*(X - Y), 200*(Y - Z));
    }

private:
    alias AllComponents = TypeTuple!("L", "a", "b");
}


/**
A CIE L*C*h° color, parameterised for component type and white point.
The LCh color space is a Lab cube color space, where instead of cartesian coordinates a*, b*, the cylindrical coordinates C* (chroma) and h° (hue angle) are specified. The CIELab lightness L* remains unchanged.
*/
struct LCh(F = float, alias whitePoint_ = (WhitePoint!F.D50)) if (isFloatingPoint!F)
{
@safe: pure: nothrow: @nogc:

    /** Type of the color components. */
    alias ComponentType = F;

    /** The color components that were specified. */
    enum whitePoint = whitePoint_;

    /** L* (lightness) component. */
    F L = 0;
    /** C* (chroma) component. */
    F C = 0;
    /** h° (hue) component, in degrees. */
    F h = 0;

    /** Get hue angle in radians. */
    @property F radians() const
    {
        return h * F((1.0/180)*PI);
    }
    /** Set hue angle in radians. */
    @property void radians(F angle)
    {
        h = angle * F(M_1_PI*180);
    }

    /**
      Cast to other color types.

      This cast is a convenience which simply forwards the call to convertColor.
    */
    Color opCast(Color)() const if (isColor!Color)
    {
        return convertColor!Color(this);
    }


package:

    alias ParentColor = Lab!(F, whitePoint_);

    static To convertColorImpl(To, From)(From color) if (isLCh!From && isLCh!To)
    {
        static if (From.whitePoint == To.whitePoint)
        {
            // same whitepoint, just a format conversion
            return To(To.ComponentType(L), To.ComponentType(C), To.ComponentType(h));
        }
        else
        {
            // we'll need to pipe through XYZ to adjust the whitepoint
            auto xyz = cast(XYZ!(To.ComponentType))this;
            return cast(To)xyz;
        }
    }

    static To convertColorImpl(To, From)(From color) if (isLCh!From && isLab!To)
    {
        alias WT = WorkingType!(From, To);

        WT a = cos(color.h*WT(1.0/180*PI)) * color.C;
        WT b = sin(color.h*WT(1.0/180*PI)) * color.C;

        return To(color.L, a, b);
    }

    static To convertColorImpl(To, From)(From color) if (isLab!From && isLCh!To)
    {
        alias WT = WorkingType!(From, To);

        WT C = sqrt(color.a^^2 + color.b^^2);
        WT h = atan2(color.b, color.a);
        if (h >= 0)
            h = h*WT(M_1_PI*180);
        else
            h = 360 + h*WT(M_1_PI*180);

        return To(color.L, C, h);
    }
}


// HACK: workaround a compiler bug that failes to instantiate `NormalizedInt opEquals`
unittest
{
    import std.experimental.normint;
    NormalizedInt!(ushort) a;
}
