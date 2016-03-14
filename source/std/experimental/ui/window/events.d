/**
 * Events related to windows and render points
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.ui.window.events;
import std.experimental.ui.events;

///
alias EventOnMoveDel = void delegate(short x, short y);
///
alias EventOnMoveFunc = void function(short x, short y);

/**
 * Group of hookable events for rendering upon
 */
interface IWindowEvents : IRenderEvents {
	import std.experimental.math.linearalgebra.vector : vec2;
	import std.functional : toDelegate;
	
	@property {
		/**
         * When the window has been moved this event will triggered.
         *
         * Params:
         *      del     =   The callback to call
         */
		void onMove(EventOnMoveDel del);
		
		/// Ditto
		final void onMove(EventOnMoveFunc func) { onMove(func.toDelegate); }
	}
}