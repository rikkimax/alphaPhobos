/**

 Copyright 1985, 1986, 1987, 1991, 1998  The Open Group

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

 */
module std.experimental.bindings.x11.Xlib;
import core.stdc.config : c_long, c_ulong;
__gshared extern(C):

///
enum XlibSpecificationRelease = 6;

import std.experimental.bindings.x11.X;

///
alias wchar_t = c_ulong;

///
alias wctomb = _Xwctomb;
///
alias mblen = _Xmblen;
///
alias mbtowc = _Xmbtowc;

///
int function(const char* str, size_t len) _Xmblen;

/**
 * API mentioning "UTF8" or "utf8" is an XFree86 extension, introduced in
 * November 2000. Its presence is indicated through the following macro.
 */
enum X_HAVE_UTF8_STRING = 1;

///
alias XPointer = void*;

///
alias Bool = int;
///
alias Status = int;
///
enum True = 1;
///
enum False = 0;

///
enum QueuedAlready = 0;
///
enum QueuedAfterReading = 1;
///
enum QueuedAfterFlush = 2;

///
auto ConnectionNumber(T)(T dpy) { return (cast(_XPrivDisplay)dpy).fd; }
///
auto RootWindow(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).root; }
///
auto DefaultScreen(T)(T dpy) { return (cast(_XPrivDisplay)dpy).default_screen; }
///
auto DefaultRootWindow(T)(T dpy) { return ScreenOfDisplay(dpy, DefaultScreen(dpy)).root; }
///
auto DefaultVisual(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).root_visual; }
///
auto DefaultGC(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).default_gc; }
///
auto BlackPixel(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).black_pixel; }
///
auto WhitePixel(T, U)(T dpy, U  scr) { return ScreenOfDisplay(dpy, scr).white_pixel; }
///
enum AllPlanes = 0;
///
auto QLength(T)(T dpy) { return (cast(_XPrivDisplay)dpy).qlen; }
///
auto DisplayWidth(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).width; }
///
auto DisplayHeight(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).height; }
///
auto DisplayWidthMM(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).mwidth; }
///
auto DisplayHeightMM(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).mheight; }
///
auto DisplayPlanes(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).root_depth; }
///
auto DisplayCells(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).map_entries; }
///
auto ScreenCount(T)(T dpy) { return (cast(_XPrivDisplay)dpy).nscreens; }
///
auto ServerVender(T)(T dpy) { return (cast(_XPrivDisplay)dpy).vender; }
///
auto ProtocolVersion(T)(T dpy) { return (cast(_XPrivDisplay)dpy).proto_major_version; }
///
auto ProtocolReversion(T)(T dpy) { return (cast(_XPrivDisplay)dpy).proto_minor_version; }
///
auto VendorRelease(T)(T dpy) { return (cast(_XPrivDisplay)dpy).release; }
///
auto DisplayString(T)(T dpy) { return (cast(_XPrivDisplay)dpy).display_name; }
///
auto DefaultDepth(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).root_depth; }
///
auto DefaultColormap(T, U)(T dpy, U scr) { return ScreenOfDisplay(dpy, scr).cmap; }
///
auto BitmapUnit(T)(T dpy) { return (cast(_XPrivDisplay)dpy).bitmap_unit; }
///
auto BitmapBitOrder(T)(T dpy) { return (cast(_XPrivDisplay)dpy).bitmap_bit_order; }
///
auto BitmapPad(T)(T dpy) { return (cast(_XPrivDisplay)dpy).bitmap_pad; }
///
auto ImageByteOrder(T)(T dpy) { return (cast(_XPrivDisplay)dpy).byte_order; }
///
auto NextRequest(T)(T dpy) { return (cast(_XPrivDisplay)dpy).request + 1; }
///
auto LastKnownRequestProcessed(T)(T dpy) { return (cast(_XPrivDisplay)dpy).last_request_read; }

/* macros for screen oriented applications (toolkit) */

///
auto ScreenOfDisplay(T, U)(T dpy, U scr) { return &(cast(_XPrivDisplay)dpy).screens[scr]; }
///
auto DefaultScreenOfDisplay(T)(T dpy) { return ScreenOfDisplay(dpy, DefaultScreen(dpy)); }
///
auto DisplayOfScreen(T)(T s) { return s.display; }
///
auto RootWindowOfScreen(T)(T s) { return s.root; }
///
auto BlackPixelOfScreen(T)(T s) { return s.black_pixel; }
///
auto WhitePixelOfScreen(T)(T s) { return s.white_pixel; }
///
auto DefaultColormapOfScreen(T)(T s) { return s.cmap; }
///
auto DefaultDepthOfScreen(T)(T s) { return s.root_depth; }
///
auto DefaultGCOfScreen(T)(T s) { return s.default_gc; }
///
auto DefaultVisualOfScreen(T)(T s) { return s.root_visual; }
///
auto WidthOfScreen(T)(T s) { return s.width; }
///
auto HeightOfScreen(T)(T s) { return s.height; }
///
auto WidthMMOfScreen(T)(T s) { return s.mwidth; }
///
auto HeightMMOfScreen(T)(T s) { return s.mheight; }
///
auto PlanesOfScreen(T)(T s) { return s.root_depth; }
///
auto CellsOfScreen(T)(T s) { return DefaultVisualOfScreen(s).map_entries; }
///
auto MinCmapsOfScreen(T)(T s) { return s.min_maps; }
///
auto MaxCmapsOfScreen(T)(T s) { return s.max_maps; }
///
auto DoesSaveUnders(T)(T s) { return s.save_unders; }
///
auto DoesBackingStore(T)(T s) { return s.backing_store; }
///
auto EventMaskOfScreen(T)(T s) { return s.root_input_mask; }

/// Extensions need a way to hang private data on some structures
struct _XExtData {
	/// number returned by XRegisterExtension
	int number;
	/// next item on list of data for structure
	_XExtData* next;
	/// called to free private storage
	extern(C) int function(_XExtData* extension) free_private;
	/// data private to this extension
	XPointer private_data;
}

///
alias XExtData = _XExtData;

/// This file contains structures used by the extension mechanism
/// public to extension, cannot be changed
struct XExtCodes {
	/// extension number
	int extension;
	/// major op-code assigned by server
	int major_opcode;
	/// first event number for the extension
	int first_event;
	/// first error number for the extension
	int first_error;
}

/// Data structure for retrieving info about pixmap formats.
struct XPixmapFormatValues {
	///
	int depth;
	///
	int bits_per_pixel;
	///
	int scanline_pad;
}

/// Data structure for setting graphics context.
struct XGCValues {
	/// logical operation
	int function_;
	/// plane mask
	c_ulong plane_mask;
	/// foreground pixel
	c_ulong foreground;
	/// background pixel
	c_ulong background;
	/// line width
	int line_width;
	/// LineSolid, LineOnOffDash, LineDoubleDash
	int line_style;
	/// CapNotLast, CapButt, CapRound, CapProjecting
	int cap_style;
	/// JoinMiter, JoinRound, JoinBevel
	int join_style;
	/// FillSolid, FillTiled, FillStippled, FillOpaeueStippled
	int fill_style;
	/// EvenOddRule, WindingRule
	int fill_rule;
	/// ArcChord, ArcPieSlice
	int arc_mode;
	/// tile pixmap for tiling operations
	Pixmap tile;
	/// stipple 1 plane pixmap for stipping
	Pixmap stipple;
	/// offset for tile or stipple operations
	int ts_x_origin;
	/// offset for tile or stipple operations
	int ts_y_origin;
	/// default text font for text operations
	Font font;
	/// ClipByChildren, IncludeInferiors
	int subwindow_mode;
	/// boolean, should exposures be generated
	Bool graphics_exposures;
	/// origin for clipping
	int clip_x_origin;
	/// origin for clipping
	int clip_y_origin;
	/// bitmap clipping; other calls for rects
	Pixmap clip_mask;
	/// patterned/dashed line information
	int dash_offset;
	/// patterned/dashed line information
	char dashes;
}

version(XLIB_ILLEGAL_ACCESS) {
	/**
	 * Graphics context.  The contents of this structure are implementation
	 * dependent.  A GC should be treated as opaque by application code.
	 */
	struct _XGC {
		/// hook for extension to hang data
		XExtData* ext_data;
		/// protocol ID for graphics context
		GContext gid;
		/* there is more to this structure, but it is private to Xlib */
	}
} else {
	/**
	 * Graphics context.  The contents of this structure are implementation
	 * dependent.  A GC should be treated as opaque by application code.
	 */
	struct _XGC;
}

///
alias GC = _XGC*;

/// Visual structure; contains information about colormapping possible.
struct Visual {
	/// hook for extension to hang data
	XExtData* ext_data;
	/// visual id of this visual
	VisualID visualid;
	/// C++ class of screen (monochrome, etc.)
	int c_class;
	/// mask values
	c_ulong red_mask, green_mask, blue_mask;
	/// log base 2 of distinct color values
	int bits_per_rgb;
	/// color map entries
	int map_entries;
}

/// Depth structure; contains information for each possible depth.
struct Depth {
	/// this depth (Z) of the depth
	int depth;
	/// number of Visual types at this depth
	int nvisuals;
	/// list of visuals possible at this depth
	Visual* visuals;
}

/**
 * Information about the screen.  The contents of this structure are
 * implementation dependent.  A Screen should be treated as opaque
 * by application code.
 */
struct Screen {
	/// hook for extension to hang data
	XExtData* ext_data;
	/// back pointer to display structure
	_XDisplay* display;
	/// Root window id.
	Window root;
	/// width and height of screen
	int width, height;
	/// width and height of  in millimeters
	int mwidth, mheight;
	/// number of depths possible
	int ndepths;
	/// list of allowable depths on the screen
	Depth* depths;
	/// bits per pixel
	int root_depth;
	/// root visual
	Visual* root_visual;
	/// GC for the root root visual
	GC default_gc;
	/// default color map
	Colormap cmap;
	/// White and Black pixel values
	c_ulong white_pixel;
	/// White and Black pixel values
	c_ulong black_pixel;
	/// max and min color maps
	int max_maps, min_maps;
	/// Never, WhenMapped, Always
	int backing_store;
	///
	Bool save_unders;
	/// initial root input mask
	long root_input_mask;
}

