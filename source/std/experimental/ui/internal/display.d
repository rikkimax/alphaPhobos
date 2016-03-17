module std.experimental.ui.internal.display;
import std.experimental.ui.rendering : IDisplay;
import std.experimental.platform : IPlatform, thePlatform;
import std.experimental.math.linearalgebra.vector : vec2;
import std.experimental.allocator : IAllocator;
import std.experimental.memory.managed;

private {
	import std.experimental.ui.internal.defs;
	import std.experimental.ui.window.features.screenshot;
	
	version(Windows) {
		import core.sys.windows.windows : MONITORINFOEXA, GetMonitorInfoA, MONITORINFOF_PRIMARY,
			DEVMODEA, EnumDisplaySettingsA, ENUM_CURRENT_SETTINGS, CreateDCA;
		
		interface DisplayInterfaces : Feature_ScreenShot, Have_ScreenShot {}
	}
}

package(std.experimental.ui.internal) {
	final class DisplayImpl : IDisplay, DisplayInterfaces {
		IAllocator alloc;
		IPlatform platform;
		
		char[] name_;
		bool primaryDisplay_;
		vec2!ushort size_;
		uint refreshRate_;
		
		version(Windows) {
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
				
				size_.x = cast(ushort)(info.rcMonitor.right - info.rcMonitor.left);
				size_.y = cast(ushort)(info.rcMonitor.bottom - info.rcMonitor.top);
				
				primaryDisplay_ = (info.dwFlags & MONITORINFOF_PRIMARY) == MONITORINFOF_PRIMARY;
				
				DEVMODEA devMode;
				devMode.dmSize = DEVMODEA.sizeof;
				EnumDisplaySettingsA(name_.ptr, ENUM_CURRENT_SETTINGS, &devMode);
				refreshRate_ = devMode.dmDisplayFrequency;
			}
		}
		
		@property {
			string name() { return cast(immutable)name_[0 .. $-1]; }
			vec2!ushort size() { return size_; }
			uint refreshRate() { return refreshRate_; }
			
			uint luminosity() {
				version(Windows) {
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
				} else
					assert(0);
			}
			
			managed!(IWindow[]) windows() {
				version(Windows) {
					GetWindows ctx = GetWindows(alloc, cast()platform, cast()this);
					ctx.call;
					return managed!(IWindow[])(ctx.windows, managers(), Ownership.Secondary, alloc);
				} else
					assert(0);
			}
			
			bool primary() { return primaryDisplay_; }
			
			IDisplay dup(IAllocator alloc) {
				version(Windows) {
					return alloc.make!DisplayImpl(hMonitor, alloc, platform);
				} else
					assert(0);
			}
			
			void* __handle() {
				version(Windows) {
					return &hMonitor;
				} else
					assert(0);
			}
		}
		
		Feature_ScreenShot __getFeatureScreenShot() {
			version(Windows)
				return this;
			else
				return null;
		}
		
		ImageStorage!RGB8 screenshot(IAllocator alloc = null) {
			if (alloc is null)
				alloc = this.alloc;
			
			version(Windows) {
				HDC hScreenDC = CreateDCA(name_.ptr, null, null, null);
				auto storage = screenshotImpl(alloc, hScreenDC, size_);
				DeleteDC(hScreenDC);
				return storage;
			} else {
				assert(0);
			}
		}
	}
}