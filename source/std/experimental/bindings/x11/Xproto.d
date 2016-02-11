/***********************************************************

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

******************************************************************/
module std.experimental.bindings.x11.Xproto;
import std.experimental.bindings.x11.Xmd;
import std.experimental.bindings.x11.Xprotostr;


/*
 * Define constants for the sizes of the network packets.  The sz_ prefix is
 * used instead of something more descriptive so that the symbols are no more
 * than 32 characters in length (which causes problems for some compilers).
 */
enum {
    ///
    sz_xSegment = 8,
    ///
    sz_xPoint = 4,
    ///
    sz_xRectangle = 8,
    ///
    sz_xArc = 12,
    ///
    sz_xConnClientPrefix = 12,
    ///
    sz_xConnSetupPrefix = 8,
    ///
    sz_xConnSetup = 32,
    ///
    sz_xPixmapFormat = 8,
    ///
    sz_xDepth = 8,
    ///
    sz_xVisualType = 24,
    ///
    sz_xWindowRoot = 40,
    ///
    sz_xTimecoord = 8,
    ///
    sz_xHostEntry = 4,
    ///
    sz_xCharInfo = 12,
    ///
    sz_xFontProp = 8,
    ///
    sz_xTextElt = 2,
    ///
    sz_xColorItem = 12,
    ///
    sz_xrgb = 8,
    ///
    sz_xGenericReply = 32,
    ///
    sz_xGetWindowAttributesReply = 44,
    ///
    sz_xGetGeometryReply = 32,
    ///
    sz_xQueryTreeReply = 32,
    ///
    sz_xInternAtomReply = 32,
    ///
    sz_xGetAtomNameReply = 32,
    ///
    sz_xGetPropertyReply = 32,
    ///
    sz_xListPropertiesReply = 32,
    ///
    sz_xGetSelectionOwnerReply = 32,
    ///
    sz_xGrabPointerReply = 32,
    ///
    sz_xQueryPointerReply = 32,
    ///
    sz_xGetMotionEventsReply = 32,
    ///
    sz_xTranslateCoordsReply = 32,
    ///
    sz_xGetInputFocusReply = 32,
    ///
    sz_xQueryKeymapReply = 40,
    ///
    sz_xQueryFontReply = 60,
    ///
    sz_xQueryTextExtentsReply = 32,
    ///
    sz_xListFontsReply = 32,
    ///
    sz_xGetFontPathReply = 32,
    ///
    sz_xGetImageReply = 32,
    ///
    sz_xListInstalledColormapsReply = 32,
    ///
    sz_xAllocColorReply = 32,
    ///
    sz_xAllocNamedColorReply = 32,
    ///
    sz_xAllocColorCellsReply = 32,
    ///
    sz_xAllocColorPlanesReply = 32,
    ///
    sz_xQueryColorsReply = 32,
    ///
    sz_xLookupColorReply = 32,
    ///
    sz_xQueryBestSizeReply = 32,
    ///
    sz_xQueryExtensionReply = 32,
    ///
    sz_xListExtensionsReply = 32,
    ///
    sz_xSetMappingReply = 32,
    ///
    sz_xGetKeyboardControlReply = 52,
    ///
    sz_xGetPointerControlReply = 32,
    ///
    sz_xGetScreenSaverReply = 32,
    ///
    sz_xListHostsReply = 32,
    ///
    sz_xSetModifierMappingReply = 32,
    ///
    sz_xError = 32,
    ///
    sz_xEvent = 32,
    ///
    sz_xKeymapEvent = 32,
    ///
    sz_xReq = 4,
    ///
    sz_xResourceReq = 8,
    ///
    sz_xCreateWindowReq = 32,
    ///
    sz_xChangeWindowAttributesReq = 12,
    ///
    sz_xChangeSaveSetReq = 8,
    ///
    sz_xReparentWindowReq = 16,
    ///
    sz_xConfigureWindowReq = 12,
    ///
    sz_xCirculateWindowReq = 8,
    ///
    sz_xInternAtomReq = 8,
    ///
    sz_xChangePropertyReq = 24,
    ///
    sz_xDeletePropertyReq = 12,
    ///
    sz_xGetPropertyReq = 24,
    ///
    sz_xSetSelectionOwnerReq = 16,
    ///
    sz_xConvertSelectionReq = 24,
    ///
    sz_xSendEventReq = 44,
    ///
    sz_xGrabPointerReq = 24,
    ///
    sz_xGrabButtonReq = 24,
    ///
    sz_xUngrabButtonReq = 12,
    ///
    sz_xChangeActivePointerGrabReq = 16,
    ///
    sz_xGrabKeyboardReq = 16,
    ///
    sz_xGrabKeyReq = 16,
    ///
    sz_xUngrabKeyReq = 12,
    ///
    sz_xAllowEventsReq = 8,
    ///
    sz_xGetMotionEventsReq = 16,
    ///
    sz_xTranslateCoordsReq = 16,
    ///
    sz_xWarpPointerReq = 24,
    ///
    sz_xSetInputFocusReq = 12,
    ///
    sz_xOpenFontReq = 12,
    ///
    sz_xQueryTextExtentsReq = 8,
    ///
    sz_xListFontsReq = 8,
    ///
    sz_xSetFontPathReq = 8,
    ///
    sz_xCreatePixmapReq = 16,
    ///
    sz_xCreateGCReq = 16,
    ///
    sz_xChangeGCReq = 12,
    ///
    sz_xCopyGCReq = 16,
    ///
    sz_xSetDashesReq = 12,
    ///
    sz_xSetClipRectanglesReq = 12,
    ///
    sz_xCopyAreaReq = 28,
    ///
    sz_xCopyPlaneReq = 32,
    ///
    sz_xPolyPointReq = 12,
    ///
    sz_xPolySegmentReq = 12,
    ///
    sz_xFillPolyReq = 16,
    ///
    sz_xPutImageReq = 24,
    ///
    sz_xGetImageReq = 20,
    ///
    sz_xPolyTextReq = 16,
    ///
    sz_xImageTextReq = 16,
    ///
    sz_xCreateColormapReq = 16,
    ///
    sz_xCopyColormapAndFreeReq = 12,
    ///
    sz_xAllocColorReq = 16,
    ///
    sz_xAllocNamedColorReq = 12,
    ///
    sz_xAllocColorCellsReq = 12,
    ///
    sz_xAllocColorPlanesReq = 16,
    ///
    sz_xFreeColorsReq = 12,
    ///
    sz_xStoreColorsReq = 8,
    ///
    sz_xStoreNamedColorReq = 16,
    ///
    sz_xQueryColorsReq = 8,
    ///
    sz_xLookupColorReq = 12,
    ///
    sz_xCreateCursorReq = 32,
    ///
    sz_xCreateGlyphCursorReq = 32,
    ///
    sz_xRecolorCursorReq = 20,
    ///
    sz_xQueryBestSizeReq = 12,
    ///
    sz_xQueryExtensionReq = 8,
    ///
    sz_xChangeKeyboardControlReq = 8,
    ///
    sz_xBellReq = 4,
    ///
    sz_xChangePointerControlReq = 12,
    ///
    sz_xSetScreenSaverReq = 12,
    ///
    sz_xChangeHostsReq = 8,
    ///
    sz_xListHostsReq = 4,
    ///
    sz_xChangeModeReq = 4,
    ///
    sz_xRotatePropertiesReq = 12,
    ///
    sz_xReply = 32,
    ///
    sz_xGrabKeyboardReply = 32,
    ///
    sz_xListFontsWithInfoReply = 60,
    ///
    sz_xSetPointerMappingReply = 32,
    ///
    sz_xGetKeyboardMappingReply = 32,
    ///
    sz_xGetPointerMappingReply = 32,
    ///
    sz_xGetModifierMappingReply = 32,
    ///
    sz_xListFontsWithInfoReq = 8,
    ///
    sz_xPolyLineReq = 12,
    ///
    sz_xPolyArcReq = 12,
    ///
    sz_xPolyRectangleReq = 12,
    ///
    sz_xPolyFillRectangleReq = 12,
    ///
    sz_xPolyFillArcReq = 12,
    ///
    sz_xPolyText8Req = 16,
    ///
    sz_xPolyText16Req = 16,
    ///
    sz_xImageText8Req = 16,
    ///
    sz_xImageText16Req = 16,
    ///
    sz_xSetPointerMappingReq = 4,
    ///
    sz_xForceScreenSaverReq = 4,
    ///
    sz_xSetCloseDownModeReq = 4,
    ///
    sz_xClearAreaReq = 16,
    ///
    sz_xSetAccessControlReq = 4,
    ///
    sz_xGetKeyboardMappingReq = 8,
    ///
    sz_xSetModifierMappingReq = 4,
    ///
    sz_xPropIconSize = 24,
    ///
    sz_xChangeKeyboardMappingReq = 8
}

