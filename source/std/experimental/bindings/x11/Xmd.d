/**
 * Xmd.h: MACHINE DEPENDENT DECLARATIONS.
 * 
 * License:
 *    Copyright 1987, 1998  The Open Group
 *    
 *    Permission to use, copy, modify, distribute, and sell this software and its
 *    documentation for any purpose is hereby granted without fee, provided that
 *    the above copyright notice appear in all copies and that both that
 *    copyright notice and this permission notice appear in supporting
 *    documentation.
 *    
 *    The above copyright notice and this permission notice shall be included in
 *    all copies or substantial portions of the Software.
 *    
 *    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 *    OPEN GROUP BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 *    AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 *    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *    
 *    Except as contained in this notice, the name of The Open Group shall not be
 *    used in advertising or otherwise to promote the sale, use or other dealings
 *    in this Software without prior written authorization from The Open Group.
 *    
 *    
 *    Copyright 1987 by Digital Equipment Corporation, Maynard, Massachusetts.
 *    
 *                            All Rights Reserved
 *    
 *    Permission to use, copy, modify, and distribute this software and its
 *    documentation for any purpose and without fee is hereby granted,
 *    provided that the above copyright notice appear in all copies and that
 *    both that copyright notice and this permission notice appear in
 *    supporting documentation, and that the name of Digital not be
 *    used in advertising or publicity pertaining to distribution of the
 *    software without specific, written prior permission.
 *    
 *    DIGITAL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
 *    ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL
 *    DIGITAL BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR
 *    ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
 *    WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
 *    ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 *    SOFTWARE.
 */
module std.experimental.bindings.x11.Xmd;
import core.stdc.config;

/// 32/64-bit architecture
version(D_LP64) {
    ///
    enum LONG64 = true;
} else {
    ///
    enum LONG64 = false;
}

///
size_t _SIZEOF(T)(){ return T.sizeof; }
///
alias SIZEOF = _SIZEOF;

///
static if (LONG64) {
    ///
    alias INT64 = c_ulong;
    ///
    alias INT32 = int;
} else {
    ///
    alias INT32 = c_long;
}

///
alias INT16 = short;

///
alias INT8 = byte;

static if (LONG64) {
    ///
    alias CARD64 = c_ulong;
    ///
    alias CARD32 = uint;
} else {
	///
	alias CARD64 = ulong;
    ///
    alias CARD32 = c_ulong;
}

///
alias CARD16 = ushort;
///
alias CARD8 = ubyte;

///
alias BITS32 = CARD32;
///
alias BITS16 = CARD16;

///
alias BYTE = CARD8;
///
alias BOOL = CARD8;

int cvtINT8toInt(INT8 val) { return cast(int)val; }
int cvtINT16toInt(INT16 val) { return cast(int)val; }
int cvtINT32toInt(INT32 val) { return cast(int)val; }
short cvtINT8toShort(INT8 val) { return cast(short)val; }
short cvtINT16toShort(INT16 val) { return cast(short)val; }
short cvtINT32toShort(INT32 val) { return cast(short)val; }
c_long cvtINT8toLong(INT8 val) { return cast(c_long)val; }
c_long cvtINT16toLong(INT16 val) { return cast(c_long)val; }
c_long cvtINT32toLong(INT32 val) { return cast(c_long)val; }

/**
 * this version should leave result of type (t *), but that should only be
 * used when not in MUSTCOPY
 */
T NEXTPTR(T)(T p) { return p + 1; }
