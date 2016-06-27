/**
 * License:
 *     Copyright © 2000 SuSE, Inc.
 * 
 *     Permission to use, copy, modify, distribute, and sell this software and its
 *     documentation for any purpose is hereby granted without fee, provided that
 *     the above copyright notice appear in all copies and that both that
 *     copyright notice and this permission notice appear in supporting
 *     documentation, and that the name of SuSE not be used in advertising or
 *     publicity pertaining to distribution of the software without specific,
 *     written prior permission.  SuSE makes no representations about the
 *     suitability of this software for any purpose.  It is provided "as is"
 *     without express or implied warranty.
 *
 *     SuSE DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
 *     IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL SuSE
 *     BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *     WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 *     OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 *     CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * Authors:
 *     Keith Packard, SuSE, Inc.
 */
module std.experimental.bindings.x11.extensions.Xrender;
import std.experimental.bindings.x11.X;
import std.experimental.bindings.x11.Xlib;
import std.experimental.bindings.x11.Xutil;
import std.experimental.bindings.x11.extensions.render;
import core.stdc.config : c_long, c_ulong;
__gshared extern(C):

///
struct XRenderDirectFormat {
	///
	short red;
	///
	short redMask;
	///
	short green;
	///
	short greenMask;
	///
	short blue;
	///
	short blueMask;
	///
	short alpha;
	///
	short alphaMask;
}

///
struct XRenderPictFormat {
	///
	PictFormat id;
	///
	int type;
	///
	int depth;
	///
	XRenderDirectFormat direct;
	///
	Colormap colormap;
}

///
enum {
	///
	PictFormatID = 1 << 0,
	///
	PictFormatType = 1 << 1,
	///
	PictFormatDepth = 1 << 2,
	///
	PictFormatRed = 1 << 3,
	///
	PictFormatRedMask = 1 << 4,
	///
	PictFormatGreen = 1 << 5,
	///
	PictFormatGreenMask = 1 << 6,
	///
	PictFormatBlue = 1 << 7,
	///
	PictFormatBlueMask = 1 << 8,
	///
	PictFormatAlpha = 1 << 9,
	///
	PictFormatAlphaMask = 1 << 10,
	///
	PictFormatColormap = 1 << 11
}

///
struct _XRenderPictureAttributes {
	///
	int repeat;
	///
	Picture alpha_map;
	///
	int alpha_x_origin;
	///
	int alpha_y_origin;
	///
	int clip_x_origin;
	///
	int clip_y_origin;
	///
	Pixmap clip_mask;
	///
	Bool graphics_exposures;
	///
	int subwindow_mode;
	///
	int poly_edge;
	///
	int poly_mode;
	///
	Atom dither;
	///
	Bool component_alpha;
}

///
alias XRenderPictureAttributes = _XRenderPictureAttributes;

///
struct XRenderColor {
	///
	ushort red;
	///
	ushort green;
	///
	ushort blue;
	///
	ushort alpha;
}

///
struct _XGlyphInfo {
	///
	ushort width;
	///
	ushort height;
	///
	short x;
	///
	short y;
	///
	short xOff;
	///
	short yOff;
}

///
alias XGlyphInfo = _XGlyphInfo;

///
struct _XGlyphElt8 {
	///
	GlyphSet glyphset;
	///
	const char* chars;
	///
	int nchars;
	///
	int xOff;
	///
	int yOff;
}

///
alias XGlyphElt8 = _XGlyphElt8;

///
struct _XGlyphElt16 {
	///
	GlyphSet glyphset;
	///
	const wchar* chars;
	///
	int nchars;
	///
	int xOff;
	///
	int yOff;
}

///
alias XGlyphElt16 = _XGlyphElt16;

///
struct _XGlyphElt32 {
	///
	GlyphSet glyphset;
	///
	const dchar* chars;
	///
	int nchars;
	///
	int xOff;
	///
	int yOff;
}

///
alias XGlyphElt32 = _XGlyphElt32;

///
alias XDouble = double;

///
struct _XPointDouble {
	///
	XDouble x, y;
}

///
alias XPointDouble = _XPointDouble;

///
XFixed XDoubleToFixed(XDouble f) { return cast(XFixed)(f * 65536); }
///
XDouble XFixedToDouble(XFixed f) { return (cast(XDouble)f) / 65536; }

///
alias XFixed = int;

///
struct _XPointFixed {
	///
	XFixed x, y;
}

///
alias XPointFixed = _XPointFixed;

