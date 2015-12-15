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
module std.experimental.bindings.x11.X;

///
enum X_PROTOCOL = 11;

///
enum X_PROTOCOL_REVISION = 0;

/* Resources */

/*
 * _XSERVER64 must ONLY be defined when compiling X server sources on
 * systems where unsigned long is not 32 bits, must NOT be used in
 * client or library code.
 *
 * We can safely ignore the mess that is _XSERVER64.
 * So it has been removed.
 */

/// 
alias XID = uint;

///
alias Mask = uint;

///
alias Atom = uint;

///
alias VisualID = uint;

///
alias Time = uint;

///
alias Window = XID;

///
alias Drawable = XID;

///
alias Font = XID;

///
alias Pixmap = XID;

///
alias Cursor = XID;

///
alias Colormap = XID;

///
alias GContext = XID;

///
alias KeySym = XID;

///
alias KeyCode = ubyte;

/*****************************************************************
 * RESERVED RESOURCE AND CONSTANT DEFINITIONS
 *****************************************************************/

///
enum {
    /// universal null resource or null atom
    None = 0,
    
    /// background pixmap in CreateWindow and ChangeWindowAttributes
    ParentRelative = 1,
    
    /**
     * border pixmap in CreateWindow
     * and ChangeWindowAttributes
     * special VisualID and special window
     * class passed to CreateWindow
     */
    CopyFromParent = 0,
    
    /// destination window in SendEvent
    PointerWindow = 0,
    
    /// destination window in SendEvent 
    InputFocus = 1,
     
    /// focus window in SetInputFocus
    PointerRoot = 1,
    
    /// special Atom, passed to GetProperty
    AnyPropertyType = 0,
    
    /// special Key Code, passed to GrabKey
    AnyKey = 0,
    
    /// special Button Code, passed to GrabButton
    AnyButton = 0,
    
    /// special Resource ID passed to KillClient
    AllTemporary = 0,
    
    /// special Time
    CurrentTime = 0,
    
    /// special KeySym
    NoSymbol = 0
}

/***************************************************************** 
 * EVENT DEFINITIONS 
 *****************************************************************/

/**
 * Input Event Masks. Used as event-mask window attribute and as arguments
 *  to Grab requests.  Not to be confused with event names.
 */
enum {
    ///
    NoEventMask = 0,
    
    ///
    KeyPressMask = 1 << 0,
    
    ///
    KeyReleaseMask = 1 << 1,
    
    ///
    ButtonPressMask = 1 << 2,
    
    ///
    ButtonReleaseMask = 1 << 3,
    
    ///
    EnterWindowMask = 1 << 4,
    
    ///
    LeaveWindowMask = 1 << 5,
    
    ///
    PointerMotionMask = 1 << 6,
    
    ///
    PointerMotionHintMask = 1 << 7,
    
    ///
    Button1MotionMask = 1 << 8,
    
    ///
    Button2MotionMask = 1 << 9,
    
    ///
    Button3MotionMask = 1 << 10,
    
    ///
    Button4MotionMask = 1 << 11,
    
    ///
    Button5MotionMask = 1 << 12,
    
    ///
    ButtonMotionMask = 1 << 13,
    
    ///
    KeymapStateMask = 1 << 14,
    
    ///
    ExposureMask = 1 << 15,
    
    ///
    VisibilityChangeMask = 1 << 16,
    
    ///
    StructureNotifyMask = 1 << 17,
    
    ///
    ResizeRedirectMask = 1 << 18,
    
    ///
    SubstructureNotifyMask = 1 << 19,
    
    ///
    SubstructureRedirectMask = 1 << 20,
    
    ///
    FocusChangeMask = 1 << 21,
    
    ///
    PropertyChangeMask = 1 << 22,
    
    ///
    ColormapChangeMask = 1 << 23,
    
    ///
    OwnerGrabButtonMask = 1 << 24
}

/**
 * Event names.  Used in "type" field in XEvent structures.  Not to be
 * confused with event masks above.  They start from 2 because 0 and 1
 * are reserved in the protocol for errors and replies.
 */
