module std.experimental.ui.window.features.notification;
import std.experimental.ui.window.defs;

interface Have_Notification {
	Feature_Notification __getFeatureNotification();
}

interface Feature_Notification {
	@property {
		SwappableImage!RGBA8* getIcon();
		void setIcon(SwappableImage!RGBA8*);
	}

	void notify(SwappableImage!RGBA8*, dstring, dstring);
	void clearNotifications();
}

@property {
	void icon(IPlatform self, SwappableImage!RGBA8* to) {
		if (self is null)
			return;
		if (Have_Notification ss = cast(Have_Notification)self) {
			auto fss = ss.__getFeatureNotification();
			if (fss !is null) {
				fss.setIcon(to);
			}
		}
	}
	
	SwappableImage!RGBA8* icon(IPlatform self) {
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

void notify(IPlatform self, SwappableImage!RGBA8* image=null, dstring title=null, dstring text=null) {
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