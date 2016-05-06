/**

Copyright 1987, 1998  The Open Group

Permission to use, copy, modify, distribute, and sell this software and its
documentation for any purpose is hereby granted without fee, provided that
the above copyright notice appear in all copies and that both that
copyright notice and this permission notice appear in supporting
documentation.

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
OPEN GROUP BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of The Open Group shall not be
used in advertising or otherwise to promote the sale, use or other dealings
in this Software without prior written authorization from The Open Group.


Copyright 1987 by Digital Equipment Corporation, Maynard, Massachusetts.

                        All Rights Reserved

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of Digital not be
used in advertising or publicity pertaining to distribution of the
software without specific, written prior permission.

DIGITAL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL
DIGITAL BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR
ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
SOFTWARE.

 */
module std.experimental.bindings.x11.Xutil;
import std.experimental.bindings.x11.X;
import std.experimental.bindings.x11.Xlib;
import std.experimental.bindings.x11.keysym;
import std.experimental.bindings.x11.keysymdef;
import std.experimental.bindings.x11.Xresource;
import core.stdc.config : c_long, c_ulong;
__gshared extern(C):

/**
 * Bitmask returned by XParseGeometry().  Each bit tells if the corresponding
 * value (x, y, width, height) was found in the parsed string.
 */
enum {
	///
	NoValue = 0x0000,
	///
	XValue = 0x0001,
	///
	YValue = 0x0002,
	///
	WidthValue = 0x0004,
	///
	HeightValue = 0x0008,
	///
	AllValues = 0x000F,
	///
	XNegative = 0x0010,
	///
	YNegative = 0x0020
}

/**
 * new version containing base_width, base_height, and win_gravity fields;
 * used with WM_NORMAL_HINTS.
 */
struct XSizeHints {
	/// marks which fields in this structure are defined
	c_long flags;
	/// obsolete for new window mgrs, but clients
	int x, y;
	/// should set so old wm's don't mess up
	int width, height;
	///
	int min_width, min_height;
	///
	int max_width, max_height;
	///
	int width_inc, height_inc;

	/// numerator
	struct Aspect {
		///
		int x;
		/// denominator
		int y;
	}
	///
	Aspect min_aspect, max_aspect;

	/// added by ICCCM version 1
	int base_width, base_height;
	/// added by ICCCM version 1
	int win_gravity;
}

/*
 * The next block of definitions are for window manager properties that
 * clients and applications use for communication.
 */

/// flags argument in size hints
enum {
	/// user specified x, y
	USPosition = 1 << 0,
	/// user specified width, height
	USSize = 1 << 1,

	/// program specified position
	PPosition = 1 << 2,
	/// program specified size
	PSize = 1 << 3,
	/// program specified minimum size
	PMinSize = 1 << 4,
	/// program specified maximum size
	PMaxSize = 1 << 5,
	/// program specified resize increments
	PResizeInc = 1 << 6,
	/// program specified min and max aspect ratios
	PAspect = 1 << 7,
	/// program specified base for incrementing
	PBaseSize = 1 << 8,
	/// program specified window gravity
	PWinGravity = 1 << 9,
}

/// obsolete
enum PAllHints = PPosition|PSize|PMinSize|PMaxSize|PResizeInc|PAspect;

///
struct XWMHints {
	/// marks which fields in this structure are defined
	c_long flags;
	/// does this application rely on the window manager to get keyboard input?
	Bool input;
	/// see below
	int initial_state;
	/// pixmap to be used as icon
	Pixmap icon_pixmap;
	/// window to be used as icon
	Window icon_window;
	/// initial position of icon
	int icon_x, icon_y;
	/// icon mask bitmap
	Pixmap icon_mask;
	/// id of related window group
	XID window_group;

	/* this structure may be extended in the future */
}

/// definition for flags of XWMHints
enum {
	///
	InputHint = 1 << 0,
	///
	StateHint = 1 << 1,
	///
	IconPixmapHint = 1 << 2,
	///
	IconWindowHint = 1 << 3,
	///
	IconPositionHint = 1 << 4,
	///
	IconMaskHint = 1 << 5,
	///
	WindowGroupHint = 1 << 6,
	///
	AllHints = InputHint|StateHint|IconPixmapHint|IconWindowHint|IconPositionHint|IconMaskHint|WindowGroupHint,
	///
	XUrgencyHint = 1 << 8
}

/// definitions for initial window state
enum {
	/// for windows that are not mapped
	WithdrawnState = 0,
	/// most applications want to start this way
	NormalState = 1,
	/// application wants to start as an icon
	IconicState = 3
}

/**
 * Obsolete states no longer defined by ICCCM
 */