/// Format structure; describes ZFormat data the screen will understand.
struct ScreenFormat {
	/// hook for extension to hang data
	XExtData *ext_data;
	/// depth of this image format
	int depth;
	/// bits/pixel at this depth
	int bits_per_pixel;
	/// scanline must padded to this multiple
	int scanline_pad;
}

/*
 * Data structure for setting window attributes.
 */

///
struct XSetWindowAttributes {
	/// background or None or ParentRelative
	Pixmap background_pixmap;
	/// background pixel
	c_ulong background_pixel;
	/// border of the window
	Pixmap border_pixmap;
	/// border pixel value
	c_ulong border_pixel;
	/// one of bit gravity values
	int bit_gravity;
	/// one of the window gravity values
	int win_gravity;
	/// NotUseful, WhenMapped, Always
	int backing_store;
	/// planes to be preseved if possible
	c_ulong backing_planes;
	/// value to use in restoring planes
	c_ulong backing_pixel;
	/// should bits under be saved? (popups)
	Bool save_under;
	/// set of events that should be saved
	c_long event_mask;
	/// set of events that should not propagate
	c_long do_not_propagate_mask;
	/// boolean value for override-redirect
	Bool override_redirect;
	/// color map to be associated with window
	Colormap colormap;
	/// cursor to be displayed (or None)
	Cursor cursor;
}

///
struct XWindowAttributes {
	/// location of window
	int x, y;
	/// width and height of window
	int width, height;
	/// border width of window
	int border_width;
	/// depth of window
	int depth;
	/// the associated visual structure
	Visual* visual;
	/// root of screen containing window
	Window root;
	/// C++ InputOutput, InputOnly
	int c_class;
	/// one of bit gravity values
	int bit_gravity;
	/// one of the window gravity values
	int win_gravity;
	/// NotUseful, WhenMapped, Always
	int backing_store;
	/// planes to be preserved if possible
	c_ulong backing_planes;
	/// value to be used when restoring planes
	c_ulong backing_pixel;
	/// boolean, should bits under be saved?
	Bool save_under;
	/// color map to be associated with window
	Colormap colormap;
	/// boolean, is color map currently installed
	Bool map_installed;
	/// IsUnmapped, IsUnviewable, IsViewable
	int map_state;
	/// set of events all people have interest in
	c_long all_event_masks;
	/// my event mask
	c_long your_event_mask;
	/// set of events that should not propagate
	c_long do_not_propagate_mask;
	/// boolean value for override-redirect
	Bool override_redirect;
	/// back pointer to correct screen
	Screen* screen;
}

/// Data structure for host setting; getting routines.
struct XHostAddress {
	/// for example FamilyInternet
	int family;
	/// length of address, in bytes
	int length;
	/// pointer to where to find the bytes
	char* address;
}

/// Data structure for ServerFamilyInterpreted addresses in host routines
struct XServerInterpretedAdddress {
	/// length of type string, in bytes
	int typelength;
	/// length of value string, in bytes
	int valuelength;
	/// pointer to where to find the type string
	char* type;
	/// pointer to where to find the address
	char* value;
}

/// Data structure for "image" data, used by image manipulation routines.
struct _XImage {
	/// size of image
	int width, height;
	/// number of pixels offset in X direction
	int xoffset;
	/// XYBitmap, XYPixmap, ZPixmap
	int format;
	/// pointer to image data
	char* data;
	/// data byte order, LSBFirst, MSBFirst
	int byte_order;
	/// quant. of scanline 8, 16, 32
	int bitmap_unit;
	/// LSBFirst, MSBFirst
	int bitmap_bit_order;
	/// 8, 16, 32 either XY or ZPixmap
	int bitmap_pad;
	/// depth of image
	int depth;
	/// accelarator to next line
	int bytes_per_line;
	/// bits per pixel (ZPixmap)
	int bits_per_pixel;
	/// bits in z arrangment
	c_ulong red_mask;
	/// bits in z arrangment
	c_ulong green_mask;
	/// bits in z arrangment
	c_ulong blue_mask;
	/// hook for the object routines to hang on
	XPointer obdata;
	
	/// image manipulation routines
	struct funcs {
		///
		_XImage function(
			_XDisplay* display, Visual* visual,
			uint depth, int format, int offset,
			char* data, uint width, uint height,
			int bitmap_pad, int bytes_per_line) create_image;
		///
		int function(_XImage*) destroy_image;
		///
		c_ulong function(_XImage *, int, int) get_pixel;
		///
		int function(_XImage *, int, int, c_ulong) put_pixel;
		///
		_XImage* function(_XImage *, int, int, uint, uint) sub_pixel;
		///
		int function(_XImage *, c_long) add_pixel;
	}
	///
	funcs f;
}

///
alias XImage = _XImage;

/// Data structure for XReconfigureWindow
struct XWindowChanges {
	///
	int x, y;
	///
	int width, height;
	///
	int border_width;
	///
	Window sibling;
	///
	int stack_mode;
}

/// Data structure used by color operations
struct XColor {
	///
	c_ulong pixel;
	///
	ushort red, green, blue;
	/// do_red, do_green, do_blue
	ubyte flags;
	///
	ubyte pad;
}

/*
 * Data structures for graphics operations.  On most machines, these are
 * congruent with the wire protocol structures, so reformatting the data
 * can be avoided on these architectures.
 */

///
struct XSegment {
	///
	short x1, y1, x2, y2;
}

///
struct XPoint {
	///
	short x, y;
}

///
struct XRectangle {
	///
	short x, y;
	///
	ushort width, height;
}

///
struct XArc {
	///
	short x, y;
	///
	ushort width, height;
	///
	short angle1, angle2;
}

/// Data structure for XChangeKeyboardControl
struct XKeyboardControl {
	///
	int key_click_percent;
	///
	int bell_percent;
	///
	int bell_pitch;
	///
	int bell_duration;
	///
	int led;
	///
	int led_mode;
	///
	int key;
	/// On, Off, Default
	int auto_repeat_mode;
}

/// Data structure for XGetKeyboardControl
struct XKeyboardState {
	///
	int key_click_percent;
	///
	int bell_percent;
	///
	uint bell_pitch, bell_duration;
	///
	c_ulong led_mask;
	///
	int global_auto_repeat;
	///
	char[32] auto_repeats;
}

/// Data structure for XGetMotionEvents.
struct XTimeCoord {
	///
	Time time;
	///
	short x, y;
}

/// Data structure for X{Set,Get}ModifierMapping
struct XModifierKeymap {
	/// The server's max # of keys per modifier
	int max_keypermod;
	/// An 8 by max_keypermod array of modifiers
	KeyCode* modifiermap;
}

struct _XPrivate;
struct _XrmHashBucketRec;

///
struct _XPrivDisplay_T {
	/// hook for extension to hang data
	XExtData* ext_data;
	/// 
	_XPrivate* private1;
	/// Network socket.
	int fd;
	///
	int private2;
	/// major version of server's X protocol
	int proto_major_version;
	/// minor version of servers X protocol
	int proto_minor_version;
	/// vendor of the server hardware
	char *vendor;
	///
	XID private3;
	///
	XID private4;
	///
	XID private5;
	///
	int private6;
	/// allocator function
	XID function(_XDisplay*) resource_alloc;
	/// screen byte order, LSBFirst, MSBFirst
	int byte_order;
	/// padding and data requirements
	int bitmap_unit;
	/// padding requirements on bitmaps
	int bitmap_pad;
	/// LeastSignificant or MostSignificant
	int bitmap_bit_order;
	/// number of pixmap formats in list
	int nformats;
	/// pixmap format list
	ScreenFormat* pixmap_format;
	///
	int private8;
	/// release of the server
	int release;
	///
	_XPrivate* private9, private10;
	/// Length of input event queue
	int qlen;
	/// seq number of last event read
	c_ulong last_request_read;
	/// sequence number of last request.
	c_ulong request;
	///
	XPointer private11;
	///
	XPointer private12;
	///
	XPointer private13;
	///
	XPointer private14;
	/// maximum number 32 bit words in request
	uint max_request_size;
	///
	_XrmHashBucketRec* db;
	///
	int function(_XDisplay*) private15;
	/// "host:display" string used on this connect
	char* display_name;
	/// default screen for operations
	int default_screen;
	/// number of screens on this server
	int nscreens;
	/// pointer to list of screens
	Screen* screens;
	/// size of motion buffer
	c_ulong motion_buffer;
	/// 
	c_ulong private16;
	/// minimum defined keycode
	int min_keycode;
	/// maximum defined keycode
	int max_keycode;
	/// 
	XPointer private17;
	/// 
	XPointer private18;
	/// 
	int private19;
	/// contents of defaults from server
	char* xdefaults;
	/* there is more to this structure, but it is private to Xlib */
}

///
alias _XPrivDisplay = _XPrivDisplay_T*;

version(XLIB_ILLEGAL_ACCESS) {
	///
	alias _XDisplay = _XPrivDisplay_T;
} else {
	/// Bug: needs to have a size so 0 will do instead of opaque.
	struct _XDisplay {}
}

///
alias Display = _XDisplay;

/// Definitions of specific events.
struct XKeyEvent {
	/// of event
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// "event" window it is reported relative to
	Window window;
	/// root window that the event occurred on
	Window root;
	/// child window
	Window subwindow;
	/// milliseconds
	Time time;
	/// pointer x, y coordinates in event window
	int x, y;
	/// coordinates relative to root
	int x_root, y_root;
	/// key or button mask
	uint state;
	/// detail
	uint keycode;
	/// same screen flag
	Bool same_screen;
}