enum {
    ///
    KeyPress = 2,
    
    ///
    KeyRelease = 3,
    
    ///
    ButtonPress = 4,
    
    ///
    ButtonRelease = 5,
    
    ///
    MotionNotify = 6,
    
    ///
    EnterNotify = 7,
    
    ///
    LeaveNotify = 8,
    
    ///
    FocusIn = 9,
    
    ///
    FocusOut = 10,
    
    ///
    KeymapNotify = 11,
    
    ///
    Expose = 12,
    
    ///
    GraphicsExpose = 13,
    
    ///
    NoExpose = 14,
    
    ///
    VisibilityNotify = 15,
    
    ///
    CreateNotify = 16,
    
    ///
    DestroyNotify = 17,
    
    ///
    UnmapNotify = 18,
    
    ///
    MapNotify = 19,
    
    ///
    MapRequest = 20,
    
    ///
    ReparentNotify = 21,
    
    ///
    ConfigureNotify = 22,
    
    ///
    ConfigureRequest = 23,
    
    ///
    GravityNotify = 24,
    
    ///
    ResizeRequest = 25,
    
    ///
    CirculateNotify = 26,
    
    ///
    CirculateRequest = 27,
    
    ///
    PropertyNotify = 28,
    
    ///
    SelectionClear = 29,
    
    ///
    SelectionRequest = 30,
    
    ///
    SelectionNotify = 31,
    
    ///
    ColormapNotify = 32,
    
    ///
    ClientMessage = 33,
    
    ///
    MappingNotify = 34,
    
    ///
    GenericEvent = 35,
    
    /// must be bigger than any event #
    LASTEvent = 36
}

/**
 * Key masks. Used as modifiers to GrabButton and GrabKey, results of QueryPointer,
 * state in various key-, mouse-, and button-related events.
 */
enum {
    ///
    ShiftMask = (1<<0),
    
    ///
    LockMask = (1<<1),
    
    ///
    ControlMask = (1<<2),
    
    ///
    Mod1Mask = (1<<3),
    
    ///
    Mod2Mask = (1<<4),
    
    ///
    Mod3Mask = (1<<5),
    
    ///
    Mod4Mask = (1<<6),
    
    ///
    Mod5Mask = (1<<7)
}

/**
 * modifier names.  Used to build a SetModifierMapping request or
 * to read a GetModifierMapping request.  These correspond to the
 * masks defined above.
*/
enum {
    ///
    ShiftMapIndex = 0,
    
    ///
    LockMapIndex = 1,
    
    ///
    ControlMapIndex = 2,
    
    ///
    Mod1MapIndex = 3,
    
    ///
    Mod2MapIndex = 4,
    
    ///
    Mod3MapIndex = 5,
    
    ///
    Mod4MapIndex = 6,
    
    ///
    Mod5MapIndex = 7,
}

/**
 * button masks.  Used in same manner as Key masks above. Not to be confused
 * with button names below.
 */
enum {
    ///
    Button1Mask = (1<<8),
    
    ///
    Button2Mask = (1<<9),
    
    ///
    Button3Mask = (1<<10),
    
    ///
    Button4Mask = (1<<11),
    
    ///
    Button5Mask = (1<<12),
    
    /// used in GrabButton, GrabKey
    AnyModifier = (1<<15)
}

/**
 * button names. Used as arguments to GrabButton and as detail in ButtonPress
 * and ButtonRelease events.  Not to be confused with button masks above.
 * Note that 0 is already defined above as "AnyButton".
 */
enum {
    ///
    Button1 = 1,
    
    ///
    Button2 = 2,
    
    ///
    Button3 = 3,
    
    ///
    Button4 = 4,
    
    ///
    Button5 = 5
}

/// Notify modes
enum {
    ///
    NotifyNormal = 0,
    
    ///
    NotifyGrab = 1,
    
    ///
    NotifyUngrab = 2,
    
    ///
    NotifyWhileGrabbed = 3
}