enum {
	/// don't know or care
	DontCareState = 0,
	/// application wants to start zoomed
	ZoomState = 2,
	/**
	 * application believes it is seldom used;
	 * some wm's may put it on inactive menu
	 */
	InactiveState = 4,
}

/**
 * new structure for manipulating TEXT properties; used with WM_NAME,
 * WM_ICON_NAME, WM_CLIENT_MACHINE, and WM_COMMAND.
 */
struct XTextProperty {
	/// same as Property routines
	ubyte* value;
	/// prop type
	Atom encoding;
	/// prop data format: 8, 16, or 32
	int format;
	/// number of data items in value
	c_ulong nitems;
}

///
enum {
	///
	XNoMemory = -1,
	///
	XLocaleNotSupported = -2,
	///
	XConverterNotFound = -3
}

///
enum XICCEncodingStyle {
	/// STRING
	XStringStyle,
	/// COMPOUND_TEXT
	XCompoundTextStyle,
	/// text in owner's encoding (current locale)
	XTextStyle,
	/// STRING, else COMPOUND_TEXT
	XStdICCTextStyle,
	/**
	 * The following is an XFree86 extension, introduced in November 2000
	 * UTF8_STRING
	 */
	XUTF8StringStyle
}

///
struct XIconSize {
	///
	int min_width, min_height;
	///
	int max_width, max_height;
	///
	int width_inc, height_inc;
}

///
struct XClassHint {
	///
	char* res_name;
	///
	char* res_class;
}

///
version(XUTIL_DEFINE_FUNCTIONS) {
	///
	int function(XImage* ximage) XDestroyImage;
	///
	c_ulong function(XImage* ximage, int x, int y) XGetPixel;
	///
	int function(XImage* ximage, int x, int y, c_ulong pixel) XPutPixel;
	///
	XImage* function(XImage* ximage, int x, int y, uint width, uint height) XSubImage;
	///
	int function(XImage* ximage, c_long value) XAddPixel;

///
} else {
	/*
	 * These macros are used to give some sugar to the image routines so that
	 * naive people are more comfortable with them.
	 */

	///
	int XDestroyImage(XImage* ximage) { return ximage.f.destroy_image(ximage); }
	///
	c_ulong XGetPixel(XImage* ximage, int x, int y) { return ximage.f.get_pixel(ximage, x, y); } 
	///
	int XPutPixel(XImage* ximage, int x, int y, c_ulong pixel) { return ximage.f.put_pixel(ximage, x, y, pixel); }
	///
	XImage* XSubImage(XImage* ximage, int x, int y, uint width, uint height) { return ximage.f.sub_pixel(ximage, x, y, width, height); }
	///
	int XAddPixel(XImage* ximage, c_long value) { return ximage.f.add_pixel(ximage, value); }
}

/**
 * Compose sequence status structure, used in calling XLookupString.
 */
struct _XComposeStatus {
	/// state table pointer
	XPointer compose_ptr;
	/// match state
	int chars_matched;
}

///
alias XComposeStatus = _XComposeStatus;

/*
 * Keysym macros, used on Keysyms to test for classes of symbols
 */

///
bool IsKeypadKey(KeySym keysym) { return keysym >= XK_KP_Space && keysym <= XK_KP_Equal; }
///
bool IsPrivateKeypadKey(KeySym keysym) { return keysym >= 0x11000000 && keysym <= 0x1100FFFF; }
///
bool IsCursorKey(KeySym keysym) { return keysym >= XK_Home && keysym <= XK_Select; }
///
bool IsPFKey(KeySym keysym) { return keysym >= XK_KP_F1 && keysym <= XK_KP_F4; }
///
bool IsFunctionKey(KeySym keysym) { return keysym >= XK_F1 && keysym <= XK_F35; }
///
bool IsMiscFunctionKey(KeySym keysym) { return keysym >= XK_Select && keysym <= XK_Break; }

///
static if (XK_XKB_KEYS) {
	///
	bool IsModifierKey(KeySym keysym) { return (keysym >= XK_Shift_L && keysym <= XK_Hyper_R) || (keysym >= XK_ISO_Lock && keysym <= XK_ISO_Level5_Lock) || keysym == XK_Mode_switch || keysym == XK_Num_Lock; }
} else {
	///
	bool IsModifierKey(KeySym keysym) { return (keysym >= XK_Shift_L && keysym <= XK_Hyper_R) || keysym == XK_Mode_switch || keysym == XK_Num_Lock; }
}

/// opaque reference to Region data type
struct _XRegion;

///
alias Region = _XRegion*;

/// Return values from XRectInRegion()
enum {
	///
	RectangleOut = 0,
	///
	RectangleIn = 1,
	///
	RectanglePart = 2
}

/**
 * Information used by the visual utility routines to find desired visual
 * type from the many visuals a display may support.
 */
