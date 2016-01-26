/**
 * Window and platform menu support.
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 */
module std.experimental.ui.window.features.menu;
import std.experimental.ui.window.defs;
import std.experimental.platform;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGB8;
import std.experimental.internal.dummyRefCount;
import std.experimental.memory.managed;

interface Have_Menu {
    Feature_Menu __getFeatureMenu();
}

///
interface Feature_Menu {
    ///
    MenuItem addItem();
    ///
    @property managed!(MenuItem[]) items();
}

///
alias MenuCallback = void delegate(MenuItem);

///
interface MenuItem {
    ///
    MenuItem addChildItem();
    ///
    void remove();

    @property {
        ///
        managed!(MenuItem[]) childItems();
        
        ///
        DummyRefCount!(ImageStorage!RGB8) image();
        
        ///
        void image(ImageStorage!RGB8);
        
        ///
        DummyRefCount!(dchar[]) text();
        
        ///
        void text(dstring);
        
        ///
        void text(wstring);
        
        ///
        void text(string);

        ///
        bool divider();
        
        ///
        void divider(bool);

        ///
        bool disabled();

        ///
        void disabled(bool);

        ///
        void callback(MenuCallback);
    }
}

@property {
    ///
    Feature_Menu menu(T)(T self) if (is(T : IWindow) || is(T : IPlatform)) {
        if (self is null)
            return null;
        if (Have_Menu ss = cast(Have_Menu)self) {
            return ss.__getFeatureMenu();
        }
        
        return null;
    }

    Feature_Menu menu(T)(T self) if (!(is(T : IWindow) || is(T : IPlatform))) {
        static assert(0, "I do not know how to handle " ~ T.stringof ~ " I can only use IWindow or IPlatform.");
    }
}