///
alias Window = CARD32;
///
alias Drawable = CARD32;
///
alias Font = CARD32;
///
alias Pixmap = CARD32;
///
alias Cursor = CARD32;
///
alias Colormap = CARD32;
///
alias GContext = CARD32;
///
alias Atom = CARD32;
///
alias VisualID = CARD32;
///
alias Time = CARD32;
///
alias KeyCode = CARD32;
///
alias KeySym = CARD32;

///
enum X_TCP_PORT = 6000;
///
enum xTrue = 1;
///
enum xFalse = 0;

///
alias KeyButMask = CARD16;

/***************** 
   connection setup structure.  This is followed by
   numRoots xWindowRoot structs.
*****************/

///
struct xConnClientPrefix {
    ///
    CARD8 byteOrder;
    ///
    BYTE pad;
    ///
    CARD16 majorVersion, minorVersion;
    /// Authorization protocol
    CARD16 nbytesAuthProto;
    /// Authorization string
    CARD16 nbytesAuthString;
    CARD16 pad2;
}

///
struct xConnSetupPrefix {
    ///
    CARD8 success;
    /// num bytes in string following if failure
    BYTE lengthReason;
    ///
    CARD16 majorVersion, minorVersion;
    /// 1/4 additional bytes in setup info
    CARD16 length;
}

///
struct xConnSetup {
    ///
    CARD32 release;
    ///
    CARD32 ridBase;
    ///
    CARD32 motionBufferSize;
    /// number of bytes in vendor string
    CARD16 nbytesVendor;
    /// number of roots structs to follow
    CARD8 numRoots;
    /// number of pixmap formats
    CARD8 numFormats;
    /// LSBFirst, MSBFirst
    CARD8 imageByteOrder;
    /// LeastSignificant, MostSign...
    CARD8 bitmapBitOrder;
    /// 8, 16, 32
    CARD8 bitmapScanlineUnit, bitmapScanlinePad;
    ///
    KeyCode minKeyCode, maxKeyCode;
    CARD32 pad2;
}

///
struct xPixmapFormat {
    ///
    CARD8 depth;
    ///
    CARD8 bitsPerPixel;
    ///
    CARD8 scanLinePad;

    CARD8 pad1;
    CARD32 pad2;
}

/* window root */

///
struct xDepth {
    ///
    CARD8 depth;

    CARD8 pad1;
    /// number of xVisualType structures following
    CARD16 nVisuals;
    CARD32 pad2;
}

///
struct xVisualType {
    ///
    VisualID visualID;
    ///
    CARD8 c_class;
    ///
    CARD8 bitsPerRGB;
    ///
    CARD16 colormapEntries;
    ///
    CARD32 redMask, greenMask, blueMask;
    CARD32 pad;
}

///
struct xWindowRoot {
    ///
    Window windowId;
    ///
    Colormap defaultColormap;
    ///
    CARD32 whitePixel, blackPixel;
    ///
    CARD32 currentInputMask;
    ///
    CARD16 pixWidth, pixHeight;
    ///
    CARD16 mmWidth, mmHeight;
    ///
    CARD16 minInstalledMaps, maxInstalledMaps;
    ///
    VisualID rootVisualID;
    ///
    CARD8 backingStore;
    ///
    BOOL saveUnders;
    ///
    CARD8 rootDepth;
    /// number of xDepth structures following
    CARD8 nDepths;
}

/*****************************************************************
 * Structure Defns
 *   Structures needed for replies 
 *****************************************************************/

/* Used in GetMotionEvents */

///
struct xTimecoord {
    ///
    CARD32 time;
    ///
    INT16 x, y;
}

///
struct xHostEntry {
    ///
    CARD8 family;
    BYTE pad;
    ///
    CARD16 length;
}

///
struct xCharInfo {
    ///
    INT16 leftSideBearing,
        rightSideBearing,
        characterWidth,
        ascent,
        descent;
    ///
    CARD16 attributes;
}

///
struct xFontProp {
    ///
    Atom name;
    ///
    CARD32 value;
}

/**
 * non-aligned big-endian font ID follows this struct
 * followed by string
 */
struct xTextElt {
    /**
     * number of *characters* in string, or FontChange (255)
     * for font change, or 0 if just delta given
     */
    CARD8 len;
    ///
    INT8 delta;
}

///
struct xColorItem {
    ///
    CARD32 pixel;
    ///
    CARD16 red, green, blue;
    /// DoRed, DoGreen, DoBlue booleans
    CARD8 flags;
    CARD8 pad;
}

struct xrgb {
    CARD16 red, green, blue;
}

alias KEYCODE = CARD8;

/*****************
 * XRep:
 *    meant to be 32 byte quantity 
 *****************/

/**
 * GenericReply is the common format of all replies.  The "data" items
 * are specific to each individual reply type.
 */
struct xGenericReply {
    /// X_Reply
    BYTE type;
    /// depends on reply type
    BYTE data1;
    /// of last request received by server
    CARD16 sequenceNumber;
    /// 4 byte quantities beyond size of GenericReply
    CARD32 length;
    ///
    CARD32 data00;
    ///
    CARD32 data01;
    ///
    CARD32 data02;
    ///
    CARD32 data03;
    ///
    CARD32 data04;
    ///
    CARD32 data05;
}

/* Individual reply formats. */