struct XVisualInfo {
	///
	Visual* visual;
	///
	VisualID visualid;
	///
	int screen;
	///
	int depth;
	///
	int c_class;
	///
	c_ulong red_mask;
	///
	c_ulong green_mask;
	///
	c_ulong blue_mask;
	///
	int colormap_size;
	///
	int bits_per_rgb;
}

///
enum {
	///
	VisualNoMask = 0x0,
	///
	VisualIDMask = 0x1,
	///
	VisualScreenMask = 0x2,
	///
	VisualDepthMask = 0x4,
	///
	VisualClassMask = 0x8,
	///
	VisualRedMaskMask = 0x10,
	///
	VisualGreenMaskMask = 0x20,
	///
	VisualBlueMaskMask = 0x40,
	///
	VisualColormapSizeMask = 0x80,
	///
	VisualBitsPerRGBMask = 0x100,
	///
	VisualAllMask = 0x1FF
}

/**
 * This defines a window manager property that clients may use to
 * share standard color maps of type RGB_COLOR_MAP:
 */
struct XStandardColormap {
	///
	Colormap colormap;
	///
	c_ulong red_max;
	///
	c_ulong red_mult;
	///
	c_ulong green_max;
	///
	c_ulong green_mult;
	///
	c_ulong blue_max;
	///
	c_ulong blue_mult;
	///
	c_ulong base_pixel;
	/// added by ICCCM version 1
	VisualID visualid;
	/// added by ICCCM version 1
	XID killid;
}

/// for killid field above
enum ReleaseByFreeingColormap = cast(XID)1;


/// return codes for XReadBitmapFile and XWriteBitmapFile
enum {
	///
	BitmapSuccess = 0,
	///
	BitmapOpenFailed = 1,
	///
	BitmapFileInvalid = 2,
	///
	BitmapNoMemory = 3
}

/****************************************************************
 *
 * Context Management
 *
 ****************************************************************/


// Associative lookup table return codes
enum {
	/// No error.
	XCSUCCESS = 0,
	/// Out of memory
	XCNOMEM = 1,
	/// No entry in table
	XCNOENT = 2
}

///
alias XContext = int;

///
XContext XUniqueContext() { return cast(XContext)XrmUniqueQuark(); }
///
XContext XStringToContext(const char* string_) { return cast(XContext)XrmStringToQuark(string_); }

/* The following declarations are alphabetized. */

