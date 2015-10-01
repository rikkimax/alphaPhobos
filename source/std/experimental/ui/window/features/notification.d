module std.experimental.ui.window.features.notification;
import std.experimental.ui.window.defs;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGBA8;
import std.experimental.platform : IPlatform;

interface Have_Notification {
    Feature_Notification __getFeatureNotification();
}

interface Feature_Notification {
    @property {
        ImageStorage!RGBA8 getIcon();
        void setIcon(ImageStorage!RGBA8);
    }

    void notify(ImageStorage!RGBA8, dstring, dstring);
    void clearNotifications();
}

@property {
    void icon(IPlatform self, ImageStorage!RGBA8 to) {
        if (self is null)
            return;
        if (Have_Notification ss = cast(Have_Notification)self) {
            auto fss = ss.__getFeatureNotification();
            if (fss !is null) {
                fss.setIcon(to);
            }
        }
    }
    
    ImageStorage!RGBA8 icon(IPlatform self) {
        if (self is null)
            return null;
        if (Have_Notification ss = cast(Have_Notification)self) {
            auto fss = ss.__getFeatureNotification();
            if (fss !is null) {
                return fss.getIcon();
            }
        }
        return null;
    }
}

void notify(IPlatform self, ImageStorage!RGBA8 image=null, dstring title=null, dstring text=null) {
    if (self is null)
        return;
    if (Have_Notification ss = cast(Have_Notification)self) {
        auto fss = ss.__getFeatureNotification();
        if (fss !is null) {
            fss.notify(image, title, text);
        }
    }
}

void clearNotifications(IPlatform self) {
    if (self is null)
        return;
    if (Have_Notification ss = cast(Have_Notification)self) {
        auto fss = ss.__getFeatureNotification();
        if (fss !is null) {
            fss.clearNotifications();
        }
    }
}