struct xGetWindowAttributesReply {
    /// X_Reply
    BYTE type;
    ///
    CARD8 backingStore;
    ///
    CARD16 sequenceNumber;
    /// NOT 0; this is an extra-large reply
    CARD32 length;
    ///
    VisualID visualID;
    ///
    CARD16 c_class;
    ///
    CARD8 bitGravity;
    ///
    CARD8 winGravity;
    ///
    CARD32 backingBitPlanes;
    ///
    CARD32 backingPixel;
    ///
    BOOL saveUnder;
    ///
    BOOL mapInstalled;
    ///
    CARD8 mapState;
    ///
    BOOL override_;
    ///
    Colormap colormap;
    ///
    CARD32 allEventMasks;
    ///
    CARD32 yourEventMask;
    ///
    CARD16 doNotPropagateMask;
    CARD16 pad;
}

///
struct xGetGeometryReply {
    /// X_Reply
    BYTE type;
    ///
    CARD8 depth;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    Window root;
    ///
    INT16 x, y;
    ///
    CARD16 width, height;
    ///
    CARD16 borderWidth;
    CARD16 pad1;
    CARD32 pad2;
    CARD32 pad3;
}

///
struct xQueryTreeReply {
    ///
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    ///
    Window root, parent;
    ///
    CARD16 nChildren;
    CARD16 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
}

///
struct xInternAtomReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    Atom atom;
    CARD32 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
}

///
struct xGetAtomNameReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// of additional bytes
    CARD32 length;
    /// # of characters in name
    CARD16 nameLength;
    CARD16 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xGetPropertyReply {
    /// X_Reply
    BYTE type;
    ///
    CARD8 format;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    ///
    Atom propertyType;
    ///
    CARD32 bytesAfter;
    ///
    CARD32 nItems;
    CARD32 pad1;
    CARD32 pad2;
    CARD32 pad3;
}

///
struct xListPropertiesReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    ///
    CARD16 nProperties;
    CARD16 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xGetSelectionOwnerReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    Window owner;
    CARD32 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
}

///
struct xGrabPointerReply {
    /// X_Reply
    BYTE type;
    ///
    BYTE status;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    CARD32 pad1;
    CARD32 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
}

///
alias xGrabKeyboardReply = xGrabPointerReply;

///
struct xQueryPointerReply {
    /// X_Reply
    BYTE type;
    ///
    BOOL sameScreen;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    Window root, child;
    ///
    INT16 rootX, rootY, winX, winY;
    ///
    CARD16 mask;
    CARD16 pad1;
    CARD32 pad;
}

///
struct xGetMotionEventsReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    CARD16 sequenceNumber;
    CARD32 length;
    CARD32 nEvents;
    CARD32 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
}

///
struct xTranslateCoordsReply {
    /// X_Reply
    BYTE type;
    ///
    BOOL sameScreen;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    Window child;
    ///
    INT16 dstX, dstY;
    CARD32 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
}

///
struct xGetInputFocusReply {
    /// X_Reply
    BYTE type;
    ///
    CARD8 revertTo;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    Window focus;
    CARD32 pad1;
    CARD32 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
}

///
struct xQueryKeymapReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// 2, NOT 0; this is an extra-large reply
    CARD32 length;
    ///
    BYTE[32] map;
}

/// Warning: this MUST match (up to component renaming) xListFontsWithInfoReply
struct xQueryFontReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// definitely > 0, even if "nCharInfos" is 0
    CARD32 length;
    ///
    xCharInfo minBounds;

    version(WORD64) {
    } else {
        CARD32 walign1;
    }

    ///
    xCharInfo maxBounds;

    version(WORD64) {
    } else {
        CARD32 walign2;
    }

    ///
    CARD16 minCharOrByte2, maxCharOrByte2;
    ///
    CARD16 defaultChar;
    /// followed by this many xFontProp structures
    CARD16 nFontProps;
    ///
    CARD8 drawDirection;
    ///
    CARD8 minByte1, maxByte1;
    ///
    BOOL allCharsExist;
    ///
    INT16 fontAscent, fontDescent;
    /// followed by this many xCharInfo structures
    CARD32 nCharInfos;
}

///
struct xQueryTextExtentsReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    CARD16 nFonts;
    CARD16 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xListFontsReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    ///
    CARD16 nFonts;
    CARD16 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

/// Warning: this MUST match (up to component renaming) xQueryFontReply
struct xListFontsWithInfoReply {
    /// X_Reply
    BYTE type;
    /// 0 indicates end-of-reply-sequence
    CARD8 nameLength;
    ///
    CARD16 sequenceNumber;
    /// definitely > 0, even if "nameLength" is 0
    CARD32 length;
    ///
    xCharInfo minBounds;

    version(WORD64) {
    } else {
        CARD32 walign1;
    }

    ///
    xCharInfo maxBounds;

    version(WORD64) {
    } else {
        CARD32 walign2;
    }

    ///
    CARD16 minCharOrByte2, maxCharOrByte2;
    ///
    CARD16 defaultChar;
    /// followed by this many xFontProp structures
    CARD16 nFontProps;
    ///
    CARD8 drawDirection;
    ///
    CARD8 minByte1, maxByte1;
    ///
    BOOL allCharsExist;
    ///
    INT16 fontAscent, fontDescent;
    /// hint as to how many more replies might be coming
    CARD32 nReplies;
}

///
struct xGetFontPathReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    ///
    CARD16 nPaths;
    CARD16 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xGetImageReply {
    /// X_Reply
    BYTE type;
    ///
    CARD8 depth;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    ///
    VisualID visual;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xListInstalledColormapsReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    ///
    CARD16 nColormaps;
    CARD16 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xAllocColorReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    CARD16 red, green, blue;
    CARD16 pad2;
    ///
    CARD32 pixel;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
}

///
struct xAllocNamedColorReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    CARD32 pixel;
    ///
    CARD16 exactRed, exactGreen, exactBlue;
    ///
    CARD16 screenRed, screenGreen, screenBlue;
    CARD32 pad2;
    CARD32 pad3;
}

///
struct xAllocColorCellsReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    ///
    CARD16 nPixels, nMasks;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xAllocColorPlanesReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    ///
    CARD16 nPixels;
    CARD16 pad2;
    ///
    CARD32 redMask, greenMask, blueMask;
    CARD32 pad3;
    CARD32 pad4;
}

///
struct xQueryColorsReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    ///
    CARD16 nColors;
    CARD16 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xLookupColorReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    CARD16 exactRed, exactGreen, exactBlue;
    ///
    CARD16 screenRed, screenGreen, screenBlue;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
}

