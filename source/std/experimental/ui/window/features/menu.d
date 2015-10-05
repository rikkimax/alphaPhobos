module std.experimental.ui.window.features.menu;
import std.experimental.ui.window.defs;
import std.experimental.platform : IPlatform;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGB8;

interface Have_Menu {
    Feature_Menu __getFeatureMenu();
}

interface Feature_Menu {
    void addItem();
    @property MenuItem[] items();
}

alias MenuCallback = void delegate(MenuItem);

interface MenuItem {
    void addChildItem();
    void remove();

    @property {
        MenuItem[] childItems();
        ImageStorage!RGB8 image();
        void image(ImageStorage!RGB8);
        dstring text();
        void text(dstring);
        bool devider();
        void devider(bool);
        void callback(MenuCallback);
    }
}

@property {
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