///
alias XKeyPressedEvent = XKeyEvent;
///
alias XKeyReleasedEvent = XKeyEvent;

///
struct XButtonEvent {
	/// of event
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// "event" window it is reported relative to
	Window window;
	/// root window that the event occurred on
	Window root;
	/// child window
	Window subwindow;
	/// milliseconds
	Time time;
	/// pointer x, y coordinates in event window
	int x, y;
	/// coordinates relative to root
	int x_root, y_root;
	/// key or button mask
	uint state;
	/// detail
	uint button;
	/// same screen flag
	Bool same_screen;
}

///
alias XButtonPressedEvent = XButtonEvent;
///
alias XButtonReleasedEvent = XButtonEvent;

///
struct XMotionEvent {
	/// of event
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// "event" window reported relative to
	Window window;
	/// root window that the event occurred on
	Window root;
	/// child window
	Window subwindow;
	/// milliseconds
	Time time;
	/// pointer x, y coordinates in event window
	int x, y;
	/// coordinates relative to root
	int x_root, y_root;
	/// key or button mask
	uint state;
	/// detail
	char is_hint;
	/// same screen flag
	Bool same_screen;
}

///
alias XPointerMovedEvent = XMotionEvent;

struct XCrossingEvent {
	/// of event
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// "event" window reported relative to
	Window window;
	/// root window that the event occurred on
	Window root;
	/// child window
	Window subwindow;
	/// milliseconds
	Time time;
	/// pointer x, y coordinates in event window
	int x, y;
	/// coordinates relative to root
	int x_root, y_root;
	/// NotifyNormal, NotifyGrab, NotifyUngrab
	int mode;
	/**
	 * NotifyAncestor, NotifyVirtual, NotifyInferior,
	 * NotifyNonlinear,NotifyNonlinearVirtual
	 */
	int detail;
	/// same screen flag
	Bool same_screen;
	/// boolean focus
	Bool focus;
	/// key or button mask
	uint state;
}

///
alias XEnterWindowEvent = XCrossingEvent;
///
alias XLeaveWindowEvent = XCrossingEvent;

///
struct XFocusChangeEvent {
	/// FocusIn or FocusOut
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// window of event
	Window window;
	/// NotifyNormal, NotifyWhileGrabbed, NotifyGrab, NotifyUngrab
	int mode;	
	/**
	 * NotifyAncestor, NotifyVirtual, NotifyInferior,
	 * NotifyNonlinear,NotifyNonlinearVirtual, NotifyPointer,
	 * NotifyPointerRoot, NotifyDetailNone
	 */
	int detail;
}

///
alias XFocusInEvent = XFocusChangeEvent;
///
alias XFocusOutEvent = XFocusChangeEvent;

/// generated on EnterWindow and FocusIn  when KeyMapState selected
struct XKeymapEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window window;
	///
	char[32] key_vector;
}

///
struct XExposeEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display *display;
	///
	Window window;
	///
	int x, y;
	///
	int width, height;
	/// if non-zero, at least this many more
	int count;
}

///
struct XGraphicsExposeEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display *display;
	///
	Drawable drawable;
	///
	int x, y;
	///
	int width, height;
	/// if non-zero, at least this many more
	int count;
	/// core is CopyArea or CopyPlane
	int major_code;
	/// not defined in the core
	int minor_code;
}

///
struct XNoExposeEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Drawable drawable;
	/// core is CopyArea or CopyPlane
	int major_code;
	/// not defined in the core
	int minor_code;
}

///
struct XVisibilityEvent {
	/// 
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window window;
	/// Visibility state
	int state;
}

///
struct XCreateWindowEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// parent of the window
	Window parent;
	/// window id of window created
	Window window;
	/// window location
	int x, y;
	/// size of window
	int width, height;
	/// border width
	int border_width;
	/// creation should be overridden
	Bool override_redirect;
}

///
struct XDestroyWindowEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window event;
	///
	Window window;
}

///
struct XUnmapEvent {
	///
	int type;
	///# of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window event;
	///
	Window window;
	///
	Bool from_configure;
}

///
struct XMapEvent {
	///
	int type;
	// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window event;
	///
	Window window;
	/// boolean, is override set...
	Bool override_redirect;
}

///
struct XMapRequestEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window parent;
	///
	Window window;
}

///
struct XReparentEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window event;
	///
	Window window;
	///
	Window parent;
	///
	int x, y;
	///
	Bool override_redirect;
}

///
struct XConfigureEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window event;
	///
	Window window;
	///
	int x, y;
	///
	int width, height;
	///
	int border_width;
	///
	Window above;
	///
	Bool override_redirect;
}

///
struct XGravityEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window event;
	///
	Window window;
	///
	int x, y;
}

///
struct XResizeRequestEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window window;
	///
	int width, height;
}

///
struct XConfigureRequestEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window parent;
	///
	Window window;
	///
	int x, y;
	///
	int width, height;
	///
	int border_width;
	///
	Window above;
	/// Above, Below, TopIf, BottomIf, Opposite
	int detail;
	///
	c_ulong value_mask;
}

///
struct XCirculateEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display *display;
	///
	Window event;
	///
	Window window;
	/// PlaceOnTop, PlaceOnBottom
	int place;
}

///
struct XCirculateRequestEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	///
	Window parent;
	///
	Window window;
	/// PlaceOnTop, PlaceOnBottom
	int place;
}

///
struct XPropertyEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display *display;
	///
	Window window;
	///
	Atom atom;
	///
	Time time;
	/// NewValue, Deleted
	int state;
}

///
struct XSelectionClearEvent {
	///
	int type;
	///
	c_ulong serial;	/* # of last request processed by server */
	///
	Bool send_event;	/* true if this came from a SendEvent request */
	///
	Display *display;	/* Display the event was read from */
	///
	Window window;
	///
	Atom selection;
	///
	Time time;
}

///
struct XSelectionRequestEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display *display;
	///
	Window owner;
	///
	Window requestor;
	///
	Atom selection;
	///
	Atom target;
	///
	Atom property;
	///
	Time time;
}

///
struct XSelectionEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display *display;
	///
	Window requestor;
	///
	Atom selection;
	///
	Atom target;
	/// ATOM or None
	Atom property;
	///
	Time time;
}

///
struct XColormapEvent {
	///
	int type;
	///
	c_ulong serial;	/* # of last request processed by server */
	///
	Bool send_event;	/* true if this came from a SendEvent request */
	///
	Display *display;	/* Display the event was read from */
	///
	Window window;
	///
	Colormap colormap;	/* COLORMAP or None */
	///
	Bool c_new;		/* C++ */
	///
	int state;		/* ColormapInstalled, ColormapUninstalled */
}

///
struct XClientMessageEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display *display;
	///
	Window window;
	///
	Atom message_type;
	///
	int format;
	
	///
	union data_t {
		///
		char[20] b;
		///
		short[10] s;
		///
		int[5] l;
	}
	///
	data_t data;
}

///
struct XMappingEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// unused
	Window window;
	///one of MappingModifier, MappingKeyboard, MappingPointer
	int request;
	/// first keycode
	int first_keycode;
	/// defines range of change w. first_keycode
	int count;
}

///
struct XErrorEvent {
	///
	int type;
	/// Display the event was read from
	Display* display;
	/// resource id
	XID resourceid;
	/// serial number of failed request
	c_ulong serial;
	/// error code of failed request
	ubyte error_code;
	/// Major op-code of failed request
	ubyte request_code;
	/// Minor op-code of failed request
	ubyte minor_code;
}

///
struct XAnyEvent {
	///
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// window on which event was requested in event mask
	Window window;
}

/***************************************************************
 *
 * GenericEvent.  This event is the standard event for all newer extensions.
 */

///
struct XGenericEvent {
	/// of event. Always GenericEvent
	int type;
	/// # of last request processed
	c_ulong serial;
	/// true if from SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// major opcode of extension that caused the event
	int extension;
	/// actual event type.
	int evtype;
}

///
struct XGenericEventCookie {
	/// of event. Always GenericEvent
	int type;
	/// # of last request processed
	c_ulong serial;
	/// true if from SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// major opcode of extension that caused the event
	int extension;
	/// actual event type.
	int evtype;
	///
	uint cookie;
	///
	void* data;
}

/**
 * this union is defined so Xlib can always use the same sized
 * event structure internally, to avoid memory fragmentation.
 */
union _XEvent {
	/// must not be changed; first element
	int type;
	///
	XAnyEvent xany;
	///
	XKeyEvent xkey;
	///
	XButtonEvent xbutton;
	///
	XMotionEvent xmotion;
	///
	XCrossingEvent xcrossing;
	///
	XFocusChangeEvent xfocus;
	///
	XExposeEvent xexpose;
	///
	XGraphicsExposeEvent xgraphicsexpose;
	///
	XNoExposeEvent xnoexpose;
	///
	XVisibilityEvent xvisibility;
	///
	XCreateWindowEvent xcreatewindow;
	///
	XDestroyWindowEvent xdestroywindow;
	///
	XUnmapEvent xunmap;
	///
	XMapEvent xmap;
	///
	XMapRequestEvent xmaprequest;
	///
	XReparentEvent xreparent;
	///
	XConfigureEvent xconfigure;
	///
	XGravityEvent xgravity;
	///
	XResizeRequestEvent xresizerequest;
	///
	XConfigureRequestEvent xconfigurerequest;
	///
	XCirculateEvent xcirculate;
	///
	XCirculateRequestEvent xcirculaterequest;
	///
	XPropertyEvent xproperty;
	///
	XSelectionClearEvent xselectionclear;
	///
	XSelectionRequestEvent xselectionrequest;
	///
	XSelectionEvent xselection;
	///
	XColormapEvent xcolormap;
	///
	XClientMessageEvent xclient;
	///
	XMappingEvent xmapping;
	///
	XErrorEvent xerror;
	///
	XKeymapEvent xkeymap;
	///
	XGenericEvent xgeneric;
	///
	XGenericEventCookie xcookie;
	///
	c_long[24] pad;
}