///
struct _XLineFixed {
	///
	XPointFixed p1, p2;
}

///
alias XLineFixed = _XLineFixed;

///
struct _XTriangle {
	///
	XPointFixed p1, p2, p3;
}

///
alias XTriangle = _XTriangle;

///
struct _XCircle {
	///
	XFixed x;
	///
	XFixed y;
	///
	XFixed radius;
}

///
alias XCircle = _XCircle;

///
struct _XTrapezoid {
	///
	XFixed top, bottom;
	///
	XLineFixed left, right;
}

///
alias XTrapezoid = _XTrapezoid;

///
struct _XTransform {
	///
	XFixed[3][3] matrix;
}

///
alias XTransform = _XTransform;

///
struct _XFilters {
	///
	int nfilter;
	///
	ubyte** filter;
	///
	int nalias;
	///
	short* alias_;
}

///
alias XFilters = _XFilters;

///
struct _XIndexValue {
	///
	c_ulong pixel;
	///
	ushort red, green, blue, alpha;
}

///
alias XIndexValue = _XIndexValue;

///
struct _XAnimCursor {
	///
	Cursor cursor;
	///
	c_ulong delay;
}

///
alias XAnimCursor = _XAnimCursor;

///
struct _XSpanFix {
	///
	XFixed left, right, y;
}

///
alias XSpanFix = _XSpanFix;

///
struct _XTrap {
	///
	XSpanFix top, bottom;
}

///
alias XTrap = _XTrap;

///
struct _XLinearGradient {
	///
	XPointFixed p1;
	///
	XPointFixed p2;
}

///
alias XLinearGradient = _XLinearGradient;

///
struct _XRadialGradient {
	///
	XCircle inner;
	///
	XCircle outer;
}

///
alias XRadialGradient = _XRadialGradient;

///
struct _XConicalGradient {
	///
	XPointFixed center;
	/// in degrees
	XFixed angle;
}

///
alias XConicalGradient = _XConicalGradient;

///
Bool XRenderQueryExtension(Display* dpy, int* event_basep, int* error_basep);
///
Status XRenderQueryVersion(Display* dpy, int* major_versionp, int* minor_versionp);
///
Status XRenderQueryFormats (Display* dpy);
///
int XRenderQuerySubpixelOrder (Display* dpy, int screen);
///
Bool XRenderSetSubpixelOrder (Display* dpy, int screen, int subpixel);
///
XRenderPictFormat* XRenderFindVisualFormat(Display* dpy, const Visual* visual);
///
XRenderPictFormat* XRenderFindFormat(Display* dpy, c_ulong mask, const XRenderPictFormat* templ, int count);

enum {
	PictStandardARGB32 = 0,
	PictStandardRGB24 = 1,
	PictStandardA8 = 2,
	PictStandardA4 = 3,
	PictStandardA1 = 4,
	PictStandardNUM = 5
}

