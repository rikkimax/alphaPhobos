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
 * Authors:
 * 		Jim Gettys, HP Labs, Hewlett-Packard, Inc.
 *	    Keith Packard, Intel Corporation
 */
module std.experimental.bindings.x11.extensions.randr;
import core.stdc.config : c_long, c_ulong;

///
alias Rotation = ushort;
///
alias SizeID = ushort;
///
alias SubpixelOrder = ushort;
///
alias Connection = ushort;
///
alias XRandrRotation = ushort;
///
alias XRandrSizeID = ushort;
///
alias XRandrSubpixelOrder = ushort;
///
alias XRandrModeFlags = c_ulong;

///
enum {
	///
	RANDR_NAME = "RANDR",
	///
	RANDR_MAJOR = 1,
	///
	RANDR_MINOR = 4
}

///
enum {
	///
	RRNumberErrors = 4,
	///
	RRNumberEvents = 2,
	///
	RRNumberRequests = 42,
}

///
enum {
	/// we skip 1 to make old clients fail pretty immediately
	X_RRQueryVersion = 0,
	///
	X_RROldGetScreenInfo = 1,
	/// V1.0 apps share the same set screen config request id
	X_RR1_0SetScreenConfig = 2,
	///
	X_RRSetScreenConfig = 2,
	/// 3 used to be ScreenChangeSelectInput; deprecated 
	X_RROldScreenChangeSelectInput = 3,
	///
	X_RRSelectInput = 4,
	///
	X_RRGetScreenInfo = 5
}

// V1.2 additions

///
enum {
	///
	X_RRGetScreenSizeRange = 6,
	///
	X_RRSetScreenSize = 7,
	///
	X_RRGetScreenResources = 8,
	///
	X_RRGetOutputInfo = 9,
	///
	X_RRListOutputProperties = 10,
	///
	X_RRQueryOutputProperty = 11,
	///
	X_RRConfigureOutputProperty = 12,
	///
	X_RRChangeOutputProperty = 13,
	///
	X_RRDeleteOutputProperty = 14,
	///
	X_RRGetOutputProperty = 15,
	///
	X_RRCreateMode = 16,
	///
	X_RRDestroyMode = 17,
	///
	X_RRAddOutputMode = 18,
	///
	X_RRDeleteOutputMode = 19,
	///
	X_RRGetCrtcInfo = 20,
	///
	X_RRSetCrtcConfig = 21,
	///
	X_RRGetCrtcGammaSize = 22,
	///
	X_RRGetCrtcGamma = 23,
	///
	X_RRSetCrtcGamma = 24
}

// V1.3 additions

///
enum {
	///
	X_RRGetScreenResourcesCurrent = 25,
	///
	X_RRSetCrtcTransform = 26,
	///
	X_RRGetCrtcTransform = 27,
	///
	X_RRGetPanning = 28,
	///
	X_RRSetPanning = 29,
	///
	X_RRSetOutputPrimary = 30,
	///
	X_RRGetOutputPrimary = 31
}

///
enum {
	///
	RRTransformUnit = 1 << 0,
	///
	RRTransformScaleUp = 1 << 1,
	///
	RRTransformScaleDown = 1 << 2,
	///
	RRTransformProjective = 1 << 3,
}

// v1.4

///
enum {
	///
	X_RRGetProviders = 32,
	///
	X_RRGetProviderInfo = 33,
	///
	X_RRSetProviderOffloadSink = 34,
	///
	X_RRSetProviderOutputSource = 35,
	///
	X_RRListProviderProperties = 36,
	///
	X_RRQueryProviderProperty = 37,
	///
	X_RRConfigureProviderProperty = 38,
	///
	X_RRChangeProviderProperty = 39,
	///
	X_RRDeleteProviderProperty = 40,
	///
	X_RRGetProviderProperty = 41
}

///
enum {
	/// Event selection bits
	RRScreenChangeNotifyMask = 1 << 0,

	// V1.2 additions