///
alias XEvent = _XEvent;

///
auto XAllocID(T)(T dpy) { return (*(cast(_XPrivDisplay)dpy).resource_alloc)((dpy)); }

/// per character font metric information.
struct XCharStruct {
	/// origin to left edge of raster
	short lbearing;
	/// origin to right edge of raster
	short rbearing;
	/// advance to next char's origin
	short width;
	/// baseline to top edge of raster
	short ascent;
	/// baseline to bottom edge of raster
	short descent;
	/// per char flags (not predefined)
	ushort attributes;
}

/**
 * To allow arbitrary information with fonts, there are additional properties
 * returned.
 */
struct XFontProp {
	///
	Atom name;
	///
	c_ulong card32;
}

///
struct XFontStruct {
	/// hook for extension to hang data
	XExtData* ext_data;
	/// Font id for this font
	Font fid;
	/// hint about direction the font is painted
	uint direction;
	/// first character
	uint min_char_or_byte2;
	/// last character
	uint max_char_or_byte2;
	/// first row that exists
	uint min_byte1;
	/// last row that exists
	uint max_byte1;
	/// flag if all characters have non-zero size
	Bool all_chars_exist;
	/// char to print for undefined character
	uint default_char;
	/// how many properties there are
	int n_properties;
	/// pointer to array of additional properties
	XFontProp *properties;
	/// minimum bounds over all existing char
	XCharStruct min_bounds;
	/// maximum bounds over all existing char
	XCharStruct max_bounds;
	/// first_char to last_char information
	XCharStruct *per_char;
	/// log. extent above baseline for spacing
	int ascent;
	/// log. descent below baseline for spacing
	int descent;
}

/// PolyText routines take these as arguments.
struct XTextItem {
	/// pointer to string
	char *chars;
	/// number of characters
	int nchars;
	/// delta between strings
	int delta;
	/// font to print it in, None don't change
	Font font;
}

/// normal 16 bit characters are two bytes
struct XChar2b {
	///
	ubyte byte1;
	///
	ubyte byte2;
}

///
struct XTextItem16 {
	/// two byte characters
	XChar2b *chars;
	/// number of characters
	int nchars;
	/// delta between strings
	int delta;
	/// font to print it in, None don't change
	Font font;
}

///
union XEDataObject {
	///
	Display* display;
	///
	GC gc;
	///
	Visual* visual;
	///
	Screen* screen;
	///
	ScreenFormat* pixmap_format;
	///
	XFontStruct* font;
}

///
struct XFontSetExtents {
	///
	XRectangle max_ink_extent;
	///
	XRectangle max_logical_extent;
}

///
struct _XOM;
///
struct _XOC;

///
alias XOM = _XOM*;
///
alias XOC = _XOC*;
///
alias XFontSet = _XOC*;

///
struct XmbTextItem {
	///
	char* chars;
	///
	int nchars;
	///
	int delta;
	///
	XFontSet font_set;
}

///
struct XwcTextItem {
	///
	wchar_t        *chars;
	///
	int             nchars;
	///
	int             delta;
	///
	XFontSet        font_set;
}

///
enum XNRequiredCharSet = "requiredCharSet";
///
enum XNQueryOrientation = "queryOrientation";
///
enum XNBaseFontName = "baseFontName";
///
enum XNOMAutomatic = "omAutomatic";
///
enum XNMissingCharSet = "missingCharSet";
///
enum XNDefaultString = "defaultString";
///
enum XNOrientation = "orientation";
///
enum XNDirectionalDependentDrawing = "directionalDependentDrawing";
///
enum XNContextualDrawing = "contextualDrawing";
///
enum XNFontInfo = "fontInfo";

///
struct XOMCharSetList {
	///
	int charset_count;
	///
	char** charset_list;
}

///
enum XOrientation {
	///
	XOMOrientation_LTR_TTB,
	///
	XOMOrientation_RTL_TTB,
	///
	XOMOrientation_TTB_LTR,
	///
	XOMOrientation_TTB_RTL,
	///
	XOMOrientation_Context
}

///
struct XOMOrientation {
	///
	int num_orientation;
	/// Input Text description
	XOrientation* orientation;
}

///
struct XOMFontInfo {
	///
	int num_font;
	///
	XFontStruct** font_struct_list;
	///
	char** font_name_list;
}

///
struct _XIM;
///
struct _XIC;

///
alias XIM = _XIM*;
///
alias XIC = _XIC*;

///
alias XIMProc = extern(C) void function(XIM, XPointer, XPointer);

///
alias XICProc = extern(C) Bool function(XIC, XPointer, XPointer);

///
alias XIDProc = extern(C) void function(Display*, XPointer, XPointer);

///
alias XIMStyle = c_ulong;

///
struct XIMStyles {
	///
	ushort count_styles;
	///
	XIMStyle* supported_styles;
}

///
enum XIMPreeditArea = 0x0001;
///
enum XIMPreeditCallbacks = 0x0002;
///
enum XIMPreeditPosition = 0x0004;
///
enum XIMPreeditNothing = 0x0008;
///
enum XIMPreeditNone = 0x0010;
///
enum XIMStatusArea = 0x0100;
///
enum XIMStatusCallbacks = 0x0200;
///
enum XIMStatusNothing = 0x0400;
///
enum XIMStatusNone = 0x0800;

///
enum XNVaNestedList = "XNVaNestedList";
///
enum XNQueryInputStyle = "queryInputStyle";
///
enum XNClientWindow = "clientWindow";
///
enum XNInputStyle = "inputStyle";
///
enum XNFocusWindow = "focusWindow";
///
enum XNResourceName = "resourceName";
///
enum XNResourceClass = "resourceClass";
///
enum XNGeometryCallback = "geometryCallback";
///
enum XNDestroyCallback = "destroyCallback";
///
enum XNFilterEvents = "filterEvents";
///
enum XNPreeditStartCallback = "preeditStartCallback";
///
enum XNPreeditDoneCallback = "preeditDoneCallback";
///
enum XNPreeditDrawCallback = "preeditDrawCallback";
///
enum XNPreeditCaretCallback = "preeditCaretCallback";
///
enum XNPreeditStateNotifyCallback = "preeditStateNotifyCallback";
///
enum XNPreeditAttributes = "preeditAttributes";
///
enum XNStatusStartCallback = "statusStartCallback";
///
enum XNStatusDoneCallback = "statusDoneCallback";
///
enum XNStatusDrawCallback = "statusDrawCallback";
///
enum XNStatusAttributes = "statusAttributes";
///
enum XNArea = "area";
///
enum XNAreaNeeded = "areaNeeded";
///
enum XNSpotLocation = "spotLocation";
///
enum XNColormap = "colorMap";
///
enum XNStdColormap = "stdColorMap";
///
enum XNForeground = "foreground";
///
enum XNBackground = "background";
///
enum XNBackgroundPixmap = "backgroundPixmap";
///
enum XNFontSet = "fontSet";
///
enum XNLineSpace = "lineSpace";
///
enum XNCursor = "cursor";

///
enum XNQueryIMValuesList = "queryIMValuesList";
///
enum XNQueryICValuesList = "queryICValuesList";
///
enum XNVisiblePosition = "visiblePosition";
///
enum XNR6PreeditCallback = "r6PreeditCallback";
///
enum XNStringConversionCallback = "stringConversionCallback";
///
enum XNStringConversion = "stringConversion";
///
enum XNResetState = "resetState";
///
enum XNHotKey = "hotKey";
///
enum XNHotKeyState = "hotKeyState";
///
enum XNPreeditState = "preeditState";
///
enum XNSeparatorofNestedList = "separatorofNestedList";

///
enum XBufferOverflow = -1;
///
enum XLookupNone = 1;
///
enum XLookupChars = 2;
///
enum XLookupKeySym = 3;
///
enum XLookupBoth = 4;

///
alias XVaNestedList = void*;

///
struct XIMCallback {
	///
	XPointer client_data;
	///
	XIMProc callback;
}

///
struct XICCallback {
	///
	XPointer client_data;
	///
	XICProc callback;
}

///
alias XIMFeedback = c_ulong;

///
enum XIMReverse = 1;
///
enum XIMUnderline = 1<<1;
///
enum XIMHighlight = 1<<2;
///
enum XIMPrimary = 1<<5;
///
enum XIMSecondary = 1<<6;
///
enum XIMTertiary = 1<<7;
///
enum XIMVisibleToForward = 1<<8;
///
enum XIMVisibleToBackword = 1<<9;
///
enum XIMVisibleToCenter = 1<<10;

///
struct _XIMText {
	///
	ushort length;
	///
	XIMFeedback* feedback;
	///
	Bool encoding_is_wchar;
	
	///
	union string_t {
		///
		char* multi_byte;
		///
		wchar_t* wide_char;
	}
	///
	string_t string_;
}

///
alias XIMText = _XIMText;

///
alias XIMPreeditState = c_ulong;

///
enum XIMPreeditUnKnown = 0;
///
enum XIMPreeditEnable = 1;
///
enum XIMPreeditDisable = 1<<1;

///
struct	_XIMPreeditStateNotifyCallbackStruct {
	///
	XIMPreeditState state;
}

///
alias XIMPreditStateNotifyCallbackStruct = _XIMPreeditStateNotifyCallbackStruct;

///
alias XIMResetState = c_ulong;

///
enum XIMInitialState = 1;
///
enum XIMPreserveState = 1<<1;

///
alias XIMStringConversionFeedback = c_ulong;

///
enum XIMStringConversionLeftEdge = 0x00000001;
///
enum XIMStringConversionRightEdge = 0x00000002;
///
enum XIMStringConversionTopEdge = 0x00000004;
///
enum XIMStringConversionBottomEdge = 0x00000008;
///
enum XIMStringConversionConcealed = 0x00000010;
///
enum XIMStringConversionWrapped = 0x00000020;