///
struct xQueryBestSizeReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    CARD16 width, height;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xQueryExtensionReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    BOOL  present;
    ///
    CARD8 major_opcode;
    ///
    CARD8 first_event;
    ///
    CARD8 first_error;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xListExtensionsReply {
    /// X_Reply
    BYTE type;
    ///
    CARD8 nExtensions;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    CARD32 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xSetMappingReply {
    /// X_Reply
    BYTE   type;
    ///
    CARD8  success;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    CARD32 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
alias xSetPointerMappingReply = xSetMappingReply;
///
alias xSetModifierMappingReply = xSetMappingReply;

///
struct xGetPointerMappingReply {
    /// X_Reply
    BYTE type;
    /// how many elements does the map have
    CARD8 nElts;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    CARD32 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

///
struct xGetKeyboardMappingReply {
    ///
    BYTE type;
    ///
    CARD8 keySymsPerKeyCode;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    CARD32 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

/// 
struct xGetModifierMappingReply {
    ///
    BYTE type;
    ///
    CARD8 numKeyPerModifier;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    CARD32 pad1;
    CARD32 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
}

///
struct xGetKeyboardControlReply {
    /// X_Reply
    BYTE type;
    ///
    BOOL globalAutoRepeat;
    ///
    CARD16 sequenceNumber;
    /// 5
    CARD32 length;
    ///
    CARD32 ledMask;
    ///
    CARD8 keyClickPercent, bellPercent;
    ///
    CARD16 bellPitch, bellDuration;
    ///
    CARD16 pad;
    /// bit masks start here
    BYTE[32] map;
}

///
struct xGetPointerControlReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    CARD16 accelNumerator, accelDenominator;
    ///
    CARD16 threshold;
    CARD16 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
}

///
struct xGetScreenSaverReply {
    /// X_Reply
    BYTE type;
    BYTE pad1;
    ///
    CARD16 sequenceNumber;
    /// 0
    CARD32 length;
    ///
    CARD16 timeout, interval;
    ///
    BOOL preferBlanking;
    ///
    BOOL allowExposures;
    CARD16 pad2;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
}

///
struct xListHostsReply {
    /// X_Reply
    BYTE type;
    ///
    BOOL enabled;
    ///
    CARD16 sequenceNumber;
    ///
    CARD32 length;
    ///
    CARD16 nHosts;
    CARD16 pad1;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

/*****************************************************************
 * Xerror
 *    All errors  are 32 bytes 
 *****************************************************************/
struct xError {
    /// X_Error
    BYTE type;
    ///
    BYTE errorCode;
    /// the nth request from this client
    CARD16 sequenceNumber;
    ///
    CARD32 resourceID;
    ///
    CARD16 minorCode;
    ///
    CARD8 majorCode;
    BYTE pad1;
    CARD32 pad3;
    CARD32 pad4;
    CARD32 pad5;
    CARD32 pad6;
    CARD32 pad7;
}

/*****************************************************************
 * xEvent
 *    All events are 32 bytes
 *****************************************************************/
struct xEvent {
    ///
    union U {
        ///
        struct U {
            ///
            BYTE type;
            ///
            BYTE detail;
            ///
            CARD16 sequenceNumber;
        }
        U u;

        ///
        struct KeyButtonPointer {
            CARD32 pad00;
            ///
            Time time;
            ///
            Window root, event, child;
            ///
            INT16 rootX, rootY, eventX, eventY;
            ///
            KeyButMask state;
            ///
            BOOL sameScreen;        
            BYTE pad1;
        }
        ///
        KeyButtonPointer keyButtonPointer;

        ///
        struct EnterLeave {
            CARD32 pad00;
            ///
            Time time;
            ///
            Window root, event, child;
            ///
            INT16 rootX, rootY, eventX, eventY;
            ///
            KeyButMask state;
            /// really XMode
            BYTE mode;
            /// sameScreen and focus booleans, packed together
            BYTE flags;

            ///
            enum ELFlagFocus = (1<<0);
            ///
            enum ELFlagSameScreen = (1<<1);
        }
        ///
        EnterLeave enterLeave;

        ///
        struct Focus {
            CARD32 pad00;
            ///
            Window window;
            /// really XMode
            BYTE mode;
            BYTE pad1, pad2, pad3;
        }
        ///
        Focus focus;

        ///
        struct Expose {
            CARD32 pad00;
            ///
            Window window;
            ///
            CARD16 x, y, width, height;
            ///
            CARD16 count;
            CARD16 pad2;
        }
        ///
        Expose expose;

        ///
        struct GraphicsExposure {
            CARD32 pad00;
            ///
            Drawable drawable;
            ///
            CARD16 x, y, width, height;
            ///
            CARD16 minorEvent;
            ///
            CARD16 count;
            ///
            BYTE majorEvent;
            BYTE pad1, pad2, pad3;
        }
        ///
        GraphicsExposure graphicsExposure;

        ///
        struct NoExposure {
            CARD32 pad00;
            ///
            Drawable drawable;
            ///
            CARD16 minorEvent;
            ///
            BYTE majorEvent;
            BYTE bpad;
        }
        ///
        NoExposure noExposure;

        ///
        struct Visibility {
            CARD32 pad00;
            ///
            Window window;
            ///
            CARD8 state;
            BYTE pad1, pad2, pad3;
        }
        ///
        Visibility visibility;

        ///
        struct CreateNotify {
            CARD32 pad00;
            ///
            Window parent, window;
            ///
            INT16 x, y;
            ///
            CARD16 width, height, borderWidth;
            ///
            BOOL override_;
            BYTE bpad;
        }
        ///
        CreateNotify createNotify;


        /*
         * The event fields in the structures for DestroyNotify, UnmapNotify,
         * MapNotify, ReparentNotify, ConfigureNotify, CirculateNotify, GravityNotify,
         * must be at the same offset because server internal code is depending upon
         * this to patch up the events before they are delivered.
         * Also note that MapRequest, ConfigureRequest and CirculateRequest have
         * the same offset for the event window.
         */


        ///
        struct DestroyNotify {
            CARD32 pad00;
            ///
            Window event, window;
        }
        ///
        DestroyNotify destroyNotify;

        ///
        struct UnmapNotify {
            CARD32 pad00;
            ///
            Window event, window;
            ///
            BOOL fromConfigure;
            BYTE pad1, pad2, pad3;
        }
        ///
        UnmapNotify unmapNotify;

        ///
        struct MapNotify {
            CARD32 pad00;
            ///
            Window event, window;
            ///
            BOOL override_;
            BYTE pad1, pad2, pad3;
        }
        ///
        MapNotify mapNotify;

        ///
        struct MapRequest {
            CARD32 pad00;
            ///
            Window parent, window;
        }
        ///
        MapRequest mapRequest;

        ///
        struct Reparent {
            CARD32 pad00;
            ///
            Window event, window, parent;
            ///
            INT16 x, y;
            ///
            BOOL override_;
            BYTE pad1, pad2, pad3;
        }
        ///
        Reparent reparent;

        ///
        struct ConfigureNotify {
            CARD32 pad00;
            ///
            Window event, window, aboveSibling;
            ///
            INT16 x, y;
            ///
            CARD16 width, height, borderWidth;
            ///
            BOOL override_;      
            BYTE bpad;
        }
        ///
        ConfigureNotify configureNotify;

        ///
        struct ConfigureRequest {
            CARD32 pad00;
            ///
            Window parent, window, sibling;
            ///
            INT16 x, y;
            ///
            CARD16 width, height, borderWidth;
            ///
            CARD16 valueMask;
            CARD32 pad1;
        }
        ///
        ConfigureRequest configureRequest;

        ///
        struct Gravity {
            CARD32 pad00;
            ///
            Window event, window;
            ///
            INT16 x, y;
            CARD32 pad1, pad2, pad3, pad4;
        }
        ///
        Gravity gravity;

        ///
        struct ResizeRequest {
            CARD32 pad00;
            ///
            Window window;
            ///
            CARD16 width, height;
        }
        ///
        ResizeRequest resizeRequest;

        ///
        struct Circulate {
            /* The event field in the circulate record is really the parent when this
   is used as a CirculateRequest instead of a CirculateNotify */
            CARD32 pad00;
            ///
            Window event, window, parent;
            /// Top or Bottom
            BYTE place;
            BYTE pad1, pad2, pad3;
        }
        ///
        Circulate circulate;

        ///
        struct Property {
            CARD32 pad00;
            ///
            Window window;
            ///
            Atom atom;
            ///
            Time time;
            /// NewValue or Deleted
            BYTE state;
            BYTE pad1;
            CARD16 pad2;
        }
        ///
        Property property;

        ///
        struct SelectionClear {
            CARD32 pad00;
            ///
            Time time;     
            ///
            Window window;
            ///
            Atom atom;
        }
        ///
        SelectionClear selectionClear;

        ///
        struct SelectionRequest {
            CARD32 pad00;
            ///
            Time time;    
            ///
            Window owner, requestor;
            ///
            Atom selection, target, property;
        }
        ///
        SelectionRequest selectionRequest;

        ///
        struct SelectionNotify {
            CARD32 pad00;
            ///
            Time time;   
            ///
            Window requestor;
            ///
            Atom selection, target, property;
        }
        ///
        SelectionNotify selectionNotify;

        ///
        struct Colormap_ {
            CARD32 pad00;
            ///
            Window window;
            ///
            Colormap colormap;
            ///
            BOOL c_new;
            /// Installed or UnInstalled
            BYTE state;
            BYTE pad1, pad2;
        }
        ///
        Colormap_ colormap;

        ///
        struct MappingNotify {
            CARD32 pad00;
            ///
            CARD8 request;
            ///
            KeyCode firstKeyCode;
            ///
            CARD8 count;
            BYTE pad1;
        }
        ///
        MappingNotify mappingNotify;

        ///
        struct ClientMessage {
            CARD32 pad00;
            ///
            Window window;
            ///
            union U {
                ///
                struct L {
                    ///
                    Atom type;
                    ///
                    INT32 longs0;
                    ///
                    INT32 longs1;
                    ///
                    INT32 longs2;
                    ///
                    INT32 longs3;
                    ///
                    INT32 longs4;
                }
                ///
                L l;

                ///
                struct S {
                    ///
                    Atom type;
                    ///
                    INT16 shorts0;
                    ///
                    INT16 shorts1;
                    ///
                    INT16 shorts2;
                    ///
                    INT16 shorts3;
                    ///
                    INT16 shorts4;
                    ///
                    INT16 shorts5;
                    ///
                    INT16 shorts6;
                    ///
                    INT16 shorts7;
                    ///
                    INT16 shorts8;
                    ///
                    INT16 shorts9;
                }
                ///
                S s;

                ///
                struct B {
                    ///
                    Atom type;
                    ///
                    INT8[20] bytes;
                }
                ///
                B b;
            }
            ///
            U u;
        }
        ///
        ClientMessage clientMessage;
    }
    ///
    U u;
}

/*********************************************************
 *
 * Generic event
 * 
 * Those events are not part of the core protocol spec and can be used by
 * various extensions.
 * type is always GenericEvent
 * extension is the minor opcode of the extension the event belongs to.
 * evtype is the actual event type, unique __per extension__. 
 *
 * GenericEvents can be longer than 32 bytes, with the length field
 * specifying the number of 4 byte blocks after the first 32 bytes. 
 *
 *
 */
struct xGenericEvent {
    ///
    BYTE    type;
    ///
    CARD8   extension;
    ///
    CARD16  sequenceNumber;
    ///
    CARD32  length;
    ///
    CARD16  evtype;
    CARD16  pad2;
    CARD32  pad3;
    CARD32  pad4;
    CARD32  pad5;
    CARD32  pad6;
    CARD32  pad7;
}

/**
 * KeymapNotify events are not included in the above union because they
 * are different from all other events: they do not have a "detail"
 * or "sequenceNumber", so there is room for a 248-bit key mask.
 */
struct xKeymapEvent {
    BYTE type;
    BYTE[31] map;
}

enum XEventSize = xEvent.sizeof;

/**
 * XReply is the union of all the replies above whose "fixed part"
 * fits in 32 bytes.  It does NOT include GetWindowAttributesReply,
 * QueryFontReply, QueryKeymapReply, or GetKeyboardControlReply 
 * ListFontsWithInfoReply
 */
union xReply {
    ///
    xGenericReply generic;
    ///
    xGetGeometryReply geom;
    ///
    xQueryTreeReply tree;
    ///
    xInternAtomReply atom;
    ///
    xGetAtomNameReply atomName;
    ///
    xGetPropertyReply property;
    ///
    xListPropertiesReply listProperties;
    ///
    xGetSelectionOwnerReply selection;
    ///
    xGrabPointerReply grabPointer;
    ///
    xGrabKeyboardReply grabKeyboard;
    ///
    xQueryPointerReply pointer;
    ///
    xGetMotionEventsReply motionEvents;
    ///
    xTranslateCoordsReply coords;
    ///
    xGetInputFocusReply inputFocus;
    ///
    xQueryTextExtentsReply textExtents;
    ///
    xListFontsReply fonts;
    ///
    xGetFontPathReply fontPath;
    ///
    xGetImageReply image;
    ///
    xListInstalledColormapsReply colormaps;
    ///
    xAllocColorReply allocColor;
    ///
    xAllocNamedColorReply allocNamedColor;
    ///
    xAllocColorCellsReply colorCells;
    ///
    xAllocColorPlanesReply colorPlanes;
    ///
    xQueryColorsReply colors;
    ///
    xLookupColorReply lookupColor;
    ///
    xQueryBestSizeReply bestSize;
    ///
    xQueryExtensionReply extension;
    ///
    xListExtensionsReply extensions;
    ///
    xSetModifierMappingReply setModifierMapping;
    ///
    xGetModifierMappingReply getModifierMapping;
    ///
    xSetPointerMappingReply setPointerMapping;
    ///
    xGetKeyboardMappingReply getKeyboardMapping;
    ///
    xGetPointerMappingReply getPointerMapping;
    ///
    xGetPointerControlReply pointerControl;
    ///
    xGetScreenSaverReply screenSaver;
    ///
    xListHostsReply hosts;
    ///
    xError error;
    ///
    xEvent event;
}

/*****************************************************************
 * REQUESTS
 *****************************************************************/

/// Request structure
struct xReq {
    ///
    CARD8 reqType;
    /// meaning depends on request type
    CARD8 data;
    /**
     * length in 4 bytes quantities 
     * of whole request, including this header
     */
    CARD16 length;
}

/*****************************************************************
 *  structures that follow request. 
 *****************************************************************/

/**
 * ResourceReq is used for any request which has a resource ID 
 * (or Atom or Time) as its one and only argument.
 */
struct xResourceReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    /// a Window, Drawable, Font, GContext, Pixmap, etc.
    CARD32 id;
}

///
struct xCreateWindowReq {
    ///
    CARD8 reqType;
    ///
    CARD8 depth;
    ///
    CARD16 length;
    ///
    Window wid, parent;
    ///
    INT16 x, y;
    ///
    CARD16 width, height, borderWidth;
    ///
    CARD16 c_class;
    ///
    VisualID visual;
    ///
    CARD32 mask;
}

///
struct xChangeWindowAttributesReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Window window;
    ///
    CARD32 valueMask; 
}

///
struct xChangeSaveSetReq {
    ///
    CARD8 reqType;
    ///
    BYTE mode;
    ///
    CARD16 length;
    ///
    Window window;
} 

///
struct xReparentWindowReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Window window, parent;
    ///
    INT16 x, y;
}

///
struct xConfigureWindowReq {
    ///
    CARD8 reqType;
    CARD8 pad;
    ///
    CARD16 length;
    ///
    Window window;
    ///
    CARD16 mask;
    ///
    CARD16 pad2;
}

struct xCirculateWindowReq {
    ///
    CARD8 reqType;
    ///
    CARD8 direction;
    ///
    CARD16 length;
    ///
    Window window;
}

/// followed by padded string
struct xInternAtomReq {
    ///
    CARD8 reqType;
    ///
    BOOL onlyIfExists;
    ///
    CARD16 length;
    /// number of bytes in string
    CARD16 nbytes;
    CARD16 pad;
}

///
struct xChangePropertyReq {
    ///
    CARD8 reqType;
    ///
    CARD8 mode;
    ///
    CARD16 length;
    ///
    Window window;
    ///
    Atom property, type;
    ///
    CARD8 format;
    BYTE[3] pad;
    /// length of stuff following, depends on format
    CARD32 nUnits;
}

///
struct xDeletePropertyReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Window window;
    ///
    Atom property;
}


