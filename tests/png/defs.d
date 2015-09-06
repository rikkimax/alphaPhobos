module tests.png.defs;
public import tests.defs;
import std.experimental.graphic.image.fileformats.png;

bool checkIDHR(Image, T...)(ref Image image, T args) @safe {
    IHDR_Chunk as = IHDR_Chunk(args);

    return image.IHDR.width == as.width &&
            image.IHDR.height == as.height &&
            image.IHDR.bitDepth == as.bitDepth &&
            image.IHDR.colorType == as.colorType &&
            image.IHDR.compressionMethod == as.compressionMethod &&
            image.IHDR.filterMethod == as.filterMethod &&
            image.IHDR.interlaceMethod == as.interlaceMethod;
}