/// for MotionNotify events
enum NotifyHint = 1;

/// Notify detail
enum {
    ///
    NotifyAncestor = 0,
    
    ///
    NotifyVirtual = 1,
    
    ///
    NotifyInferior = 2,
    
    ///
    NotifyNonlinear = 3,
    
    ///
    NotifyNonlinearVirtual = 4,
    
    ///
    NotifyPointer = 5,
    
    ///
    NotifyPointerRoot = 6,
    
    ///
    NotifyDetailNone = 7
}

/// Visibility notify
enum {
    ///
    VisibilityUnobscured = 0,
    
    ///
    VisibilityPartiallyObscured = 1,
    
    ///
    VisibilityFullyObscured = 2
}

/// Circulation request
enum {
    ///
    PlaceOnTop = 0,
    
    ///
    PlaceOnBottom = 1
}

/// protocol families
enum {
    /// IPv4
    FamilyInternet = 0,
    
    ///
    FamilyDECnet = 1,
    
    ///
    FamilyChaos = 2,
    
    /// IPv6
    FamilyInternet6 = 6
}

/// authentication families not tied to a specific protocol
enum FamilyServerInterpreted = 5;

/// Property notification
enum {
    ///
    PropertyNewValue = 0,
    
    ///
    PropertyDelete = 1
}

/// Color Map notification
enum {
    ///
    ColormapUninstalled = 0,
    
    ///
    ColormapInstalled = 1
}

/// GrabPointer, GrabButton, GrabKeyboard, GrabKey Modes
enum {
    ///
    GrabModeSync = 0,
    
    ///
    GrabModeAsync = 1
}

/// GrabPointer, GrabKeyboard reply status
enum {
    ///
    GrabSuccess = 0,
    
    ///
    AlreadyGrabbed = 1,
    
    ///
    GrabInvalidTime = 2,
    
    ///
    GrabNotViewable = 3,
    
    ///
    GrabFrozen = 4
}

/// AllowEvents modes
enum {
    ///
    AsyncPointer = 0,
    
    ///
    SyncPointer = 1,
    
    ///
    ReplayPointer = 2,
    
    ///
    AsyncKeyboard = 3,
    
    ///
    SyncKeyboard = 4,
    
    ///
    ReplayKeyboard = 5,
    
    ///
    AsyncBoth = 6,
    
    ///
    SyncBoth = 7
}

/// Used in SetInputFocus, GetInputFocus
enum {
    ///
    RevertToNone = None,
    
    ///
    RevertToPointerRoot = PointerRoot,
    
    ///
    RevertToParent = 2
}

/*****************************************************************
 * ERROR CODES 
 *****************************************************************/
 enum {
    /// everything's okay
    Success = 0,
    
    /// bad request code
    BadRequest = 1,
    
    /// int parameter out of range
    BadValue = 2,
    
    /// parameter not a Window
    BadWindow = 3,
    
    /// parameter not a Pixmap 
    BadPixmap = 4,
    
    /// parameter not an Atom
    BadAtom = 5,
    
    /// parameter not a Cursor
    BadCursor = 6,
    
    /// parameter not a Font
    BadFont = 7,
    
    /// parameter mismatch
    BadMatch = 8,
    
    /// parameter not a Pixmap or Window
    BadDrawable = 9,
    
    /**
     * depending on context:
     * $(UL
     *      $(LI key/button already grabbed)
     *      $(LI attempt to free an illegal cmap entry) 
     *      $(LI attempt to store into a read-only color map entry.)
     *      $(LI attempt to modify the access control list from other than the local host.)
     * )
     */
     BadAccess = 10,
     
     /// insufficient resources
     BadAlloc = 11,
     
     /// no such colormap
     BadColor = 12,
     
     /// parameter not a GC
     BadGC = 13,
     
     /// choice not in range or already used
     BadIDChoice = 14,
     
     /// font or color name doesn't exist
     BadName = 15,
     
     /// Request length incorrect
     BadLength = 16,
     
     /// server is defective
     BadImplementation = 17
 }