///
struct xGetPropertyReq {
    ///
    CARD8 reqType;
    ///
    BOOL c_delete;
    ///
    CARD16 length;
    ///
    Window window;
    ///
    Atom property, type;
    ///
    CARD32 longOffset;
    ///
    CARD32 longLength;
}

///
struct xSetSelectionOwnerReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Window window;
    ///
    Atom selection;
    ///
    Time time;
}

struct xConvertSelectionReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Window requestor;
    ///
    Atom selection, target, property;
    ///
    Time time;
}

///
struct xSendEventReq {
    ///
    CARD8 reqType;
    ///
    BOOL propagate;
    ///
    CARD16 length;
    ///
    Window destination;
    ///
    CARD32 eventMask;

    version(WORD64) {
        /// the structure should have been quad-aligned
        BYTE[xEvent.sizeof] eventdata;
    } else {
        ///
        xEvent event;
    }
}

///
struct xGrabPointerReq {
    ///
    CARD8 reqType;
    ///
    BOOL ownerEvents;
    ///
    CARD16 length;
    ///
    Window grabWindow;
    ///
    CARD16 eventMask;
    ///
    BYTE pointerMode, keyboardMode;
    ///
    Window confineTo;
    ///
    Cursor cursor;
    ///
    Time time;
}

