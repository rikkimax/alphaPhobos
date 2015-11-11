module std.experimental.ui.window.features.notification;
import std.experimental.ui.window.defs;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGBA8;
import std.experimental.platform : IPlatform;
import std.experimental.internal.dummyRefCount;
import std.experimental.allocator : IAllocator, theAllocator;

interface Have_Notification {
    Feature_Notification __getFeatureNotification();
}

interface Feature_Notification {
    @property {
        ImageStorage!RGBA8 getNotificationIcon(IAllocator alloc=theAllocator);
        void setNotificationIcon(ImageStorage!RGBA8, IAllocator alloc=theAllocator);
    }

    void notify(ImageStorage!RGBA8, dstring, dstring, IAllocator alloc=theAllocator);
    void clearNotifications();
}

void notificationIcon(IPlatform self, ImageStorage!RGBA8 to, IAllocator alloc=theAllocator) {
    if (self is null)
        return;
    if (Have_Notification ss = cast(Have_Notification)self) {
        auto fss = ss.__getFeatureNotification();
        if (fss !is null) {
            fss.setNotificationIcon(to, alloc);
        }
    }
}
    
@property {
    DummyRefCount!(ImageStorage!RGBA8) notificationIcon(IPlatform self, IAllocator alloc=theAllocator) {
        if (self is null)
            return DummyRefCount!(ImageStorage!RGBA8)(null, null);
        if (Have_Notification ss = cast(Have_Notification)self) {
            auto fss = ss.__getFeatureNotification();
            if (fss !is null) {
                return DummyRefCount!(ImageStorage!RGBA8)(fss.getNotificationIcon(alloc), alloc);
            }
        }
        return DummyRefCount!(ImageStorage!RGBA8)(null, null);
    }
}

void notify(IPlatform self, ImageStorage!RGBA8 image=null, dstring title=null, dstring text=null, IAllocator alloc=theAllocator) {
    if (self is null)
        return;
    if (Have_Notification ss = cast(Have_Notification)self) {
        auto fss = ss.__getFeatureNotification();
        if (fss !is null) {
            fss.notify(image, title, text, alloc);
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