///
enum FirstExtensionError = 128;

///
enum LastExtensionError = 255;

/*****************************************************************
 * WINDOW DEFINITIONS 
 *****************************************************************/
 
/* Window classes used by CreateWindow */
/* Note that CopyFromParent is already defined as 0 above */

///
enum {
    ///
    InputOutput = 1,
    
    ///
    InputOnly = 2
}

/// Window attributes for CreateWindow and ChangeWindowAttributes
enum {
    ///
    CWBackPixmap = 1 << 0,
    
    ///
    CWBackPixel = 1 << 1,
    
    ///
    CWBorderPixmap = 1 << 2,
    
    ///
    CWBorderPixel = 1 << 3,
    
    ///
    CWBitGravity = 1 << 4,
    
    ///
    CWWinGravity = 1 << 5,
    
    ///
    CWBackingStore = 1 << 6,
    
    ///
    CWBackingPlanes = 1 << 7,
    
    ///
    CWBackingPixel = 1 << 8,
    
    ///
    CWOverrideRedirect = 1 << 9,
    
    ///
    CWSaveUnder = 1 << 10,
    
    ///
    CWEventMask = 1 << 11,
    
    ///
    CWDontPropagate = 1 << 12,
    
    ///
    CWColormap = 1 << 13,
    
    ///
    CWCursor = 1 << 14
}

/// ConfigureWindow structure
enum {
    ///
    CWX = 1 << 0,
    
    ///
    CWY = 1 << 1,
    
    ///
    CWWidth = 1 << 2,
    
    ///
    CWHeight = 1 << 3,
    
    ///
    CWBorderWidth = 1 << 4,
    
    ///
    CWSibling = 1 << 5,
    
    ///
    CWStackMode = 1 << 6 
}

/// Bit Gravity
enum {
    ///
    ForgetGravity = 0,
    
    ///
    NorthWestGravity = 1,
    
    ///
    NorthGravity = 2,
    
    ///
    NorthEastGravity = 3,
    
    ///
    WestGravity = 4,
    
    ///
    SouthWestGravity = 7,
    
    ///
    SouthGravity = 8,
    
    ///
    SouthEastGravity = 9,
    
    ///
    StaticGravity = 10
}

/// Window gravity + bit gravity above
enum UnmapGravity = 0;

/// Used in CreateWindow for backing-store hint
enum {
    ///
    NotUseful = 0,
    
    ///
    WhenMapped = 1,
    
    ///
    Always = 2
}

/// Used in GetWindowAttributes reply
enum {
    ///
    IsUnmapped = 0,
    
    ///
    IsUnviewable = 1,
    
    ///
    IsViewable = 2
}

/// Used in ChangeSaveSet
enum {
    ///
    SetModeInsert = 0,
    
    ///
    SetModeDelete = 1
}

/// Used in ChangeCloseDownMode
enum {
    ///
    DestroyAll = 0,
    
    ///
    RetainPermanent = 1,
    
    ///
    RetainTemporary = 2
}

/// Window stacking method (in configureWindow)
enum {
    ///
    Above = 0,
    
    ///
    Below = 1,
    
    ///
    TopIf = 2,
    
    ///
    BottomIf = 3,
    
    ///
    Opposite = 4
}

/// Circulation direction
enum {
    ///
    RaiseLowest = 0,
    
    ///
    LowerHighest = 1
}

/// Property modes
enum {
    ///
    PropModeReplace = 0,
    
    ///
    PropModePrepend = 1,
    
    ///
    PropModeAppend = 2
}

/*****************************************************************
 * GRAPHICS DEFINITIONS
 *****************************************************************/

/// graphics functions, as in GC.alu
enum {
    /// 0
    GXClear = 0,
    
    /// src AND dst
    GXand = 0x1,
    
    /// src AND NOT dst
    GXandReverse = 0x2,
    
    /// src
    GXcopy = 0x3,
    
    /// NOT src AND dst
    GXandInverted = 0x4,
    
    /// dst
    GXnoop = 0x5,
    