///
struct xGrabButtonReq {
    ///
    CARD8 reqType;
    ///
    BOOL ownerEvents;
    ///
    CARD16 length;
    ///
    Window grabWindow;
    ///
    CARD16 eventMask;
    ///
    BYTE pointerMode, keyboardMode;
    ///
    Window confineTo;
    ///
    Cursor cursor;
    ///
    CARD8 button;
    BYTE pad;
    ///
    CARD16 modifiers;
}

///
struct xUngrabButtonReq {
    ///
    CARD8 reqType;
    ///
    CARD8 button;
    ///
    CARD16 length;
    ///
    Window grabWindow;
    ///
    CARD16 modifiers;
    CARD16 pad;
}

///
struct xChangeActivePointerGrabReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Cursor cursor;
    ///
    Time time;
    ///
    CARD16 eventMask;
    CARD16 pad2;
}


///
struct xGrabKeyboardReq {
    ///
    CARD8 reqType;
    ///
    BOOL ownerEvents;
    ///
    CARD16 length;
    ///
    Window grabWindow;
    ///
    Time time;
    ///
    BYTE pointerMode, keyboardMode;
    CARD16 pad;
}

///
struct xGrabKeyReq {
    ///
    CARD8 reqType;
    ///
    BOOL ownerEvents;
    ///
    CARD16 length;
    ///
    Window grabWindow;
    ///
    CARD16 modifiers;
    ///
    CARD8 key;
    ///
    BYTE pointerMode, keyboardMode;  
    BYTE pad1, pad2, pad3;
}

///
struct xUngrabKeyReq {
    ///
    CARD8 reqType;
    ///
    CARD8 key;
    ///
    CARD16 length;
    ///
    Window grabWindow;
    ///
    CARD16 modifiers;
    CARD16 pad;
}

///
struct xAllowEventsReq {
    ///
    CARD8 reqType;
    ///
    CARD8 mode;
    ///
    CARD16 length;
    ///
    Time time;
}

///
struct xGetMotionEventsReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Window window;
    ///
    Time start, stop;
}

///
struct xTranslateCoordsReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Window srcWid, dstWid;
    ///
    INT16 srcX, srcY;
}

///
struct xWarpPointerReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Window srcWid, dstWid;
    ///
    INT16 srcX, srcY;
    ///
    CARD16 srcWidth, srcHeight;
    ///
    INT16 dstX, dstY;
}

///
struct xSetInputFocusReq {
    ///
    CARD8 reqType;
    ///
    CARD8 revertTo;
    ///
    CARD16 length;
    ///
    Window focus;
    ///
    Time time;
}

///
struct xOpenFontReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Font fid;
    ///
    CARD16 nbytes;
    /// string follows on word boundary
    BYTE pad1, pad2;
}

///
struct xQueryTextExtentsReq {
    ///
    CARD8 reqType;
    ///
    BOOL oddLength;
    ///
    CARD16 length;
    ///
    Font fid;
}

///
struct xListFontsReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    CARD16 maxNames;
    /// followed immediately by string bytes
    CARD16 nbytes;
}

///
alias xListFontsWithInfoReq = xListFontsReq;

///
struct xSetFontPathReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    CARD16 nFonts;
    /// LISTofSTRING8 follows on word boundary
    BYTE pad1, pad2;
}

///
struct xCreatePixmapReq {
    ///
    CARD8 reqType;
    ///
    CARD8 depth;
    ///
    CARD16 length;
    ///
    Pixmap pid;
    ///
    Drawable drawable;
    ///
    CARD16 width, height;
}

///
struct xCreateGCReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    GContext gc;
    ///
    Drawable drawable;
    ///
    CARD32 mask;
}

///
struct xChangeGCReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    GContext gc;
    ///
    CARD32 mask;
}

///
struct xSetDashesReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    GContext gc;
    ///
    CARD16 dashOffset;
    /// length LISTofCARD8 of values following
    CARD16 nDashes;
}

///
struct xSetClipRectanglesReq {
    ///
    CARD8 reqType;
    ///
    BYTE ordering;
    ///
    CARD16 length;
    ///
    GContext gc;
    ///
    INT16 xOrigin, yOrigin;
}

