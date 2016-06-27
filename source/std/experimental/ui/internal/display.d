module std.experimental.ui.internal.display;
import std.experimental.ui.internal.defs;
import std.experimental.ui.internal.platform;
import std.experimental.ui.rendering;
import std.experimental.ui.window.features.screenshot;
import std.experimental.math.linearalgebra.vector : vec2;
import std.experimental.memory.managed;
import std.experimental.allocator : IAllocator;

abstract class DisplayImpl : IDisplay {
	import std.experimental.ui.window.defs : IWindow;

	package(std.experimental.ui.internal) {
		IAllocator alloc;
		IPlatform platform;
		
		char[] name_;
		bool primaryDisplay_;
		vec2!ushort size_;
		uint refreshRate_;
	}

	@property {
		string name() {
			if (name_.length < 2)
				return null;
			return cast(immutable)name_[0 .. $-1];
		}

		vec2!ushort size() { return size_; }
		uint refreshRate() { return refreshRate_; }
		bool primary() { return primaryDisplay_; }
	}
}

version(Windows) {
	import core.sys.windows.windows : MONITORINFOEXA, GetMonitorInfoA, MONITORINFOF_PRIMARY,
		DEVMODEA, EnumDisplaySettingsA, ENUM_CURRENT_SETTINGS, CreateDCA, LONG;

	final class WinAPIDisplayImpl : DisplayImpl, Feature_ScreenShot, Have_ScreenShot {
		HMONITOR hMonitor;
		
		this(HMONITOR hMonitor, IAllocator alloc, IPlatform platform) {
			import std.string : fromStringz;
			
			this.alloc = alloc;
			this.platform = platform;
			
			this.hMonitor = hMonitor;
			
			MONITORINFOEXA info;
			info.cbSize = MONITORINFOEXA.sizeof;
			GetMonitorInfoA(hMonitor, &info);
			
			char[] temp = info.szDevice.ptr.fromStringz;
			name_ = alloc.makeArray!char(temp.length + 1);
			name_[0 .. $-1] = temp[];
			name_[$-1] = '\0';
			
			LONG sizex = info.rcMonitor.right - info.rcMonitor.left;
			LONG sizey = info.rcMonitor.bottom - info.rcMonitor.top;
			
			if (sizex > 0 && sizey > 0) {
				size_.x = cast(ushort)sizex;
				size_.y = cast(ushort)sizey;
			}
			
			primaryDisplay_ = (info.dwFlags & MONITORINFOF_PRIMARY) == MONITORINFOF_PRIMARY;
			
			DEVMODEA devMode;
			devMode.dmSize = DEVMODEA.sizeof;
			EnumDisplaySettingsA(name_.ptr, ENUM_CURRENT_SETTINGS, &devMode);
			refreshRate_ = devMode.dmDisplayFrequency;
		}

		@property {
			uint luminosity() {
				DWORD pdwMonitorCapabilities, pdwSupportedColorTemperatures;
				DWORD pdwMinimumBrightness, pdwCurrentBrightness, pdwMaxiumumBrightness;
				PHYSICAL_MONITOR[1] pPhysicalMonitorArray;
				
				bool success = cast(bool)GetPhysicalMonitorsFromHMONITOR(hMonitor, pPhysicalMonitorArray.length, pPhysicalMonitorArray.ptr);
				if (!success)
					return 10;
				
				success = cast(bool)GetMonitorCapabilities(pPhysicalMonitorArray[0].hPhysicalMonitor, &pdwMonitorCapabilities, &pdwSupportedColorTemperatures);
				if (!success || (pdwMonitorCapabilities & MC_CAPS_BRIGHTNESS) == 0)
					return 10;
				
				success = cast(bool)GetMonitorBrightness(pPhysicalMonitorArray[0].hPhysicalMonitor, &pdwMinimumBrightness, &pdwCurrentBrightness, &pdwMaxiumumBrightness);
				if (!success)
					return 10;
				
				return pdwCurrentBrightness;
			}

			managed!(IWindow[]) windows() {
				GetWindows ctx = GetWindows(alloc, cast()platform, cast()this);
				ctx.call;
				return managed!(IWindow[])(ctx.windows, managers(), Ownership.Secondary, alloc);
			}

			void* __handle() {
				return &hMonitor;
			}
		}


		Feature_ScreenShot __getFeatureScreenShot() {
			return this;
		}
		
		ImageStorage!RGB8 screenshot(IAllocator alloc = null) {
			if (alloc is null)
				alloc = this.alloc;
			
			if (size_.x < 0 || size_.y < 0)
				return null;
			
			HDC hScreenDC = CreateDCA(name_.ptr, null, null, null);
			auto storage = screenshotImpl(alloc, hScreenDC, size_);
			DeleteDC(hScreenDC);
			return storage;
		}

		IDisplay dup(IAllocator alloc) {
			return alloc.make!WinAPIDisplayImpl(hMonitor, alloc, platform);
		}
	}
}