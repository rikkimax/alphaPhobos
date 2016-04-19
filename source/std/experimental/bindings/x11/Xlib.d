/*

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
__gshared extern(C):

///
enum XlibSpecificationRelease = 6;

import std.experimental.bindings.x11.X;

///
alias wchar_t = wchar;

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