///
struct xClearAreaReq {
    ///
    CARD8 reqType;
    ///
    BOOL exposures;
    ///
    CARD16 length;
    ///
    Window window;
    ///
    INT16 x, y;
    ///
    CARD16 width, height;
}

///
struct xCopyAreaReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Drawable srcDrawable, dstDrawable;
    ///
    GContext gc;
    ///
    INT16 srcX, srcY, dstX, dstY;
    ///
    CARD16 width, height;
}

///
struct xCopyPlaneReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Drawable srcDrawable, dstDrawable;
    ///
    GContext gc;
    ///
    INT16 srcX, srcY, dstX, dstY;
    ///
    CARD16 width, height;
    ///
    CARD32 bitPlane;
}

///
struct xPolyPointReq {
    ///
    CARD8 reqType;
    ///
    BYTE coordMode;
    ///
    CARD16 length;
    ///
    Drawable drawable;
    ///
    GContext gc;
}

/// same request structure
alias xPolyLineReq = xPolyPointReq;

/// The following used for PolySegment, PolyRectangle, PolyArc, PolyFillRectangle, PolyFillArc
struct xPolySegmentReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Drawable drawable;
    ///
    GContext gc;
}

alias xPolyArcReq = xPolySegmentReq;
alias xPolyRectangleReq = xPolySegmentReq;
alias xPolyFillRectangleReq = xPolySegmentReq;
alias xPolyFillArcReq = xPolySegmentReq;

///
struct xFillPolyReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Drawable drawable;
    ///
    GContext gc;
    ///
    BYTE shape;
    ///
    BYTE coordMode;
    CARD16 pad1;
}

///
struct xPutImageReq {
    ///
    CARD8 reqType;
    ///
    CARD8 format;
    ///
    CARD16 length;
    ///
    Drawable drawable;
    ///
    GContext gc;
    ///
    CARD16 width, height;
    ///
    INT16 dstX, dstY;
    ///
    CARD8 leftPad;
    ///
    CARD8 depth;
    CARD16 pad;
}

///
struct xGetImageReq {
    ///
    CARD8 reqType;
    ///
    CARD8 format;
    ///
    CARD16 length;
    ///
    Drawable drawable;
    ///
    INT16 x, y;
    ///
    CARD16 width, height;
    ///
    CARD32 planeMask;
}

/// the following used by PolyText8 and PolyText16
struct xPolyTextReq {
    ///
    CARD8 reqType;
    CARD8 pad;
    ///
    CARD16 length;
    ///
    Drawable drawable;
    ///
    GContext gc;
    /// items (xTextElt) start after struct
    INT16 x, y;
}

///
alias xPolyText8Req = xPolyTextReq;
///
alias xPolyText16Req = xPolyTextReq;

///
struct xImageTextReq {
    ///
    CARD8 reqType;
    ///
    BYTE nChars;
    ///
    CARD16 length;
    ///
    Drawable drawable;
    ///
    GContext gc;
    ///
    INT16 x, y;
}

///
alias xImageText8Req = xImageTextReq;
///
alias xImageText16Req = xImageTextReq;

///
struct xCreateColormapReq {
    ///
    CARD8 reqType;
    ///
    BYTE alloc;
    ///
    CARD16 length;
    ///
    Colormap mid;
    ///
    Window window;
    ///
    VisualID visual;
}

///
struct xCopyColormapAndFreeReq {
    ///
    CARD8 reqType;
    ///
    BYTE pad;
    ///
    CARD16 length;
    ///
    Colormap mid;
    ///
    Colormap srcCmap;
}

///
struct xAllocColorReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Colormap cmap;
    ///
    CARD16 red, green, blue;
    CARD16 pad2;
}

///
struct xAllocNamedColorReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Colormap cmap;
    /// followed by structure
    CARD16 nbytes;
    BYTE pad1, pad2;
}

///
struct xAllocColorCellsReq {
    ///
    CARD8 reqType;
    ///
    BOOL contiguous;
    ///
    CARD16 length;
    ///
    Colormap cmap;
    ///
    CARD16 colors, planes;
}

///
struct xAllocColorPlanesReq {
    ///
    CARD8 reqType;
    ///
    BOOL contiguous;
    ///
    CARD16 length;
    ///
    Colormap cmap;
    ///
    CARD16 colors, red, green, blue;
}

///
struct xFreeColorsReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Colormap cmap;
    ///
    CARD32 planeMask;
}

///
struct xStoreColorsReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Colormap cmap;
}

///
struct xStoreNamedColorReq {
    ///
    CARD8 reqType;
    /// DoRed, DoGreen, DoBlue, as in xColorItem
    CARD8 flags;
    ///
    CARD16 length;
    ///
    Colormap cmap;
    ///
    CARD32 pixel;
    /// number of name string bytes following structure
    CARD16 nbytes;
    BYTE pad1, pad2;
}

///
struct xQueryColorsReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Colormap cmap;
}

///
struct xLookupColorReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Colormap cmap;
    /// number of string bytes following structure
    CARD16 nbytes;
    /// followed  by string of length len
    BYTE pad1, pad2;
}

///
struct xCreateCursorReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Cursor cid;
    ///
    Pixmap source, mask;
    ///
    CARD16 foreRed, foreGreen, foreBlue;
    ///
    CARD16 backRed, backGreen, backBlue;
    ///
    CARD16 x, y;
}

///
struct xCreateGlyphCursorReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Cursor cid;
    ///
    Font source, mask;
    ///
    CARD16 sourceChar, maskChar;
    ///
    CARD16 foreRed, foreGreen, foreBlue;
    ///
    CARD16 backRed, backGreen, backBlue;
}

///
struct xRecolorCursorReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Cursor cursor;
    ///
    CARD16 foreRed, foreGreen, foreBlue;
    ///
    CARD16 backRed, backGreen, backBlue;
}

///
struct xQueryBestSizeReq {
    ///
    CARD8 reqType;
    ///
    CARD8 c_class;
    ///
    CARD16 length;
    ///
    Drawable drawable;
    ///
    CARD16 width, height;
}

///
struct xQueryExtensionReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    /// number of string bytes following structure
    CARD16 nbytes;
    BYTE pad1, pad2;
}

///
struct xSetModifierMappingReq {
    ///
    CARD8   reqType;
    ///
    CARD8   numKeyPerModifier;
    ///
    CARD16  length;
}

///
struct xGetKeyboardMappingReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    KeyCode firstKeyCode;
    ///
    CARD8 count;
    CARD16 pad1;
}

///
struct xChangeKeyboardMappingReq {
    ///
    CARD8 reqType;
    ///
    CARD8 keyCdes;
    ///
    CARD16 length;
    ///
    KeyCode firstKeyCode;
    ///
    CARD8 keySymsPerKeyCode;
    CARD16 pad1;
}

///
struct xChangeKeyboardControlReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    CARD32 mask;
}

///
struct xBellReq {
    ///
    CARD8 reqType;
    /// -100 to 100
    INT8 percent;
    ///
    CARD16 length;
}