///
XClassHint* function() XAllocClassHint;
///
XIconSize* function() XAllocIconSize;
///
XSizeHints* function() XAllocSizeHints;
///
XStandardColormap* function() XAllocStandardColormap;
///
XWMHints* function() XAllocWMHints;
///
int function(Region r, XRectangle* rect_return) XClipBox;
///
Region function() XCreateRegion;
///
const char* function() XDefaultString;
///
int function(Display* display, XID rid, XContext context) XDeleteContext;
///
int function(Region r) XDestroyRegion;
///
int function(Region r) XEmptyRegion;
///
int function(Region r1, Region r2) XEqualRegion;
///
int function(Display* display, XID rid, XContext context, XPointer* data_return) XFindContext;
///
Status function(Display* display, Window w, XClassHint* class_hints_return) XGetClassHint;
///
Status function(Display* display, Window w, XIconSize** size_list_return, int* count_return) XGetIconSizes;
///
Status function(Display* display, Window w, XSizeHints* hints_return) XGetNormalHints;
///
Status function(Display* display, Window w, XStandardColormap** stdcmap_return, int* count_return, Atom property) XGetRGBColormaps;
///
Status function(Display* display, Window w, XSizeHints* hints_return, Atom property) XGetSizeHints;
///
Status function(Display* display, Window w, XStandardColormap* colormap_return, Atom property) XGetStandardColormap;
///
Status function(Display* display, Window window, XTextProperty* text_prop_return, Atom property) XGetTextProperty;
///
XVisualInfo* function(Display* display, c_long vinfo_mask, XVisualInfo* vinfo_template, int*  nitems_return) XGetVisualInfo;
///
Status function(Display* display, Window w, XTextProperty* text_prop_return) XGetWMClientMachine;
///
XWMHints* function(Display* display, Window w) XGetWMHints;
///
Status function(Display* display, Window w, XTextProperty* text_prop_return) XGetWMIconName;
///
Status function(Display* display, Window w, XTextProperty* text_prop_return) XGetWMName;
///
Status function(Display* display, Window w, XSizeHints* hints_return, c_long* supplied_return) XGetWMNormalHints;
///
Status function(Display* display, Window w, XSizeHints* hints_return, c_long* supplied_return, Atom property) XGetWMSizeHints;
///
Status function(Display* display, Window w, XSizeHints* zhints_return) XGetZoomHints;
///
int function(Region sra, Region srb, Region dr_return) XIntersectRegion;
///
void function(KeySym sym, KeySym* lower, KeySym* upper) XConvertCase;
///
int function(XKeyEvent* event_struct, char* buffer_return, int bytes_buffer, KeySym* keysym_return, XComposeStatus* status_in_out) XLookupString;
///
Status function(Display* display, int screen, int depth, int class_, XVisualInfo* vinfo_return) XMatchVisualInfo;
///
int function(Region r, int dx, int dy) XOffsetRegion;
///
Bool function(Region r, int x, int y) XPointInRegion;
///
Region function(XPoint* points, int n, int fill_rule) XPolygonRegion;
///
int function(Region r, int x, int y, uint width, uint height) XRectInRegion;
///
int function(Display* display, XID rid, XContext context, const char* data) XSaveContext;
///
int function(Display* display, Window w, XClassHint* class_hints) XSetClassHint;
///
int function(Display* display, Window w, XIconSize* size_list, int count) XSetIconSizes;
///
int function(Display* display, Window w, XSizeHints* hints) XSetNormalHints;
///
void function(Display* display, Window w, XStandardColormap* stdcmaps, int count, Atom property) XSetRGBColormaps;
///
int function(Display* display, Window w, XSizeHints* hints, Atom property) XSetSizeHints;
///
int function(Display* display, Window w, const char* window_name, const char* icon_name, Pixmap icon_pixmap, char** argv, int argc, XSizeHints* hints) XSetStandardProperties;
///
void function(Display* display, Window w, XTextProperty* text_prop, Atom property) XSetTextProperty;
///
void function(Display* display, Window w, XTextProperty* text_prop) XSetWMClientMachine;
///
int function(Display* display, Window w, XWMHints* wm_hints) XSetWMHints;
///
void function(Display* display, Window w, XTextProperty* text_prop) XSetWMIconName;
///
void function(Display* display, Window w, XTextProperty* text_prop) XSetWMName;
///
void function(Display* display, Window w, XSizeHints* hints) XSetWMNormalHints;
///
void function(Display* display, Window w, XTextProperty* window_name, XTextProperty* icon_name, char** argv, int argc, XSizeHints* normal_hints, XWMHints* wm_hints, XClassHint* class_hints) XSetWMProperties;
///
void function(Display* display, Window w, const char* window_name, const char* icon_name, char** argv, int argc, XSizeHints* normal_hints, XWMHints* wm_hints, XClassHint* class_hints) XmbSetWMProperties;
///
void function(Display* display, Window w, const char* window_name, const char* icon_name, char** argv, int argc, XSizeHints* normal_hints, XWMHints* wm_hints, XClassHint* class_hints) Xutf8SetWMProperties;
///
void function(Display* display, Window w, XSizeHints* hints, Atom property) XSetWMSizeHints;
///
int function(Display* display, GC gc, Region r) XSetRegion;
///
void function(Display* display, Window w, XStandardColormap* colormap, Atom property) XSetStandardColormap;
///
int function(Display* display, Window w, XSizeHints* zhints) XSetZoomHints;
///
int function(Region r, int dx, int dy) XShrinkRegion;
///
Status function(char** list, int count, XTextProperty* text_prop_return) XStringListToTextProperty;
///
int function(Region sra, Region srb, Region dr_return) XSubtractRegion;
///
int function(Display* display, char** list, int count, XICCEncodingStyle style, XTextProperty* text_prop_return) XmbTextListToTextProperty;
///
int function(Display* display, wchar_t** list, int count, XICCEncodingStyle style, XTextProperty* text_prop_return) XwcTextListToTextProperty;
///
int function(Display* display, char** list, int count, XICCEncodingStyle style, XTextProperty* text_prop_return) Xutf8TextListToTextProperty;
///
void function(wchar_t** list) XwcFreeStringList;
///
Status function(XTextProperty* text_prop, char*** list_return, int* count_return) XTextPropertyToStringList;
///
int function(Display* display, const XTextProperty* text_prop, char*** list_return, int* count_return) XmbTextPropertyToTextList;
///
int function(Display* display, const XTextProperty* text_prop, wchar_t*** list_return, int* count_return) XwcTextPropertyToTextList;
///
int function(Display* display, const XTextProperty* text_prop, char*** list_return, int* count_return) Xutf8TextPropertyToTextList;
///
int function(XRectangle* rectangle, Region src_region, Region dest_region_return) XUnionRectWithRegion;
///
int function(Region sra, Region srb, Region dr_return) XUnionRegion;
///
int function(Display* display, int screen_number, const char* user_geometry, const char* default_geometry, uint border_width, XSizeHints* hints, int* x_return, int* y_return, int* width_return, int* height_return, int* gravity_return) XWMGeometry;
///
int function(Region sra, Region srb, Region dr_return) XXorRegion;