///
struct _XIMStringConversionText {
	///
	ushort length;
	///
	XIMStringConversionFeedback* feedback;
	///
	Bool encoding_is_wchar;
	///
	union string_t {
		///
		char* mbs;
		///
		wchar_t* wcs;
	}
	///
	string_t string_;
}

///
alias XIMStringConversionText = _XIMStringConversionText;

///
alias XIMStringConversionPosition = ushort;
///
alias XIMStringConversionType = ushort;

///
enum XIMStringConversionBuffer = 0x0001;
///
enum XIMStringConversionLine = 0x0002;
///
enum XIMStringConversionWord = 0x0003;
///
enum XIMStringConversionChar = 0x0004;

///
alias XIMStringConversionOperation = ushort;

///
enum XIMStringConversionSubstitution = 0x0001;
///
enum XIMStringConversionRetrieval = 0x0002;

///
enum XIMCaretDirection {
	///
	XIMForwardChar,
	///
	XIMBackwardChar,
	///
	XIMForwardWord,
	///
	XIMBackwardWord,
	///
	XIMCaretUp,
	///
	XIMCaretDown,
	///
	XIMNextLine,
	///
	XIMPreviousLine,
	///
	XIMLineStart,
	///
	XIMLineEnd,
	///
	XIMAbsolutePosition,
	///
	XIMDontChange
}

///
struct _XIMStringConversionCallbackStruct {
	///
	XIMStringConversionPosition position;
	///
	XIMCaretDirection direction;
	///
	XIMStringConversionOperation operation;
	///
	ushort factor;
	///
	XIMStringConversionText* text;
}

///
alias XIMStringConversionCallbackStruct = _XIMStringConversionCallbackStruct;

///
struct _XIMPreeditDrawCallbackStruct {
	/// Cursor offset within pre-edit string
	int caret;
	/// Starting change position
	int chg_first;
	/// Length of the change in character count
	int chg_length;
	///
	XIMText *text;
}

///
alias XIMPreeditDrawCallbackStruct = _XIMPreeditDrawCallbackStruct;

///
enum XIMCaretStyle {
	/// Disable caret feedback
	XIMIsInvisible,
	/// UI defined caret feedback
	XIMIsPrimary,
	/// UI defined caret feedback
	XIMIsSecondary
}

///
struct _XIMPreeditCaretCallbackStruct {
	/// Caret offset within pre-edit string
	int position;
	/// Caret moves direction
	XIMCaretDirection direction;
	/// Feedback of the caret
	XIMCaretStyle style;
}

///
alias XIMPreeditCaretCallbackStruct = _XIMPreeditCaretCallbackStruct;

///
enum XIMStatusDataType {
	///
	XIMTextType,
	///
	XIMBitmapType
}

///
struct _XIMStatusDrawCallbackStruct {
	///
	XIMStatusDataType type;
	
	///
	union data_t {
		///
		XIMText* text;
		///
		Pixmap bitmap;
	}
	///
	data_t data;
}

///
alias XIMStatusDrawCallbackStruct = _XIMStatusDrawCallbackStruct;

///
struct _XIMHotKeyTrigger {
	///
	KeySym keysym;
	///
	int modifier;
	///
	int modifier_mask;
}

///
alias XIMHotKeyTrigger = _XIMHotKeyTrigger;

///
struct _XIMHotKeyTriggers {
	///
	int num_hot_key;
	///
	XIMHotKeyTrigger* key;
}

///
alias XIMHotKeyTriggers = _XIMHotKeyTriggers;

///
alias XIMHotKeyState = c_ulong;

///
enum XIMHotKeyStateON = 0x0001;
///
enum XIMHotKeyStateOFF = 0x0002;

///
struct XIMValuesList {
	///
	ushort count_values;
	///
	char** supported_values;
}

/*
 * We're not porting Xlibint.h since it is internal to the implementation
 * Could be very dangerous.
 */

///
int function() _Xdebug_p;

///
alias _Xdebug = _Xdebug_p;

///
XFontStruct* function(Display* display, const char* name) XLoadQueryFont;
///
XFontStruct* function(Display* display, XID font_ID) XQueryFont;
///
XTimeCoord* function(Display* display, Window w, Time start, Time stop, int* nevents_return) XGetMotionEvents;

///
version(NeedWidePrototypes) {
	///
	XModifierKeymap* function(XModifierKeymap* modmap, uint keycode_entry, int modifier) XDeleteModifiermapEntry;
} else {
	///
	XModifierKeymap* function(XModifierKeymap* modmap, KeyCode keycode_entry, int modifier) XDeleteModifiermapEntry;
}

///
XModifierKeymap* function(Display* display) XGetModifierMapping;

///
version(NeedWidePrototypes) {
	///
	XModifierKeymap* function(XModifierKeymap* modmap, uint keycode_entry, int modifier) XInsertModifiermapEntry;
} else {
	///
	XModifierKeymap* function(XModifierKeymap* modmap, KeyCode keycode_entry, int modifier) XInsertModifiermapEntry;
}

///
XModifierKeymap* function(int max_keys_per_mod) XNewModifiermap;

///
XImage* function(Display* display, Visual* visual, uint depth, int format, int offset, char* data, uint width, uint height, int bitmap_pad, int bytes_per_line) XCreateImage;
///
Status function(XImage* image) XInitImage;
///
XImage* function(Display* display, Drawable d, int x, int y, uint width, uint height, c_ulong plane_mask, int format) XGetImage;
///
XImage* function(Display* display, Drawable d, int x, int y, uint width, uint height, c_ulong plane_mask, int format, XImage* dest_image, int dest_x, int dest_y) XGetSubImage;

/*
 * X function declarations.
 */

///
KeySym function(const char* string_) XStringToKeysym;
///
c_long function(Display* display) XMaxRequestSize;
///
c_long function(Display* display) XExtendedMaxRequestSize;
///
char* function(Display* display) XResourceManagerString;
///
char* function(Screen* screen) XScreenResourceString;
///
c_ulong function(Display* display) XDisplayMotionBufferSize;
///
VisualID function(Visual* visual) XVisualIDFromVisual;

/* multithread routines */

///
Status function() XInitThreads;

///
void function(Display* display) XLockDisplay;

///
void function(Display* display) XUnlockDisplay;

/* routines for dealing with extensions */

///
XExtCodes* function(Display* display, const char* name) XInitExtension;

///
XExtCodes* function(Display* display) XAddExtension;
///
XExtData* function(XExtData** structure, int number) XFindOnExtensionList;
///
XExtData** function(XEDataObject object) XEHeadOfExtensionList;

/* these are routines for which there are also macros */
///
Window function(Display* display, int screen_number) XRootWindow;
///
Window function(Display* display) XDefaultRootWindow;
///
Window function(Screen* screen) XRootWindowOfScreen;
///
Visual* function(Display* display, int screen_number) XDefaultVisual;
///
Visual* function(Screen* screen) XDefaultVisualOfScreen;
///
GC function(Display* display, int screen_number) XDefaultGC;
///
GC function(Screen* screen) XDefaultGCOfScreen;
///
c_ulong function(Display* display, int screen_number) XBlackPixel;
///
c_ulong function(Display* display, int screen_number) XWhitePixel;
///
c_ulong function() XAllPlanes;
///
c_ulong function(Screen* screen) XBlackPixelOfScreen;
///
c_ulong function(Screen* screen) XWhitePixelOfScreen;
///
c_ulong function(Display* display) XNextRequest;
///
c_ulong function(Display* display) XLastKnownRequestProcessed;
///
char* function(Display* display) XServerVendor;
///
char* function(Display* display) XDisplayString;
///
Colormap function(Display* display, int screen_number) XDefaultColormap;
///
Colormap function(Screen* screen) XDefaultColormapOfScreen;
///
Display* function(Screen* screen) XDisplayOfScreen;
///
Screen* function(Display* display, int screen_number) XScreenOfDisplay;
///
Screen* function(Display* display) XDefaultScreenOfDisplay;
///
long function(Screen* screen) XEventMaskOfScreen;
///
int function(Screen* screen) XScreenNumberOfScreen;

/// WARNING, this type not in Xlib spec
alias XErrorHandler = extern(C) int function(Display* display, XErrorEvent* error_event);

///
XErrorHandler function(XErrorHandler handler) XSetErrorHandler;

/// WARNING, this type not in Xlib spec
alias XIOErrorHandler = extern(C) int function(Display* display);

///
XIOErrorHandler function(XIOErrorHandler handler) XSetIOErrorHandler;
///
XPixmapFormatValues* function(Display* display, int* count_return) XListPixmapFormats;
///
int* function(Display* display, int screen_number, int* count_return) XListDepths;

/*
 * ICCCM routines for things that don't require special include files;
 * other declarations are given in Xutil.h
 */

///
Status function(Display* display, Window w, int screen_number, uint mask, XWindowChanges* changes) XReconfigureWMWindow;
///
Status function(Display* display, Window w, Atom** protocols_return, int* count_return) XGetWMProtocols;
///
Status function(Display* display, Window w, Atom* protocols, int count) XSetWMProtocols;
///
Status function( Display* display, Window w, int screen_number) XIconifyWindow;
///
Status function(Display* display, Window w, int screen_number) XWithdrawWindow;
///
Status function(Display* display, Window w , char*** argv_return, int* argc_return) XGetCommand;
///
Status function(Display* display, Window w, Window** windows_return, int* count_return) XGetWMColormapWindows;
///
Status function(Display* display, Window w, Window* colormap_windows, int count) XSetWMColormapWindows;
///
void function(char** list) XFreeStringList;
///
int function(Display* display, Window w, Window prop_window) XSetTransientForHint;

/* The following are given in alphabetical order */

