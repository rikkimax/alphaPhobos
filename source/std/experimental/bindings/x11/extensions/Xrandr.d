/**
 * License:
 *     Copyright © 2000 Compaq Computer Corporation, Inc.
 *     Copyright © 2002 Hewlett-Packard Company, Inc.
 *     Copyright © 2006 Intel Corporation
 *     Copyright © 2008 Red Hat, Inc.
 *     
 *     Permission to use, copy, modify, distribute, and sell this software and its
 *     documentation for any purpose is hereby granted without fee, provided that
 *     the above copyright notice appear in all copies and that both that copyright
 *     notice and this permission notice appear in supporting documentation, and
 *     that the name of the copyright holders not be used in advertising or
 *     publicity pertaining to distribution of the software without specific,
 *     written prior permission.  The copyright holders make no representations
 *     about the suitability of this software for any purpose.  It is provided "as
 *     is" without express or implied warranty.
 *
 *     THE COPYRIGHT HOLDERS DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
 *     INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO
 *     EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY SPECIAL, INDIRECT OR
 *     CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
 *     DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 *     TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
 *     OF THIS SOFTWARE.
 *
 *     Author:  Jim Gettys, HP Labs, Hewlett-Packard, Inc.
 *	    Keith Packard, Intel Corporation
 */
module std.experimental.bindings.x11.extensions.Xrandr;
import std.experimental.bindings.x11.X;
import std.experimental.bindings.x11.Xlib;
import std.experimental.bindings.x11.extensions.randr;
import std.experimental.bindings.x11.extensions.Xrender;
import core.stdc.config : c_long, c_ulong;
__gshared extern(C):

///
alias RROutput = XID;
///
alias RRCrtc = XID;
///
alias RRMode = XID;
///
alias RRProvider = XID;

///
struct XRRScreenSize {
	///
	int width, height;
	///
	int mwidth, mheight;
}

/*
 * Events.
 */

///
struct XRRScreenChangeNotifyEvent {
	/// event base
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// window which selected for this event
	Window window;
	/// Root window for changed screen
	Window root;
	/// when the screen change occurred
	Time timestamp;
	/// when the last configuration change
	Time config_timestamp;
	///
	SizeID size_index;
	///
	SubpixelOrder subpixel_order;
	///
	Rotation rotation;
	///
	int width;
	///
	int height;
	///
	int mwidth;
	///
	int mheight;
}

///
struct XRRNotifyEvent {
	/// event base
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// window which selected for this event
	Window window;
	/// RRNotify_ subtype
	int subtype;
}

///
struct XRROutputChangeNotifyEvent {
	/// event base
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// window which selected for this event
	Window window;
	/// RRNotify_OutputChange
	int subtype;
	/// affected output
	RROutput output;
	/// current crtc (or None)
	RRCrtc crtc;
	/// current mode (or None)
	RRMode mode;
	/// current rotation of associated crtc
	Rotation rotation;
	/// current connection status
	Connection connection;
	///
	SubpixelOrder subpixel_order;
}

///
struct XRRCrtcChangeNotifyEvent {
	/// event base
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// window which selected for this event
	Window window;
	/// RRNotify_CrtcChange
	int subtype;
	/// current crtc (or None)
	RRCrtc crtc;
	/// current mode (or None)
	RRMode mode;
	/// current rotation of associated crtc
	Rotation rotation;
	/// position
	int x, y;
	/// size
	uint width, height;
}

///
struct XRROutputPropertyNotifyEvent {
	/// event base
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// window which selected for this event
	Window window;
	/// RRNotify_OutputProperty
	int subtype;
	/// related output
	RROutput output;
	/// changed property
	Atom property;
	/// time of change
	Time timestamp;
	/// NewValue, Deleted
	int state;
}

///
struct XRRProviderChangeNotifyEvent {
	/// event base
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// window which selected for this event
	Window window;
	/// RRNotify_ProviderProperty
	int subtype;
	/// related provider
	RRProvider provider;
	/// changed property
	Atom property;
	/// time of change
	Time timestamp;
	/// NewValue, Deleted
	int state;
}

///
struct XRRProviderPropertyNotifyEvent {
	/// event base
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// window which selected for this event
	Window window;
	/// RRNotify_ProviderProperty
	int subtype;
	/// related provider
	RRProvider provider;
	/// changed property
	Atom property;
	/// time of change
	Time timestamp;
	/// NewValue, Deleted
	int state;
}