///
struct xChangePointerControlReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    INT16 accelNum, accelDenum;
    ///
    INT16 threshold;
    ///
    BOOL doAccel, doThresh;
}

///
struct xSetScreenSaverReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    INT16 timeout, interval;
    ///
    BYTE preferBlank, allowExpose;
    CARD16 pad2;
}

///
struct xChangeHostsReq {
    ///
    CARD8 reqType;
    ///
    BYTE mode;
    ///
    CARD16 length;
    ///
    CARD8 hostFamily;
    BYTE pad;
    ///
    CARD16 hostLength;
}

///
struct xListHostsReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
}

///
struct xChangeModeReq {
    ///
    CARD8 reqType;
    ///
    BYTE mode;
    ///
    CARD16 length;
}

alias xSetAccessControlReq = xChangeModeReq;
alias xSetCloseDownModeReq = xChangeModeReq;
alias xForceScreenSaverReq = xChangeModeReq;

/// followed by LIST of ATOM
struct xRotatePropertiesReq {
    ///
    CARD8 reqType;
    BYTE pad;
    ///
    CARD16 length;
    ///
    Window window;
    ///
    CARD16 nAtoms;
    ///
    INT16 nPositions;
}

/// Reply codes
enum {
    /// Normal reply
    X_Reply = 1,
    /// Error
    X_Error = 0
}

/// Request codes
enum {
    ///
    X_CreateWindow = 1,              
    ///
    X_ChangeWindowAttributes = 2,        
    ///
    X_GetWindowAttributes = 3,     
    ///
    X_DestroyWindow = 4,
    ///
    X_DestroySubwindows = 5,   
    ///
    X_ChangeSaveSet = 6,
    ///
    X_ReparentWindow = 7,
    ///
    X_MapWindow = 8,
    ///
    X_MapSubwindows = 9,
    ///
    X_UnmapWindow = 10,
    ///
    X_UnmapSubwindows = 11,  
    ///
    X_ConfigureWindow = 12,  
    ///
    X_CirculateWindow = 13,  
    ///
    X_GetGeometry = 14,
    ///
    X_QueryTree = 15,
    ///
    X_InternAtom = 16,
    ///
    X_GetAtomName = 17,
    ///
    X_ChangeProperty = 18, 
    ///
    X_DeleteProperty = 19, 
    ///
    X_GetProperty = 20,
    ///
    X_ListProperties = 21, 
    ///
    X_SetSelectionOwner = 22,    
    ///
    X_GetSelectionOwner = 23,    
    ///
    X_ConvertSelection = 24,   
    ///
    X_SendEvent = 25,
    ///
    X_GrabPointer = 26,
    ///
    X_UngrabPointer = 27,
    ///
    X_GrabButton = 28,
    ///
    X_UngrabButton = 29,
    ///
    X_ChangeActivePointerGrab = 30,          
    ///
    X_GrabKeyboard = 31,
    ///
    X_UngrabKeyboard = 32, 
    ///
    X_GrabKey = 33,
    ///
    X_UngrabKey = 34,
    ///
    X_AllowEvents = 35,       
    ///
    X_GrabServer = 36,      
    ///
    X_UngrabServer = 37,        
    ///
    X_QueryPointer = 38,        
    ///
    X_GetMotionEvents = 39,           
    ///
    X_TranslateCoords = 40,                
    ///
    X_WarpPointer = 41,       
    ///
    X_SetInputFocus = 42,         
    ///
    X_GetInputFocus = 43,         
    ///
    X_QueryKeymap = 44,       
    ///
    X_OpenFont = 45,    
    ///
    X_CloseFont = 46,     
    ///
    X_QueryFont = 47,
    ///
    X_QueryTextExtents = 48,     
    ///
    X_ListFonts = 49,  
    ///
    X_ListFontsWithInfo = 50, 
    ///
    X_SetFontPath = 51, 
    ///
    X_GetFontPath = 52, 
    ///
    X_CreatePixmap = 53,        
    ///
    X_FreePixmap = 54,      
    ///
    X_CreateGC = 55,    
    ///
    X_ChangeGC = 56,    
    ///
    X_CopyGC = 57,  
    ///
    X_SetDashes = 58,     
    ///
    X_SetClipRectangles = 59,             
    ///
    X_FreeGC = 60,  
    ///
    X_ClearArea = 61,             
    ///
    X_CopyArea = 62,    
    ///
    X_CopyPlane = 63,     
    ///
    X_PolyPoint = 64,     
    ///
    X_PolyLine = 65,    
    ///
    X_PolySegment = 66,       
    ///
    X_PolyRectangle = 67,         
    ///
    X_PolyArc = 68,   
    ///
    X_FillPoly = 69,    
    ///
    X_PolyFillRectangle = 70,             
    ///
    X_PolyFillArc = 71,       
    ///
    X_PutImage = 72,    
    ///
    X_GetImage = 73, 
    ///
    X_PolyText8 = 74,     
    ///
    X_PolyText16 = 75,      
    ///
    X_ImageText8 = 76,      
    ///
    X_ImageText16 = 77,       
    ///
    X_CreateColormap = 78,          
    ///
    X_FreeColormap = 79,        
    ///
    X_CopyColormapAndFree = 80,               
    ///
    X_InstallColormap = 81,           
    ///
    X_UninstallColormap = 82,             
    ///
    X_ListInstalledColormaps = 83,                  
    ///
    X_AllocColor = 84,      
    ///
    X_AllocNamedColor = 85,           
    ///
    X_AllocColorCells = 86,           
    ///
    X_AllocColorPlanes = 87,            
    ///
    X_FreeColors = 88,      
    ///
    X_StoreColors = 89,       
    ///
    X_StoreNamedColor = 90,           
    ///
    X_QueryColors = 91,       
    ///
    X_LookupColor = 92,       
    ///
    X_CreateCursor = 93,        
    ///
    X_CreateGlyphCursor = 94,             
    ///
    X_FreeCursor = 95,      
    ///
    X_RecolorCursor = 96,         
    ///
    X_QueryBestSize = 97,         
    ///
    X_QueryExtension = 98,          
    ///
    X_ListExtensions = 99,          
    ///
    X_ChangeKeyboardMapping = 100,
    ///
    X_GetKeyboardMapping = 101,
    ///
    X_ChangeKeyboardControl = 102,                
    ///
    X_GetKeyboardControl = 103,             
    ///
    X_Bell = 104,
    ///
    X_ChangePointerControl = 105,
    ///
    X_GetPointerControl = 106,
    ///
    X_SetScreenSaver = 107,          
    ///
    X_GetScreenSaver = 108,          
    ///
    X_ChangeHosts = 109,       
    ///
    X_ListHosts = 110,     
    ///
    X_SetAccessControl = 111,               
    ///
    X_SetCloseDownMode = 112,
    ///
    X_KillClient = 113, 
    ///
    X_RotateProperties = 114,
    ///
    X_ForceScreenSaver = 115,
    ///
    X_SetPointerMapping = 116,
    ///
    X_GetPointerMapping = 117,
    ///
    X_SetModifierMapping = 118,
    ///
    X_GetModifierMapping = 119,
    ///
    X_NoOperation = 127
}