    /// src XOR dst
    GXxor = 0x6,
    
    /// src OR dst
    GXor = 0x7,
    
    /// NOT src AND NOT dst
    GXnor = 0x8,
    
    /// NOT src XOR dst
    GXequiv = 0x9,
    
    /// NOT dst
    GXinvert = 0xa,
    
    /// src OR NOT dst
    GXorReverse = 0xb,
    
    /// NOT src
    GXcopyInverted = 0xc,
    
    /// NOT src OR dst
    GXorInverted = 0xd,
    
    /// NOT src OR NOT dst
    GXnand = 0xe,
    
    /// 1
    GXset = 0xf
}

/// LineStyle
enum {
    ///
    LineSolid = 0,
    
    ///
    LineOnOffDash = 1,
    
    ///
    LineDoubleDash = 2
}

/// capStyle
enum {
    ///
    CapNotLast = 0,
    
    ///
    CapButt = 1,
    
    ///
    CapRound = 2,
    
    ///
    CapProjecting = 3,
}

/// joinStyle
enum {
    ///
    JoinMiter = 0,
    
    ///
    JoinRound = 1,
    
    ///
    JoinBevel = 2
}

/// fillStyle
enum {
    ///
    FillSolid = 0,
    
    ///
    FillTiled = 1,
    
    ///
    FillStippled = 2,
    
    ///
    FillOpaqueStippled = 3
}

/// fillRule
enum {
    ///
    EvenOddRule = 0,
    
    ///
    WindingRule = 1
}

/// subwindow mode
enum {
    ///
    ClipByChildren = 0,
    
    ///
    IncludeInferiors = 1
}

/// SetClipRectangles ordering
enum {
    ///
    Unsorted = 0,
    
    ///
    YSorted = 1,
    
    ///
    YXSorted = 2,
    
    ///
    YXBanded = 3
}

/// CoordinateMode for drawing routines
enum {
    /// relative to the origin
    CoordModeOrigin = 0,
    
    /// relative to previous point
    CoordModePrevious = 1
}

/// Polygon shapes
enum {
    /// paths may intersect
    Complex = 0,
    
    /// no paths intersect, but not convex
    Nonconvex = 1,
    
    /// wholly convex
    Convex = 2
}

/// Arc modes for PolyFillArc
enum {
    /// join endpoints of arc
    ArcChord = 0,
    
    /// join endpoints to center of arc
    ArcPieSlice = 1
}

/// GC components: masks used in CreateGC, CopyGC, ChangeGC, OR'ed into GC.stateChanges
enum {
    ///
    GCFunction = 1 << 0,
    
    ///
    GCPlaneMask = 1 << 1,
    
    ///
    GCForeground = 1 << 2,
    
    ///
    GCBackground = 1 << 3,
    
    ///
    GCLineWidth = 1 << 4,
    
    ///
    GCLineStyle = 1 << 5,
    
    ///
    GCCapStyle = 1 << 6,
    
    ///
    GCJoinStyle = 1 << 7,
    
    ///
    GCFillStyle = 1 << 8,
    
    ///
    GCFillRule = 1 << 9,
    
    ///
    GCTile = 1 << 10,
    
    ///
    GCStipple = 1 << 11,
    
    ///
    GCTileStipXOrigin = 1 << 12,
    
    ///
    GCTileStipYOrigin = 1 << 13,
    
    ///
    GCFont = 1 << 14,
    
    ///
    GCSubwindowMode = 1 << 15,
    
    ///
    GCGraphicsExposures = 1 << 16,
    
    ///
    GCClipXOrigin = 1 << 17,
    
    ///
    GCClipYOrigin = 1 << 18,
    
    ///
    GCClipMask = 1 << 19,
    
    ///
    GCDashOffset = 1 << 20,
    
    ///
    GCDashList = 1 << 21,
    
    ///
    GCArcMode = 1 << 22
}

///
enum GCLastBit = 22;

/*****************************************************************
 * FONTS 
 *****************************************************************/