	///
	RRCrtcChangeNotifyMask = 1 << 1,
	///
	RROutputChangeNotifyMask = 1 << 2,
	///
	RROutputPropertyNotifyMask = 1 << 3,

	// V1.4

	///
	RRProviderChangeNotifyMask = 1 << 4,
	///
	RRProviderPropertyNotifyMask = 1 << 5,
	///
	RRResourceChangeNotifyMask = 1 << 6
}

/// Event codes
enum {
	///
	RRScreenChangeNotify = 0,

	// V1.2 additions

	///
	RRNotify = 1,

	// RRNotifySubcodes

	///
	RRNotify_CrtcChange = 0,
	///
	RRNotify_OutputChange = 1,
	///
	RRNotify_OuputProperty = 2,
	///
	RRNotify_ProviderChange = 3,
	///
	RRNotify_ProviderProperty = 4,
	///
	RRNotify_ResourceChange = 5
}

/// used in the rotation field; rotation and reflection in 0.1 proto.
enum {
	///
	RR_Rotate_0 = 1,
	///
	RR_Rotate_90 = 2,
	///
	RR_Rotate_180 = 4,
	///
	RR_Rotate_270 = 8,

	// new in 1.0 protocol, to allow reflection of screen

	///
	RR_Reflect_X = 16,
	///
	RR_Reflect_Y = 32
}

///
enum {
	///
	RRSetConfigSuccess = 0,
	///
	RRSetConfigInvalidConfigTime = 1,
	///
	RRSetConfigInvalidTime = 2,
	///
	RRSetConfigFailed = 3
}

// new in 1.2 protocol

///
enum {
	///
	RR_HSyncPositive = 0x00000001,
	///
	RR_HSyncNegative = 0x00000002,
	///
	RR_VSyncPositive = 0x00000004,
	///
	RR_VSyncNegative = 0x00000008,
	///
	RR_Interlace = 0x00000010,
	///
	RR_DoubleScan = 0x00000020,
	///
	RR_CSync = 0x00000040,
	///
	RR_CSyncPositive = 0x00000080,
	///
	RR_CSyncNegative = 0x00000100,
	///
	RR_HSkewPresent = 0x00000200,
	///
	RR_BCast = 0x00000400,
	///
	RR_PixelMultiplex = 0x00000800,
	///
	RR_DoubleClock = 0x00001000,
	///
	RR_ClockDivideBy2 = 0x00002000
}

///
enum {
	///
	RR_Connected = 0,
	///
	RR_Disconnected = 1,
	///
	RR_UnknownConnection = 2
}

///
enum {
	///
	BadRROutput = 0,
	///
	BadRRCrtc = 1,
	///
	BadRRMode = 2,
	///
	BadRRProvider = 3
}

/// Conventional RandR output properties
enum {
	///
	RR_PROPERTY_BACKLIGHT = "Backlight",
	///
	RR_PROPERTY_RANDR_EDID = "EDID",
	///
	RR_PROPERTY_SIGNAL_FORMAT = "SignalFormat",
	///
	RR_PROPERTY_SIGNAL_PROPERTIES = "SignalProperties",
	///
	RR_PROPERTY_CONNECTOR_TYPE = "ConnectorType",
	///
	RR_PROPERTY_CONNECTOR_NUMBER = "ConnectorNumber",
	///
	RR_PROPERTY_COMPATIBILITY_LIST = "CompatibilityList",
	///
	RR_PROPERTY_CLONE_LIST = "CloneList",
	///
	RR_PROPERTY_BORDER = "Border",
	///
	RR_PROPERTY_BORDER_DIMENSIONS = "BorderDimensions"
}

/// roles this device can carry out
enum {
	///
	RR_Capability_None = 0,
	///
	RR_Capability_SourceOutput = 1,
	///
	RR_Capability_SinkOutput = 2,
	///
	RR_Capability_SourceOffload = 4,
	///
	RR_Capability_SinkOffloat = 8
}
