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
module std.experimental.bindings.x11.Xresource;
import std.experimental.bindings.x11.Xlib;
import core.stdc.string : strcmp;
import core.stdc.config : c_long, c_ulong;
__gshared extern(C):

/****************************************************************
 ****************************************************************
 ***                                                          ***
 ***                                                          ***
 ***          X Resource Manager Intrinsics                   ***
 ***                                                          ***
 ***                                                          ***
 ****************************************************************
 ****************************************************************/

/****************************************************************
 *
 * Memory Management
 *
 ****************************************************************/

///
char* function(uint size) Xpermalloc;

/****************************************************************
 *
 * Quark Management
 *
 ****************************************************************/

///
alias XrmQuark = int;
///
alias XrmQuarkList = int*;
///
enum NULLQUARK = cast(XrmQuark)0;

///
alias XrmString = char*;
///
enum NULLSTRING = cast(XrmString)0;

/// find quark for string, create new quark if none already exists */
XrmQuark function(const char* string_) XrmStringToQuark;
///
XrmQuark function(const char* string_) XrmPermStringToQuark;

/// find string for quark
XrmString function(XrmQuark quark) XrmQuarkToString;

///
XrmQuark function() XrmUniqueQuark;

///
bool XrmStringsEqual(XrmString a1, XrmString a2) { return strcmp(a1, a2) == 0; }

/****************************************************************
 *
 * Conversion of Strings to Lists
 *
 ****************************************************************/

///
enum XrmBinding {
	///
	XrmBindTightly,
	///
	XrmBindLoosely
}
///
alias XrmBindingList = XrmBinding*;

///
void function(const char* string_, XrmQuarkList quarks_return) XrmStringToQuarkList;
///
void function(const char* string_,	XrmBindingList bindings_return, XrmQuarkList quarks_return) XrmStringToBindingQuarkList;

/****************************************************************
 *
 * Name and Class lists.
 *
 ****************************************************************/

///
alias XrmName = XrmQuark;
///
alias XrmNameList = XrmQuarkList;
///
XrmString XrmNameToString(XrmQuark name) { return XrmQuarkToString(name); }
///
XrmQuark XrmStringToName(const char* string_) { return XrmStringToQuark(string_); }
///
void XrmStringToNameList(const char* str, XrmQuarkList name) { XrmStringToQuarkList(str, name); }

///
alias XrmClass = XrmQuark;
///
alias XrmClassList = XrmQuarkList;
///
XrmString XrmClassToString(XrmQuark c_class) { return XrmQuarkToString(c_class); }
///
XrmQuark XrmStringToClass(XrmString c_class) { return XrmStringToQuark(c_class); }
///
void XrmStringToClassList(const char* str, XrmQuarkList c_class) { XrmStringToQuarkList(str, c_class); }

/****************************************************************
 *
 * Resource Representation Types and Values
 *
 ****************************************************************/

///
alias XrmRepresentation = XrmQuark;
///
XrmQuark XrmStringToRepresentation(XrmString string_) { return XrmStringToQuark(string_); }
///
XrmString XrmRepresentationToString(XrmQuark type) { return XrmQuarkToString(type); }

///
struct XrmValue {
	///
	uint size;
	///
	XPointer addr;
}

///
alias XrmValuePtr = XrmValue*;

/****************************************************************
 *
 * Resource Manager Functions
 *
 ****************************************************************/

///
alias XrmHashBucket = _XrmHashBucketRec*;
///
alias XrmHashTable = XrmHashBucket*;
///
alias XrmSearchList = XrmHashTable[];
///
alias XrmDatabase = _XrmHashBucketRec*;