///
struct XRRResourceChangeNotifyEvent {
	/// event base
	int type;
	/// # of last request processed by server
	c_ulong serial;
	/// true if this came from a SendEvent request
	Bool send_event;
	/// Display the event was read from
	Display* display;
	/// window which selected for this event
	Window window;
	/// RRNotify_ResourceChange
	int subtype;
	/// time of change
	Time timestamp;
}

/* internal representation is private to the library */

///
struct _XRRScreenConfiguration;
///
alias XRRScreenConfiguration = _XRRScreenConfiguration;

///
Bool function(Display* dpy, int* event_base_return, int* error_base_return) XRRQueryExtension;
///
Status function(Display* dpy, int* major_versiohn_return, int* minor_version_return) XRRQueryVersion;
///
XRRScreenConfiguration* function(Display* dpy, Window window) XRRGetScreenInfo;
///
void function(XRRScreenConfiguration* config) XRRFreeScreenConfigInfo;

/*
 * Note that screen configuration changes are only permitted if the client can
 * prove it has up to date configuration information.  We are trying to
 * insist that it become possible for screens to change dynamically, so
 * we want to ensure the client knows what it is talking about when requesting
 * changes.
 */

///
Status function(Display* dpy, XRRScreenConfiguration* config, Drawable draw, int size_index, Rotation rotation, Time timestamp) XRRSetScreenConfig;
/// added in v1.1, sorry for the lame name
Status function(Display* dpy, XRRScreenConfiguration* config, Drawable draw, int size_index, Rotation rotation, short rate, Time timestamp) XRRSetScreenConfigAndRate;

///
Rotation function(XRRScreenConfiguration* config, Rotation* current_rotation) XRRConfigRotations;
///
Time function(XRRScreenConfiguration* config, Time* config_timestamp) XRRConfigTimes;
///
XRRScreenSize* function(XRRScreenConfiguration* config, int* nsizes) XRRConfigSizes;
///
short* function(XRRScreenConfiguration* config, int sizeID, int* nrates) XRRConfigRates;
///
SizeID function(XRRSreenConfiguration* config, Rotation* rotation) XRRConfigCurrentConfiguration;
///
short function(XRRScreenConfiguration* config) XRRConfigCurrentRate;
///
int function(Display* dpy, Window root) XRRRootToScreen;

/**
 * returns the screen configuration for the specified screen; does a lazy
 * evalution to delay getting the information, and caches the result.
 * These routines should be used in preference to XRRGetScreenInfo
 * to avoid unneeded round trips to the X server.  These are new
 * in protocol version 0.1.
 */
void function(Display* dpy, Window window, int mask) XRRSelectInput;

/*
 * the following are always safe to call, even if RandR is not implemented
 * on a screen
 */

///
Rotation function(Display* dpy, int screen, Rotation* current_rotation) XRRRotations;
///
XRRScreenSize* function(Display* dpy, int screen, int* nsizes) XRRSizes;
///
short* function(Display* dpy, int screen, int sizeID, int* nrates) XRRRates;
///
Time function(Display* dpy, int screen, Time* config_timestamp) XRRTimes;

/* Version 1.2 additions */

/// despite returning a Status, this returns 1 for success
Status function(Display* dpy, Window window, int* minWidth, int* minHeight, int* maxWidth, int* maxHeight) XRRGetScreenSizeRange;
///
void function(Display* dpy, Window window, int width, int height, int mmWidth, int mmHeight) XRRSetScreenSize;

///
alias XRRModeFlags = c_ulong;

///
struct _XRRModeInfo {
	///
	RRMode id;
	///
	uint width;
	///
	uint height;
	///
	c_ulong dotClock;
	///
	uint hSyncStart;
	///
	uint hSyncEnd;
	///
	uint hTotal;
	///
	uint hSkew;
	///
	uint vSyncStart;
	///
	uint vSyncEnd;
	///
	uint vTotal;
	///
	char* name;
	///
	uint nameLength;
	///
	XRRModeFlags modeFlags;
}

///
alias XRRModeInfo = _XRRModeInfo;

///
struct _XRRScreenResources {
	///
	Time timestamp;
	///
	Time configTimestamp;
	///
	int ncrtc;
	///
	RRCrtc* crtcs;
	///
	int noutput;
	///
	RROutput* outputs;
	///
	int nmode;
	///
	XRRModeInfo* modes;
}

