/**
 * Types definitions shared between server and clients
 * 
 * License:
 *     Copyright (c) 1999  The XFree86 Project Inc.
 *     
 *     All Rights Reserved.
 *     
 *     The above copyright notice and this permission notice shall be included in
 *     all copies or substantial portions of the Software.
 *     
 *     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 *     OPEN GROUP BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 *     AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 *     CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *     
 *     Except as contained in this notice, the name of The XFree86 Project
 *     Inc. shall not be used in advertising or otherwise to promote the
 *     sale, use or other dealings in this Software without prior written
 *     authorization from The XFree86 Project Inc..
 */
module std.experimental.bindings.x11.Xdefs;
import core.stdc.config : c_long, c_ulong;

version(_XSERVER64) {
	public import std.experimental.bindings.x11.Xmd;
}

///
version(_XSERVER64) {
	///
	alias Atom = CARD32;
} else {
	///
	alias Atom = c_ulong;
}

///
alias Bool = int;
///
alias pointer = void*;

///
struct _Client;
///
alias ClientPtr = _Client*;

///
version(_XSERVER64) {
	///
	alias XID = CARD32;
} else {
	///
	alias XID = c_ulong;
}

///
struct _Font;
/// also in fonts/include/font.h
alias FontPtr = _Font*;

///
alias Font = XID;

///
version(_XSERVER64) {
	///
	alias FSID = CARD32;
} else {
	///
	alias FSID = c_ulong;
}

///
alias AccContext = FSID;

/**
 * OS independent time value 
 * XXX Should probably go in Xos.h
 */
struct timeval;
///
alias OSTimePtr = timeval**;

///
alias BlockHandlerProcPtr =  extern(C) void function(void* blockData, OSTimePtr pTimeout, void* pReadmask);