///
XRenderPictFormat* function(Display* dpy, int format) XRenderFindStandardFormat;
///
XIndexValue* function(Display* dpy, const XRenderPictFormat* format, int* num) XRenderQueryPictIndexValues;
///
Picture function(Display* dpy, Drawable drawable, const XRenderPictFormat* format, c_ulong valuemask, const XRenderPictureAttributes* attributes) XRenderCreatePicture;
///
void function(Display* dpy, Picture picture, c_ulong valuemask, const XRenderPictureAttributes* attributes) XRenderChangePicture;
///
void function(Display* dpy, Picture picture, int xOrigin, int yOrigin, const XRectangle* rects, int n) XRenderSetPictureClipRectangles;
///
void function(Display* dpy, Picture picture, Region r) XRenderSetPictureClipRegion;
///
void function(Display* dpy, Picture picture, XTransform* transform) XRenderSetPictureTransform;
///
void function(Display* dpy, Picture picture) XRenderFreePicture;
///
void function(Display* dpy, int op, Picture src, Picture mask, Picture dst, int src_x, int src_y, int mask_x, int mask_y, int dst_x, int dst_y, uint width, uint height) XRenderComposite;
///
GlyphSet function(Display* dpy, const XRenderPictFormat* format) XRenderCreateGlyphSet;
///
GlyphSet function(Display* dpy, GlyphSet existing) XRenderReferenceGlyphSet;
///
void function(Display* dpy, GlyphSet glyphset) XRenderFreeGlyphSet;
///
void function(Display* dpy, GlyphSet glyphset, const Glyph* gids, const XGlyphInfo* glyphs, int nglyphs, const char* images, int nbyte_images) XRenderAddGlyphs;
///
void function(Display* dpy, GlyphSet glyphset, const Glyph* gids, int nglyphs) XRenderFreeGlyphs;
///
void function(Display* dpy, int op, Picture src, Picture dst, const XRenderPictFormat* maskFormat, GlyphSet glyphset, int xSrc, int ySrc, int xDst, int yDst, const char* string, int nchar) XRenderCompositeString8;
///
void function(Display* dpy, int op, Picture src, Picture dst, const XRenderPictFormat* maskFormat, GlyphSet glyphset, int xSrc, int ySrc, int xDst, int yDst, const wchar* string, int nchar) XRenderCompositeString16;
///
void function(Display* dpy, int op, Picture src, Picture dst, const XRenderPictFormat* maskFormat, GlyphSet glyphset, int xSrc, int ySrc, int xDst, int yDst, const dchar* string, int nchar) XRenderCompositeString32;
///
void function(Display* dpy, int op, Picture src, Picture dst,const XRenderPictFormat* maskFormat, int xSrc, int ySrc, int xDst, int yDst, const XGlyphElt8* elts, int nelt) XRenderCompositeText8;
///
void function(Display* dpy, int op, Picture src, Picture dst, const XRenderPictFormat* maskFormat, int xSrc, int ySrc, int xDst, int yDst, const XGlyphElt16* elts, int nelt) XRenderCompositeText16;
///
void function(Display* dpy, int op, Picture src, Picture dst, const XRenderPictFormat* maskFormat, int xSrc, int ySrc, int xDst, int yDst, const XGlyphElt32* elts, int nelt) XRenderCompositeText32;
///
void function(Display* dpy, int op, Picture dst, const XRenderColor* color, int x, int y, uint width, uint height) XRenderFillRectangle;
///
void function(Display* dpy, int op, Picture dst, const XRenderColor* color, const XRectangle* rectangles, int n_rects) XRenderFillRectangles;
///
void function(Display* dpy, int op, Picture src, Picture dst, const XRenderPictFormat* maskFormat, int xSrc, int ySrc, const XTrapezoid* traps, int ntrap) XRenderCompositeTrapezoids;
///
void function(Display* dpy, int op, Picture src, Picture dst, const XRenderPictFormat* maskFormat, int xSrc, int ySrc, const XTriangle* triangles, int ntriangle) XRenderCompositeTriangles;
///
void function(Display* dpy, int op, Picture src, Picture dst, const XRenderPictFormat* maskFormat, int xSrc, int ySrc, const XPointFixed* points, int npoint) XRenderCompositeTriStrip;
///
void function(Display* dpy, int op, Picture src, Picture dst, const XRenderPictFormat* maskFormat, int xSrc, int ySrc, const XPointFixed* points, int npoint) XRenderCompositeTriFan;
///
void function(Display* dpy, int op, Picture src, Picture dst, const XRenderPictFormat* maskFormat, int xSrc, int ySrc, int xDst, int yDst, const XPointDouble* fpoints, int npoints, int winding) XRenderCompositeDoublePoly;
///
Status function(Display* dpy, ubyte* spec, XRenderColor* def) XRenderParseColor;
///
Cursor function(Display* dpy, Picture source, uint x, uint y) XRenderCreateCursor;
///
XFilters* function(Display* dpy, Drawable drawable) XRenderQueryFilters;
///
void function(Display* dpy, Picture picture, const char* filter, XFixed* params, int nparams) XRenderSetPictureFilter;
///
Cursor function(Display* dpy, int ncursor, XAnimCursor* cursors) XRenderCreateAnimCursor;
///
void function(Display* dpy, Picture picture, int xOff, int yOff, const XTrap* traps, int ntrap) XRenderAddTraps;
///
Picture function(Display* dpy, const XRenderColor* color) XRenderCreateSolidFill;
///
Picture function(Display* dpy, const XLinearGradient* gradient, const XFixed* stops, const XRenderColor* colors, int nstops) XRenderCreateLinearGradient;
///
Picture function(Display* dpy, const XRadialGradient* gradient, const XFixed* stops, const XRenderColor* colors, int nstops) XRenderCreateRadialGradient;
///
Picture function(Display* dpy, const XConicalGradient* gradient, const XFixed* stops, const XRenderColor* colors, int nstops) XRenderCreateConicalGradient; 