///
alias XRRScreenResources = _XRRScreenResources;

///
XRRScreenResources* function(Display* dpy, Window window) XRRGetScreenResources;

///
void function(XRRScreenResources* resources) XRRFreeScreenResources;

///
struct _XRROutputInfo {
	///
	Time timestamp;
	///
	RRCrtc crtc;
	///
	char* name;
	///
	int nameLen;
	///
	c_ulong mm_width;
	///
	c_ulong mm_height;
	///
	Connection connection;
	///
	SubpixelOrder subpixel_order;
	///
	int ncrtc;
	///
	RRCrtc* crtcs;
	///
	int nclone;
	///
	RROutput* clones;
	///
	int nmode;
	///
	int npreferred;
	///
	RRMode* modes;
}

///
alias XRROutputInfo = _XRROutputInfo;

///
XRROutputInfo* function(Display* dpy, XRRScreenResources* resources, RROutput output) XRRGetOutputInfo;
///
void function(XRROutputInfo* outputInfo) XRRFreeOutputInfo;
///
Atom* function(Display* dpy, RROutput output, int* nprop) XRRListOutputProperties;

///
struct XRRPropertyInfo {
	///
	Bool pending;
	///
	Bool range;
	///
	Bool immutable_;
	///
	int num_values;
	///
	c_long* values;
}

///
XRRPropertyInfo* function(Display* dpy, RROutput output, Atom property) XRRQueryOutputProperty;
///
void function(Display* dpy, RROutput output, Atom property, Bool pending, Bool range, int num_values, c_long* values) XRRConfigureOutputProperty;
///
void function(Display* dpy, RROutput output, Atom property, Atom type, int format, int mode, const ubyte* data, int nelements) XRRChangeOutputProperty;
///
void function(Display* dpy, RROutput output, Atom property) XRRDeleteOutputProperty;
///
int function(Display* dpy, RROutput output, Atom property, c_long offset, c_long length, Bool _delete, Bool pending, Atom req_type, Atom* actual_type, int* actual_format, c_ulong* nitems, c_ulong* bytes_after, ubyte** prop) XRRGetOutputProperty;
///
XRRModeInfo* function(const char* name, int nameLength) XRRAllocModeInfo;
///
RRMode function(Display* dpy, Window window, XRRModeInfo* modeInfo) XRRCreateMode;
///
void function(Display* dpy, RRMode mode) XRRDestroyMode;
///
void function(Display* dpy, RROutput output, RRMode mode) XRRAddOutputMode;
///
void function(Display* dpy, RROutput output, RRMode mode) XRRDeleteOutputMode;
///
void function(XRRModeInfo* modeInfo) XRRFreeModeInfo;

///
struct _XRRCrtcInfo {
	///
	Time timestamp;
	///
	int x, y;
	///
	uint width, height;
	///
	RRMode mode;
	///
	Rotation rotation;
	///
	int noutput;
	///
	RROutput* outputs;
	///
	Rotation rotations;
	///
	int npossible;
	///
	RROutput* possible;
}

///
alias XRRCrtcInfo = _XRRCrtcInfo;

///
XRRCrtcInfo* function(Display* dpy, XRRScreenResources* resources, RRCrtc crtc) XRRGetCrtcInfo;
///
void function(XRRCrtcInfo* crtcInfo) XRRFreeCrtcInfo;
///
Status function(Display* dpy, XRRScreenResources* resources, RRCrtc crtc, Time timestamp, int x, int y, RRMode mode, Rotation rotation, RROutput* outputs, int noutputs) XRRSetCrtcConfig;
///
int function(Display* dpy, RRCrtc crtc) XRRGetCrtcGammaSize;

///
struct _XRRCrtcGamma {
	///
	int size;
	///
	ushort* red;
	///
	ushort* green;
	///
	ushort* blue;
}

///
alias XRRCrtcGamma = _XRRCrtcGamma;

///
XRRCrtcGamma* function(Display* dpy, RRCrtc crtc) XRRGetCrtcGamma;
///
XRRCrtcGamma* function(int size) XRRAllocGamma;
///
void function(Display* dpy, RRCrtc crtc, XRRCrtcGamma* gamma) XRRSetCrtcGamma;
///
void function(XRRCrtcGamma* gamma) XRRFreeGamma;