///
int function(Display* display) XActivateScreenSaver;
///
int function(Display* display, XHostAddress* host) XAddHost;
///
int function(Display* display, XHostAddress* hosts, int num_hosts) XAddHosts;
///
int function(_XExtData** structure, XExtData* ext_data) XAddToExtensionList;
///
int function(Display* display, Window w) XAddToSaveSet;
///
Status function(Display* display, Colormap colormap, XColor* screen_in_out) XAllocColor;
///
Status function(Display* display, Colormap colormap, Bool contig, c_ulong* plane_masks_return, uint nplanes, c_ulong* pixels_return, uint npixels) XAllocColorCells;
///
Status function(Display* display, Colormap colormap, Bool contig, c_ulong* pixels_return, int ncolors, int nreds, int ngreens, int nblues, c_ulong* rmask_return, c_ulong* gmask_return, c_ulong* bmask_return) XAllocColorPlanes;
///
Status function(Display* display, Colormap colormap, const char* color_name, XColor* screen_def_return, XColor* exact_def_return) XAllocNamedColor;
///
int function(Display* display, int event_mode, Time time) XAllowEvents;
///
int function(Display* display) XAutoRepeatOff;
///
int function(Display* display) XAutoRepeatOn;
///
int function(Display* display, int percent) XBell;
///
int function(Display* display) XBitmapBitOrder;
///
int function(Display* display) XBitmapPad;
///
int function(Display* display) XBitmapUnit;
///
int function(Screen* screen) XCellsOfScreen;
///
int function(Display* display, uint event_mask, Cursor cursor, Time time) XChangeActivePointerGrab;
///
int function(Display* display, GC gc, c_ulong valuemask, XGCValues* values) XChangeGC;
///
int function(Display* display, c_ulong value_mask, XKeyboardControl* values) XChangeKeyboardControl;
///
int function(Display* display, int first_keycode, int keysyms_per_keycode, KeySym* keysyms, int num_codes) XChangeKeyboardMapping;
///
int function(Display* display, Bool do_accel, Bool do_threshold, int accel_numerator, int accel_denominator, int threshold) XChangePointerControl;
///
int function(Display* display, Window w, Atom property, Atom type, int format, int mode, const ubyte* data, int nelements) XChangeProperty;
///
int function(Display* display, Window w, int change_mode) XChangeSaveSet;
///
int function(Display* display, Window w, c_ulong valuemask, XSetWindowAttributes* attributes) XChangeWindowAttributes;
///
Bool function(Display* display, XEvent* event_return, Bool function(Display* display, XEvent* event, XPointer arg) predicate, XPointer arg) XCheckIfEvent;
///
Bool function(Display* display, c_long event_mask, XEvent* event_return) XCheckMaskEvent;
///
Bool function(Display* display, int event_type, XEvent* event_return) XCheckTypedEvent;
///
Bool function(Display* display, Window w, int event_type, XEvent* event_return) XCheckTypedWindowEvent;
///
Bool function(Display* display, Window w, c_long event_mask, XEvent* event_return) XCheckWindowEvent;
///
int function(Display* display, Window w, int direction) XCirculateSubwindows;
///
int function(Display* display, Window w) XCirculateSubwindowsDown;
///
int function(Display* display, Window w) XCirculateSubwindowsUp;
///
int function(Display* display, Window w, int x, int y, uint width, uint height, Bool exposures) XClearArea;
///
int function(Display* display, Window w) XClearWindow;
///
int function(Display* display) XCloseDisplay;
///
int function(Display* display, Window w, uint value_mask, XWindowChanges* values) XConfigureWindow;
///
int function(Display* display) XConnectionNumber;
///
int function(Display* display, Atom selection, Atom target, Atom property, Window requestor, Time time) XConvertSelection;
///
int function(Display* display, Drawable src, Drawable dest, GC gc, int src_x, int src_y, uint width, uint height, int dest_x, int dest_y) XCopyArea;
///
int function(Display* display, GC src, c_ulong valuemask, GC dest) XCopyGC;
///
int function(Display* display, Drawable src, Drawable dest, GC gc, int src_x, int src_y, uint width, uint height, int dest_x, int dest_y, c_ulong plane) XCopyPlane;
///
int function(Display* display, int screen_number) XDefaultDepth;
///
int function(Screen* screen) XDefaultDepthOfScreen;
///
int function(Display* display) XDefaultScreen;
///
int function(Display* display, Window w, Cursor cursor) XDefineCursor;
///
int function(Display* display, Window w, Atom property) XDeleteProperty;
///
int function(Display* display, Window w) XDestroyWindow;
///
int function(Display* display, Window w) XDestroySubwindows;
///
int function(Screen* screen) XDoesBackingStore;
///
Bool function(Screen* screen) XDoesSaveUnders;
///
int function(Display* display) XDisableAccessControl;
///
int function(Display* display, int screen_number) XDisplayCells;
///
int function(Display* display, int screen_number) XDisplayHeight;
///
int function(Display* display, int screen_number) XDisplayHeightMM;
///
int function(Display* display, int* min_keycodes_return, int* max_keycodes_return) XDisplayKeycodes;
///
int function(Display* display, int screen_number) XDisplayPlanes;
///
int function(Display* display, int screen_number) XDisplayWidth;
///
int function(Display* display, int screen_number) XDisplayWidthMM;
///
int function(Display* display, Drawable d, GC gc, int x, int y, uint width, uint height, int angle1, int angle2) XDrawArc;
///
int function(Display* display, Drawable d, GC gc, XArc* arcs, int narcs) XDrawArcs;
///
int function(Display* display, Drawable d, GC gc, int x, int y, const char* string_, int length) XDrawImageString;
///
int function(Display* display, Drawable d, GC gc, int x, int y, const XChar2b* string, int length) XDrawImageString16;
///
int function(Display* display, Drawable d, GC gc, int x1, int y1, int x2, int y2) XDrawLine;
///
int function(Display* display, Drawable d, GC gc, XPoint* points, int npoints, int mode) XDrawLines;
///
int function(Display* display, Drawable d, GC gc, int x, int y) XDrawPoint;
///
int function(Display* display, Drawable d, GC gc, XPoint* points, int npoints, int mode) XDrawPoints;
///
int function(Display* display, Drawable d, GC gc, int x, int y, uint width, uint height) XDrawRectangle;
///
int function(Display* display, Drawable d, GC gc, XRectangle* rectangles, int nrectangles) XDrawRectangles;
///
int function(Display* display, Drawable d, GC gc, XSegment* segments, int nsegments) XDrawSegments;
///
int function(Display* display, Drawable d, GC gc, int x, int y, const char* string_, int length) XDrawString;
///
int function(Display* display, Drawable d, GC gc, int x, int y, const XChar2b* string_, int length) XDrawString16;
///
int function(Display* display, Drawable d, GC gc, int x, int y, XTextItem* items, int nitems) XDrawText;
///
int function(Display* display, Drawable d, GC gc, int x, int y, XTextItem16* items, int nitems) XDrawText16;
///
int function(Display* display) XEnableAccessControl;
///
int function(Display* display, int mode) XEventsQueued;
///
Status function(Display* display, Window w, char** window_name_return) XFetchName;
///
int function(Display* display, Drawable d, GC gc, int x, int y, uint width, uint height, int angle1, int angle2) XFillArc;
///
int function(Display* display, Drawable d, GC gc, XArc* arcs, int narcs) XFillArcs;
///
int function(Display* display, Drawable d, GC gc, XPoint* points, int npoints, int shape, int mode) XFillPolygon;
///
int function(Display* display, Drawable d, GC gc, int x, int y, uint width, uint height) XFillRectangle;
///
int function(Display* display, Drawable d, GC gc, XRectangle* rectangles, int nrectangles) XFillRectangles;
///
int function(Display* display) XFlush;
///
int function(Display* display, int mode) XForceScreenSaver;
///
int function(void* data) XFree;
///
int function(Display* display, Colormap colormap) XFreeColormap;
///
int function(Display* display, Colormap colormap, c_ulong* pixels, int npixels, c_ulong planes) XFreeColors;
///
int function(Display* display, Cursor cursor) XFreeCursor;
///
int function(char** list) XFreeExtensionList;
///
int function(Display* display, XFontStruct* font_struct) XFreeFont;
///
int function(char** names, XFontStruct* free_info, int actual_count) XFreeFontInfo;
///
int function(char** list) XFreeFontNames;
///
int function(char** list) XFreeFontPath;
///
int function(Display* display, GC gc) XFreeGC;
///
int function(XModifierKeymap* modmap) XFreeModifiermap;
///
int function(Display* display, Pixmap pixmap) XFreePixmap;
///
int function(Display* display, int screen, const char* position, const char* default_position, uint bwidth, uint fwidth, uint fheight, int xadder, int yadder, int* x_return, int* y_return, int* width_return, int* height_return) XGeometry;
///
int function(Display* display, const char* name, const char* message, const char* default_string, char* buffer_return, int length) XGetErrorDatabaseText;
///
int function(Display* display, int code, char* buffer_return, int length) XGetErrorText;
///
Bool function(XFontStruct* font_struct, Atom atom, c_ulong* value_return) XGetFontProperty;
///
Status function(Display* display, GC gc, c_ulong valuemask, XGCValues* values_return) XGetGCValues;
///
Status function(Display* display, Drawable d, Window* root_return, int* x_return, int* y_return, uint* width_return, uint* height_return, uint* border_width_return, uint* depth_return) XGetGeometry;
///
Status function(Display* display, Window w, char** icon_name_return) XGetIconName;
///
int function(Display* display, Window* focus_return, int* revert_to_return) XGetInputFocus;
///
int function(Display* display, XKeyboardState* values_return) XGetKeyboardControl;
///
int function(Display* display, int* accel_numerator_return, int* accel_denominator_return, int* threshold_return) XGetPointerControl;
///
int function(Display* display, ubyte* map_return, int nmap) XGetPointerMapping;
///
int function(Display* display, int* timeout_return, int* interval_return, int* prefer_blanking_return, int* allow_exposures_return) XGetScreenSaver;
///
Status function(Display* display, Window w, Window* prop_window_return) XGetTransientForHint;
///
int function(Display* display, Window w, Atom property, c_long long_offset, c_long long_length, Bool delete_, Atom req_type, Atom* actual_type_return, int* actual_format_return, c_ulong* nitems_return, c_ulong* bytes_after_return, ubyte** prop_return) XGetWindowProperty;
///
Status function(Display* display, Window w, XWindowAttributes* window_attributes_return) XGetWindowAttributes;
///
int function(Display* display, uint button, uint modifiers, Window grab_window, Bool owner_events, uint event_mask, int pointer_mode, int keyboard_mode, Window confine_to, Cursor cursor) XGrabButton;
///
int function(Display* display, int keycode, uint modifiers, Window grab_window, Bool owner_events, int pointer_mode, int keyboard_mode) XGrabKey;
///
int function(Display* display, Window grab_window, Bool owner_events, int pointer_mode, int keyboard_mode, Time time) XGrabKeyboard;
///
int function(Display* display, Window grab_window, Bool owner_events, uint event_mask, int pointer_mode, int keyboard_mode, Window confine_to, Cursor cursor, Time time) XGrabPointer;
///
int function(Display* display) XGrabServer;
///
int function(Screen* screen) XHeightMMOfScreen;
///
int function(Screen* screen) XHeightOfScreen;
///
int function(Display* display, XEvent* event_return, Bool function(Display* display, XEvent* event, XPointer arg) predicate, XPointer arg) XIfEvent;
///
int function(Display* display) XImageByteOrder;
///
int function(Display* display, Colormap colormap) XInstallColormap;
///
KeyCode function(Display* display, KeySym keysym) XKeysymToKeycode;
///
int function(Display* display, XID resource) XKillClient;
///
Status function(Display* display, Colormap colormap, const char* color_name, XColor* exact_def_return, XColor* screen_def_return) XLookupColor;
///
int function(Display* display, Window w) XLowerWindow;
///
int function(Display* display, Window w) XMapRaised;
///
int function(Display* display, Window w) XMapSubwindows;
///
int function(Display* display, Window w) XMapWindow;
///
int function(Display* display, c_long event_mask, XEvent* event_return) XMaskEvent;
///
int function(Screen* screen) XMaxCmapsOfScreen;
///
int function(Screen* screen) XMinCmapsOfScreen;
///
int function(Display* display, Window w, int x, int y, uint width, uint height) XMoveResizeWindow;
///
int function(Display* display, Window w, int x, int y) XMoveWindow;
///
int function(Display* display, XEvent* event_return) XNextEvent;
///
int function(Display* display) XNoOp;
///
Status function(Display* display, Colormap colormap, const char* spec, XColor* exact_def_return) XParseColor;
///
int function(const char* parsestring, int* x_return, int* y_return, uint* width_return, uint* height_return) XParseGeometry;
///
int function(Display* display, XEvent* event_return) XPeekEvent;
///
int function(Display* display, XEvent* event_return, Bool function(Display* display, XEvent* event, XPointer arg) predicate, XPointer arg) XPeekIfEvent;
///
int function(Display* display) XPending;
///
int function(Screen* screen) XPlanesOfScreen;
///
int function(Display* display) XProtocolRevision;
///
int function(Display* display) XProtocolVersion;
///
int function(Display* display, XEvent* event) XPutBackEvent;
///
int function(Display* display, Drawable d, GC gc, XImage* image, int src_x, int src_y, int dest_x, int dest_y, uint width, uint height) XPutImage;
///
int function(Display* display) XQLength;
///
Status function(Display* display, Drawable d, uint width, uint height, uint* width_return, uint* height_return) XQueryBestCursor;
///
Status function(Display* display, int class_, Drawable which_screen, uint width, uint height, uint* width_return, uint* height_return) XQueryBestSize;
///
Status function(Display* display, Drawable which_screen, uint width, uint height, uint* width_return, uint* height_return) XQueryBestStipple;
///
Status function(Display* display, Drawable which_screen, uint width, uint height, uint* width_return, uint* height_return) XQueryBestTile;
///
int function(Display* display, Colormap colormap, XColor* def_in_out) XQueryColor;
///
int function(Display* display, Colormap colormap, XColor* defs_in_out, int ncolors) XQueryColors;
///
Bool function(Display* display, const char* name, int* major_opcode_return, int* first_event_return, int* first_error_return) XQueryExtension;
///
int function(Display* display, char[32] keys_return) XQueryKeymap;
///
Bool function(Display* display, Window w, Window* root_return, Window* child_return, int* root_x_return, int* root_y_return, int* win_x_return, int* win_y_return, uint* mask_return) XQueryPointer;
///
int function(Display* display, XID font_ID, const char* string_, int nchars, int* direction_return, int* font_ascent_return, int* font_descent_return, XCharStruct* overall_return) XQueryTextExtents;
///
int function(Display* display, XID font_ID, const XChar2b* string_, int nchars, int* direction_return, int* font_ascent_return, int* font_descent_return, XCharStruct* overall_return) XQueryTextExtents16;
///
Status function(Display* display, Window w, Window* root_return, Window* parent_return, Window** children_return, uint* nchildren_return) XQueryTree;
///
int function(Display* display, Window w) XRaiseWindow;
///
int function(Display* display, Drawable d, const char* filename, uint* width_return, uint* height_return, Pixmap* bitmap_return, int* x_hot_return, int* y_hot_return) XReadBitmapFile;
///
int function(const char* filename, uint* width_return, uint* height_return, ubyte** data_return, int* x_hot_return, int* y_hot_return) XReadBitmapFileData;
///
int function(Display* display, KeySym keysym, KeySym* list, int mod_count, const char* string_, int bytes_string) XRebindKeysym;
///
int function(Display* display, Cursor cursor, XColor* foreground_color, XColor* background_color) XRecolorCursor;
///
int function(XMappingEvent* event_map) XRefreshKeyboardMapping;
///
int function(Display* display, Window w) XRemoveFromSaveSet;
///
int function(Display* display, XHostAddress* host) XRemoveHost;
///
int function(Display* display, XHostAddress* hosts, int num_hosts) XRemoveHosts;
///
int function(Display* display, Window w, Window parent, int x, int y) XReparentWindow;
///
int function(Display* display) XResetScreenSaver;
///
int function(Display* display, Window w, uint width, uint height) XResizeWindow;
///
int function(Display* display, Window* windows, int nwindows) XRestackWindows;
///
int function(Display* display, int rotate) XRotateBuffers;
///
int function(Display* display, Window w, Atom* properties, int num_prop, int npositions) XRotateWindowProperties;
///
int function(Display* display) XScreenCount;
///
int function(Display* display, Window w, c_long event_mask) XSelectInput;
///
Status function(Display* display, Window w, Bool propagate, c_long event_mask, XEvent* event_send) XSendEvent;
///
int function(Display* display, int mode) XSetAccessControl;
///
int function(Display* display, GC gc, int arc_mode) XSetArcMode;
///
int function(Display* display, GC gc, c_ulong background) XSetBackground;
///
int function(Display* display, GC gc, Pixmap pixmap) XSetClipMask;
///
int function(Display* display, GC gc, int clip_x_origin, int clip_y_origin) XSetClipOrigin;
///
int function(Display* display, GC gc, int clip_x_origin, int clip_y_origin, XRectangle* rectangles, int n, int ordering) XSetClipRectangles;
///
int function(Display* display, int close_mode) XSetCloseDownMode;
///
int function(Display* display, Window w, char** argv, int argc) XSetCommand;
///
int function(Display* display, GC gc, int dash_offset, const char* dash_list, int n) XSetDashes;
///
int function(Display* display, GC gc, int fill_rule) XSetFillRule;
///
int function(Display* display, GC gc, int fill_style) XSetFillStyle;
///
int function(Display* display, GC gc, Font font) XSetFont;
///
int function(Display* display, char** directories, int ndirs) XSetFontPath;
///
int function(Display* display, GC gc, c_ulong foreground) XSetForeground;
///
int function(Display* display, GC gc, int function_) XSetFunction;
///
int function(Display* display, GC gc, Bool graphics_exposures) XSetGraphicsExposures;
///
int function(Display* display, Window w, const char* icon_name) XSetIconName;
///
int function(Display* display, Window focus, int revert_to, Time time) XSetInputFocus;
///
int function(Display* display, GC gc, uint line_width, int line_style, int cap_style, int join_style) XSetLineAttributes;
///
int function(Display* display, XModifierKeymap* modmap) XSetModifierMapping;
///
int function(Display* display, GC gc, c_ulong plane_mask) XSetPlaneMask;
///
int function(Display* display, const ubyte* map, int nmap) XSetPointerMapping;
///
int function(Display* display, int timeout, int interval, int prefer_blanking, int allow_exposures) XSetScreenSaver;
///
int function(Display* display, Atom selection, Window owner, Time time) XSetSelectionOwner;
///
int function(Display* display, GC gc, c_ulong foreground, c_ulong background, int function_, c_ulong plane_mask) XSetState;
///
int function(Display* display, GC gc, Pixmap stipple) XSetStipple;
///
int function(Display* display, GC gc, int subwindow_mode) XSetSubwindowMode;
///
int function(Display* display, GC gc, int ts_x_origin, int ts_y_origin) XSetTSOrigin;
///
int function(Display* display, GC gc, Pixmap tile) XSetTile;
///
int function(Display* display, Window w, c_ulong background_pixel) XSetWindowBackground;
///
int function(Display* display, Window w, Pixmap background_pixmap) XSetWindowBackgroundPixmap;
///
int function(Display* display, Window w, c_ulong border_pixel) XSetWindowBorder;
///
int function(Display* display, Window w, Pixmap border_pixmap) XSetWindowBorderPixmap;
///
int function(Display* display, Window w, uint width) XSetWindowBorderWidth;
///
int function(Display* display, Window w, Colormap colormap) XSetWindowColormap;
///
int function(Display* display, const char* bytes, int nbytes, int buffer) XStoreBuffer;
///
int function(Display* display, const char* bytes, int nbytes) XStoreBytes;
///
int function(Display* display, Colormap colormap, XColor* color) XStoreColor;
///
int function(Display* display, Colormap colormap, XColor* color, int ncolors) XStoreColors;
///
int function(Display* display, Window w, const char* window_name) XStoreName;
///
int function(Display* display, Colormap colormap, const char* color, c_ulong pixel, int flags) XStoreNamedColor;
///
int function(Display* display, Bool discard) XSync;
///
int function(XFontStruct* font_struct, const char* string_, int nchars, int* direction_return, int* font_ascent_return, int* font_descent_return, XCharStruct* overall_return) XTextExtents;
///
int function(XFontStruct* font_struct, const XChar2b* string_, int nchars, int* direction_return, int* font_ascent_return, int* font_descent_return, XCharStruct* overall_return) XTextExtents16;
///
int function(XFontStruct* font_struct, const char* string_, int count) XTextWidth;
///
int function(XFontStruct* font_struct, const XChar2b* string_, int count) XTextWidth16;
///
Bool function(Display* display, Window src_w, Window dest_w, int src_x, int src_y, int* dest_x_return, int* dest_y_return, Window* child_return) XTranslateCoordinates;
///
int function(Display* display, Window w) XUndefineCursor;
///
int function(Display* display, uint button, uint modifiers, Window grab_window) XUngrabButton;
///
int function(Display* display, int keycode, uint modifiers, Window grab_window) XUngrabKey;
///
int function(Display* display, Time time) XUngrabKeyboard;
///
int function(Display* display, Time time) XUngrabPointer;
///
int function(Display* display) XUngrabServer;
///
int function(Display* display, Colormap colormap) XUninstallColormap;
///
int function(Display* display, Font font) XUnloadFont;
///
int function(Display* display, Window w) XUnmapSubwindows;
///
int function(Display* display, Window w) XUnmapWindow;
///
int function(Display* display) XVendorRelease;
///
int function(Display* display, Window src_w, Window dest_w, int src_x, int src_y, uint src_width, uint src_height, int dest_x, int dest_y) XWarpPointer;
///
int function(Screen* screen) XWidthMMOfScreen;
///
int function(Screen* screen) XWidthOfScreen;
///
int function(Display* display, Window w, c_long event_mask, XEvent* event_return) XWindowEvent;
///
int function(Display* display, const char* filename, Pixmap bitmap, uint width, uint height, int x_hot, int y_hot) XWriteBitmapFile;
///
Bool function() XSupportsLocale;
///
char* function(const char* modifier_list) XSetLocaleModifiers;
///
XOM function(Display* display, _XrmHashBucketRec* rdb, const char* res_name, const char* res_class) XOpenOM;
///
Status function(XOM om) XCloseOM;
///
char* function(XOM om, ...) XSetOMValues;
///
char* function(XOM om, ...) XGetOMValues;
///
Display* function(XOM om) XDisplayOfOM;
///
char* function(XOM om) XLocaleOfOM;
///
XOC function(XOM om, ...) XCreateOC;
///
void function(XOC oc) XDestroyOC;
///
XOM function(XOC oc) XOMOfOC;
///
char* function(XOC oc, ...) XSetOCValues;
///
char* function(XOC oc, ...) XGetOCValues;
///
XFontSet function(Display* display, const char* base_font_name_list, char*** missing_charset_list, int* missing_charset_count, char** def_string) XCreateFontSet;
///
void function(Display* display, XFontSet font_set) XFreeFontSet;
///
int function(XFontSet font_set, XFontStruct*** font_struct_list, char*** font_name_list) XFontsOfFontSet;
///
char* function(XFontSet font_set) XBaseFontNameListOfFontSet;
///
char* function(XFontSet font_set) XLocaleOfFontSet;
///
Bool function(XFontSet font_set) XContextDependentDrawing;
///
Bool function(XFontSet font_set) XDirectionalDependentDrawing;
///
Bool function(XFontSet font_set) XContextualDrawing;
///
XFontSetExtents* function(XFontSet font_set) XExtentsOfFontSet;
///
int function(XFontSet font_set, const char* text, int bytes_text) XmbTextEscapement;
///
int function(XFontSet font_set, const wchar_t* text, int num_wchars) XwcTextEscapement;
///
int function(XFontSet font_set, const char* text, int bytes_text) Xutf8TextEscapement;
///
int function(XFontSet font_set, const char* text, int bytes_text, XRectangle* overall_ink_return, XRectangle* overall_logical_return) XmbTextExtents;
///
int function(XFontSet font_set, const wchar_t* text, int num_wchars, XRectangle* overall_ink_return, XRectangle* overall_logical_return) XwcTextExtents;
///
int function(XFontSet font_set, const char* text, int bytes_text, XRectangle* overall_ink_return, XRectangle* overall_logical_return) Xutf8TextExtents;
///
Status function(XFontSet font_set, const char* text, int bytes_text, XRectangle* ink_extents_buffer, XRectangle* logical_extents_buffer, int buffer_size, int* num_chars, XRectangle* overall_ink_return, XRectangle* overall_logical_return) XmbTextPerCharExtents;
///
Status function(XFontSet font_set, const wchar_t* text, int num_wchars, XRectangle* ink_extents_buffer, XRectangle* logical_extents_buffer, int buffer_size, int* num_chars, XRectangle* overall_ink_return, XRectangle* overall_logical_return) XwcTextPerCharExtents;
///
Status function(XFontSet font_set, const char* text, int bytes_text, XRectangle* ink_extents_buffer, XRectangle* logical_extents_buffer, int buffer_size, int* num_chars, XRectangle* overall_ink_return, XRectangle* overall_logical_return) Xutf8TextPerCharExtents;
///
void function(Display* display, Drawable d, GC gc, int x, int y, XmbTextItem* text_items, int nitems) XmbDrawText;
///
void function(Display* display, Drawable d, GC gc, int x, int y, XwcTextItem* text_items, int nitems) XwcDrawText;
///
void function(Display* display, Drawable d, GC gc, int x, int y, XmbTextItem* text_items, int nitems) Xutf8DrawText;
///
void function(Display* display, Drawable d, XFontSet font_set, GC gc, int x, int y, const char* text, int bytes_text) XmbDrawString;
///
void function(Display* display, Drawable d, XFontSet font_set, GC gc, int x, int y, const wchar_t* text, int num_wchars) XwcDrawString;
///
void function(Display* display, Drawable d, XFontSet font_set, GC gc, int x, int y, const char* text, int bytes_text) Xutf8DrawString;
///
void function(Display* display, Drawable d, XFontSet font_set, GC gc, int x, int y, const char* text, int bytes_text) XmbDrawImageString;
///
void function(Display* display, Drawable d, XFontSet font_set, GC gc, int x, int y, const wchar_t* text, int num_wchars) XwcDrawImageString;
///
void function(Display* display, Drawable d, XFontSet font_set, GC gc, int x, int y, const char* text, int bytes_text) Xutf8DrawImageString;
///
XIM function(Display* dpy, _XrmHashBucketRec* rdb, char* res_name, char* res_class) XOpenIM;
///
Status function(XIM im) XCloseIM;
///
char* function(XIM im, ...) XGetIMValues;
///
char* function(XIM im, ...) XSetIMValues;
///
Display* function(XIM im) XDisplayOfIM;
///
char* function(XIM im) XLocaleOfIM;
///
XIC function(XIM im, ...) XCreateIC;
///
void function(XIC ic) XDestroyIC;
///
void function(XIC ic) XSetICFocus;
///
void function(XIC ic) XUnsetICFocus;
///
wchar_t* function(XIC ic) XwcResetIC;
///
char* function(XIC ic) XmbResetIC;
///
char* function(XIC ic) Xutf8ResetIC;
///
char* function(XIC ic, ...) XSetICValues;
///
char* function(XIC i, ...) XGetICValues;
///
XIM function(XIC ic) XIMOfIC;
///
Bool function(XEvent* event, Window window) XFilterEvent;
///
int function(XIC ic, XKeyPressedEvent* event, char* buffer_return, int bytes_buffer, KeySym* keysym_return, Status* status_return) XmbLookupString;
///
int function(XIC ic, XKeyPressedEvent* event, wchar_t* buffer_return, int wchars_buffer, KeySym* keysym_return, Status* status_return) XwcLookupString;
///
int function(XIC ic, XKeyPressedEvent* event, char* buffer_return, int bytes_buffer, KeySym* keysym_return, Status* status_return) Xutf8LookupString;
///
XVaNestedList function(int unused, ...) XVaCreateNestedList;