///
void function(XrmDatabase database) XrmDestroyDatabase;
///
void function(XrmDatabase* database, XrmBindingList bindings, XrmQuarkList quarks, XrmRepresentation type, XrmValue* value) XrmQPutResource;
///
void function(XrmDatabase* database, const char* specifier, const char* type, XrmValue* value) XrmPutResource;
///
void function(XrmDatabase* database, XrmBindingList bindings, XrmQuarkList quarks, const char* value) XrmQPutStringResource;
///
void function(XrmDatabase* database, const char* specifier, const char* value) XrmPutStringResource;
///
void function(XrmDatabase* database, const char* line) XrmPutLineResource;
///
Bool function(XrmDatabase database, XrmNameList quark_name, XrmClassList quark_class, XrmRepresentation* quark_type_return, XrmValue* value_return) XrmQGetResource;
///
Bool function(XrmDatabase database, const char* str_name, const char* str_class, char** str_type_return, XrmValue* value_return) XrmGetResource;
///
Bool function(XrmDatabase database, XrmNameList names, XrmClassList classes, XrmSearchList list_return, int list_length) XrmQGetSearchList;
///
Bool function(XrmSearchList list, XrmName name, XrmClass class_, XrmRepresentation* type_return, XrmValue* value_return) XrmQGetSearchResource;

/****************************************************************
 *
 * Resource Database Management
 *
 ****************************************************************/

///
version(_XP_PRINT_SERVER_) {
} else {
	///
	void function(Display* display, XrmDatabase database) XrmSetDatabase;
	///
	XrmDatabase function(Display* display) XrmGetDatabase;
}

///
XrmDatabase function(const char* filename) XrmGetFileDatabase;
///
Status function(const char* filename, XrmDatabase* target, Bool override_) XrmCombineFileDatabase;

/**
 * Params:
 * 		data	=	null terminated string
 */
XrmDatabase function(const char* data) XrmGetStringDatabase;

///
void function(XrmDatabase database, const char* filename) XrmPutFileDatabase;
///
void function(XrmDatabase source_db, XrmDatabase* target_db) XrmMergeDatabases;
///
void function(XrmDatabase source_db, XrmDatabase* target_db, Bool override_) XrmCombineDatabase;

///
enum {
	///
	XrmEnumAllLevels = 0,
	///
	XrmEnumOneLevel = 1
}

alias XrmEnumerateDatabaseFunc = extern(C) Bool function(XrmDatabase* db, XrmBindingList bindings, XrmQuarkList quarks, XrmRepresentation* type, XrmValue* value, XPointer closure);

///
Bool function(XrmDatabase db, XrmNameList name_prefix, XrmClassList class_prefix, int mode, XrmEnumerateDatabaseFunc proc, XPointer closure) XrmEnumerateDatabase;

///
const char* function(XrmDatabase database) XrmLocaleOfDatabase;

/****************************************************************
 *
 * Command line option mapping to resource entries
 *
 ****************************************************************/

///
enum XrmOptionKind {
	/// Value is specified in OptionDescRec.value
	XrmoptionNoArg,
	/// Value is the option string itself
	XrmoptionIsArg,
	/// Value is characters immediately following option
	XrmoptionStickyArg,
	/// Value is next argument in argv
	XrmoptionSepArg,
	/// Resource and value in next argument in argv
	XrmoptionResArg,
	/// Ignore this option and the next argument in argv
	XrmoptionSkipArg,
	/// Ignore this option and the rest of argv
	XrmoptionSkipLine,
	/// Ignore this option and the next OptionDescRes.value arguments in argv
	XrmoptionSkipNArgs
}

///
struct XrmOptionDescRec {
	/// Option abbreviation in argv
	char* option;
	/// Resource specifier
	char* specifier;
	/// Which style of option it is
	XrmOptionKind argKind;
	/// Value to provide if XrmoptionNoArg
	XPointer value;
}

///
alias XrmOptionDescList = XrmOptionDescRec*;

///
void function(XrmDatabase* database, XrmOptionDescList table, int table_count, const char* name, int* argc_in_out, char** argv_in_out) XrmParseCommand;