/* Version 1.3 additions */

/// 
XRRScreenResources* function(Display* dpy, Window window) XRRGetScreenResourcesCurrent;
///
void function(Display* dpy, RRCrtc crtc, XTransform *transform, const char* filter, XFixed* params, int nparams) XRRSetCrtcTransform;

///
struct _XRRCrtcTransformAttributes {
	///
	XTransform pendingTransform;
	///
	char* pendingFilter;
	///
	int pendingNparams;
	///
	XFixed* pendingParams;
	///
	XTransform currentTransform;
	///
	char* currentFilter;
	///
	int currentNparams;
	///
	XFixed* currentParams;
}

///
alias XRRCrtcTransformAttributes = _XRRCrtcTransformAttributes;

/**
 * Get current crtc transforms and filters.
 * Pass *attributes to XFree to free
 */
Status function(Display* dpy, RRCrtc crtc, XRRCrtcTransformAttributes** attributes) XRRGetCrtcTransform;

/**
 * intended to take RRScreenChangeNotify, or
 * ConfigureNotify (on the root window)
 * returns 1 if it is an event type it understands, 0 if not
 */
int function(XEvent* event) XRRUpdateConfiguration;

///
struct _XRRPanning {
	///
	Time timestamp;
	///
	uint left;
	///
	uint top;
	///
	uint width;
	///
	uint height;
	///
	uint track_left;
	///
	uint track_top;
	///
	uint track_width;
	///
	uint track_height;
	///
	int border_left;
	///
	int border_top;
	///
	int border_right;
	///
	int border_bottom;
}

///
alias XRRPanning = _XRRPanning;

///
XRRPanning* function(Display* dpy, XRRScreenResources* resources, RRCrtc crtc) XRRGetPanning;
///
void function(XRRPanning* panning) XRRFreePanning;
///
Status function(Display* dpy, XRRScreenResources* resources, RRCrtc crtc, XRRPanning* panning) XRRSetPanning;
///
void function(Display* dpy, Window window, RROutput output) XRRSetOutputPrimary;
///
RROutput function(Display* dpy, Window window) XRRGetOutputPrimary;

///
struct _XRRProviderResources {
	///
	Time timestamp;
	///
	int nproviders;
	///
	RRProvider* providers;
}

///
alias XRRProviderResources = _XRRProviderResources;
///
XRRProviderResources* function(Display* dpy, Window window) XRRGetProviderResources;
///
void function(XRRProviderResources* resources) XRRFreeProviderResources;

///
struct _XRRProviderInfo {
	///
	uint capabilities;
	///
	int ncrtcs;
	///
	RRCrtc* crtcs;
	///
	int noutputs;
	///
	RROutput* outputs;
	///
	char* name;
	///
	int nassociatedproviders;
	///
	RRProvider* associated_providers;
	///
	uint* associated_capability;
	///
	int nameLen;
}

///
alias XRRProviderInfo = _XRRProviderInfo;

///
XRRProviderInfo* function(Display* dpy, XRRScreenResources* resources, RRProvider provider) XRRGetProviderInfo;
///
void function(XRRProviderInfo* provider) XRRFreeProviderInfo;
///
int function(Display* dpy, XID provider, XID source_provider) XRRSetProviderOutputSource;
///
int function(Display* dpy, XID provider, XID sink_provider) XRRSetProviderOffloadSink;
///
Atom* function(Display* dpy, RRProvider provider, int* nprop) XRRListProviderProperties;
///
XRRPropertyInfo* function(Display* dpy, RRProvider provider, Atom property) XRRQueryProviderProperty;
///
void function(Display* dpy, RRProvider provider, Atom property, Bool pending, Bool range, int num_values, c_long* values) XRRConfigureProviderProperty;
///
void function(Display* dpy, RRProvider provider, Atom property, Atom type, int format, int mode, const ubyte* data, int nelements) XRRChangeProviderProperty;
///
void function(Display* dpy, RRProvider provider, Atom property) XRRDeleteProviderProperty;
///
int function(Display* dpy, RRProvider provider, Atom property, c_long offset, c_long length, Bool _delete, Bool pending, Atom req_type, Atom* actual_type, int* actual_format, c_ulong* nitems, c_ulong* bytes_after, ubyte** prop) XRRGetProviderProperty;


