/* internal connections for IMs */

///
Bool function(Display* dpy, _XrmHashBucketRec* rdb, char* res_name, char* res_class, XIDProc callback, XPointer client_data) XRegisterIMInstantiateCallback;
///
Bool function(Display* dpy, _XrmHashBucketRec* rdb, char* res_name, char* res_class, XIDProc callback, XPointer client_data) XUnregisterIMInstantiateCallback;

/**
 * Params: 
 * 		dpy			=
 * 		client_data	=
 * 		fd 			=
 * 		opening 	=	open or close flag
 * 		watch_data	=	open sets, close uses
 */
alias XConnectionWatchProc = extern(C) void function(Display* dpy, XPointer client_data, int fd, Bool opening, XPointer* watch_data);

///
Status function(Display* dpy, int** fd_return, int* count_return) XInternalConnectionNumbers;
///
void function(Display* dpy, int fd) XProcessInternalConnection;
///
Status function(Display* dpy, XConnectionWatchProc callback, XPointer client_data) XAddConnectionWatch;
///
void function(Display* dpy, XConnectionWatchProc callback, XPointer client_data) XRemoveConnectionWatch;
///
void function(char* name, int namelen, char* data, int datalen) XSetAuthorization;
///
int function(wchar_t* wstr, const char* str, size_t len) _Xmbtowc;
///
int function(char* str, wchar_t wc) _Xwctomb;
///
Bool function(Display* dpy, XGenericEventCookie* cookie) XGetEventData;
///
void function(Display* dpy, XGenericEventCookie* cookie) XFreeEventData;
