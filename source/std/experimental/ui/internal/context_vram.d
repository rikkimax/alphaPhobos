module std.experimental.ui.internal.context_vram;
import std.experimental.math.linearalgebra.vector : vec2;
import std.experimental.ui.rendering;
import std.experimental.ui.context_features.vram;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGB8, RGBA8;
import std.experimental.allocator : IAllocator;

private {
	version(Windows) {
		import core.sys.windows.windows : HWND, HDC, GetDC, CreateCompatibleDC, IsWindowVisible,
			RECT, GetClientRect, HBITMAP, CreateBitmap, HGDIOBJ, SelectObject, GetObjectA, StretchBlt,
			DeleteObject, InvalidateRgn, SRCCOPY;
	}
}

final class VRAMContextImpl : IContext, Have_VRam, Feature_VRam {
	import std.experimental.graphic.image.interfaces : SwappableImage, imageObject;
	import std.experimental.graphic.image.storage.flat;

	private {
		bool assignedAlpha;
		
		// how we exposed the storage
		ImageStorage!RGB8 storage2;
		ImageStorage!RGBA8 alphaStorage2;
		
		// the intermediary between the exposed (pixel format) and the actual supported one
		SwappableImage!RGB8 storage3 = void;
		SwappableImage!RGBA8 alphaStorage3 = void;
		
		version(Windows) {
			import std.experimental.graphic.color.rgb : BGR8, BGRA8;
			
			HWND hwnd;
			HDC hdc, hdcMem;
			
			// where the actual pixels are stored
			FlatImageStorage!BGR8 storage1 = void;
			FlatImageStorage!BGRA8 alphaStorage1 = void;
		}
	}
	
	// sets up our internal image buffer
	this(bool assignAlpha, size_t width, size_t height, IAllocator alloc) {
		assignedAlpha = assignAlpha;
		
		version(Windows) {
			if (assignAlpha) {
				// create the actual storage
				alphaStorage1 = FlatImageStorage!BGRA8(width, height, alloc);
				
				// we need to do a bit of magic to translate the colors
				storage3 = SwappableImage!RGB8(&alphaStorage1, alloc);
				storage2 = imageObject(&storage3, alloc);
				
				alphaStorage3 = SwappableImage!RGBA8(&alphaStorage1, alloc);
				alphaStorage2 = imageObject(&alphaStorage3, alloc);
			} else {
				// create the actual storage
				storage1 = FlatImageStorage!BGR8(width, height, alloc);
				
				// we need to do a bit of magic to translate the colors
				storage3 = SwappableImage!RGB8(&storage1, alloc);
				storage2 = imageObject(&storage3, alloc);
				
				alphaStorage3 = SwappableImage!RGBA8(&storage1, alloc);
				alphaStorage2 = imageObject(&alphaStorage3, alloc);
			}
		} else
			assert(0);
	}
	
	version(Windows) {
		this(HWND hwnd, bool assignAlpha, IAllocator alloc) {
			this(true, 1, 1, alloc);
			
			this.hwnd = hwnd;
			
			hdc = GetDC(hwnd);
			hdcMem = CreateCompatibleDC(hdc);
			swapBuffers();
		}
	}
	
	@property {
		ImageStorage!RGB8 vramBuffer() { return storage2; }
		ImageStorage!RGBA8 vramAlphaBuffer() { return alphaStorage2; }
	}
	
	Feature_VRam __getFeatureVRam() {
		return this;
	}
	
	void swapBuffers() {
		version(Windows) {
			if (!IsWindowVisible(hwnd))
				return;
			
			ubyte* bufferPtr;
			uint bitsCount;
			
			if (assignedAlpha) {
				bitsCount = 32;
				bufferPtr = cast(ubyte*)alphaStorage1.__pixelsRawArray.ptr;
			} else {
				bitsCount = 24;
				bufferPtr = cast(ubyte*)storage1.__pixelsRawArray.ptr;
			}
			
			RECT windowRect;
			GetClientRect(hwnd, &windowRect);
			
			HBITMAP hBitmap = CreateBitmap(cast(uint)storage2.width, cast(uint)storage2.height, 1, bitsCount, bufferPtr);
			
			HGDIOBJ oldBitmap = SelectObject(hdcMem, hBitmap);
			
			HBITMAP bitmap;
			GetObjectA(hBitmap, HBITMAP.sizeof, &bitmap);
			
			StretchBlt(hdc, 0, 0, cast(uint)storage2.width, cast(uint)storage2.height, hdcMem, 0, 0, cast(uint)windowRect.right, cast(uint)windowRect.bottom, SRCCOPY);
			
			SelectObject(hdcMem, oldBitmap);
			DeleteObject(hBitmap);
			
			if (windowRect.right != storage2.width || windowRect.bottom != storage2.height) {
				if (assignedAlpha) {
					alphaStorage1.resize(windowRect.right, windowRect.bottom);
				} else {
					storage1.resize(windowRect.right, windowRect.bottom);
				}
			}
			
			InvalidateRgn(hwnd, null, true);
		} else
			assert(0);
	}
}