/// used in QueryFont -- draw direction
enum {
    ///
    FontLeftToRight = 0,
    
    ///
    FontRightToLeft = 1
}

///
enum FontChange = 255;

/*****************************************************************
 *  IMAGING 
 *****************************************************************/

/// ImageFormat -- PutImage, GetImage
enum {
    /// depth 1, XYFormat
    XYBitmap = 0,
    
    /// depth == drawable depth
    XYPixmap = 1,
    
    /// depth == drawable depth
    ZPixmap = 2
}

/*****************************************************************
 *  COLOR MAP STUFF 
 *****************************************************************/

/// For CreateColormap
enum {
    /// create map with no entries
    AllocNone = 0,
    
    /// allocate entire map writeable
    AllocAll = 1
}

/// Flags used in StoreNamedColor, StoreColors
enum {
    ///
    DoRed = 1 << 0,
    
    ///
    DoGreen = 1 << 1,
    
    ///
    DoBlue = 1 << 2
}

/*****************************************************************
 * CURSOR STUFF
 *****************************************************************/
 
/// QueryBestSize Class
enum {
    /// largest size that can be displayed
    CursorShape = 0,
    
    /// size tiled fastest
    TileShape = 1,
    
    /// size stippled fastest
    StippleShape = 2
}

/***************************************************************** 
 * KEYBOARD/POINTER STUFF
 *****************************************************************/

///
enum {
    ///
    AutoRepeatModeOff = 0,
    
    ///
    AutoRepeatModeOn = 1,
    
    ///
    AutoRepeatModeDefault = 2,
    
    ///
    LedModeOff = 0,
    
    ///
    LedModeOn = 1
}

/// masks for ChangeKeyboardControl
enum {
    ///
    KBKeyClickPercent = 1 << 0,
    
    ///
    KBBellPercent = 1 << 1,
    
    ///
    KBBellPitch = 1 << 2,
    
    ///
    KBBellDuration = 1 << 3,
    
    ///
    KBLed = 1 << 4,
    
    ///
    KBLedMode = 1 << 5,
    
    ///
    KBKey = 1 << 6,
    
    ///
    KBAutoRepeatMode = 1 << 7
}

///
enum {
    ///
    MappingSuccess = 0,
    
    ///
    MappingBusy = 1,
    
    ///
    MappingFailed = 2,
    
    ///
    MappingModifier = 0,
    
    ///
    MappingKeyboard = 1,
    
    ///
    MappingPointer = 2
}

/*****************************************************************
 * SCREEN SAVER STUFF 
 *****************************************************************/

///
enum {
    ///
    DontPreferBlanking = 0,
    
    ///
    PreferBlanking = 1,
    
    ///
    DefaultBlanking = 2,
    
    ///
    DisableScreenSaver = 0,
    
    ///
    DisableScreenInterval = 0,
    
    ///
    DontAllowExposures = 0,
    
    ///
    AllowExposures = 1,
    
    ///
    DefaultExposures = 2
}

/// for ForceScreenSaver
enum {
    ///
    ScreenSaverReset = 0,
    
    ///
    ScreenSaverActive = 1
}

/*****************************************************************
 * HOSTS AND CONNECTIONS
 *****************************************************************/

/// for ChangeHosts
enum {
    ///
    HostInsert = 0,
    
    ///
    HostDelete = 0
}

/// for ChangeAccessControl
enum {
    ///
    EnableAccess = 1,
    
    ///
    DisableAccess = 0
}

/**
 * Display classes  used in opening the connection 
 * Note that the statically allocated ones are even numbered and the
 * dynamically changeable ones are odd numbered
 */
enum {
    ///
    StaticGray = 0,
    
    ///
    GrayScale = 1,
    
    ///
    StaticColor = 2,
    
    ///
    PseudoColor = 3,
    
    ///
    TrueColor = 4,
    
    ///
    DirectColor = 5
}

/// Byte order  used in imageByteOrder and bitmapBitOrder
enum {
    ///
    LSBFirst = 0,
    
    ///
    MSBFirst
}
