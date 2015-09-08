module tests.png.basic;
import tests.png.defs;
import std.experimental.graphic.image;
import std.file : read, write, remove;
import std.path : baseName;

void png_test1(string checkStatements)(string file, bool mustBeExact) {
    void check(Image)(ref Image image) {
        mixin(checkStatements);
    }

    entryTest(file);
    testOutput(baseName(file).tempLocation);

    HeadersOnlyPNGFileFormat headerImage = loadPNGHeaders(cast(ubyte[])read(file));
    check(headerImage);
    
    // import 1
    testOutput("import 1");
    auto image1 = loadPNG!RGBA16(cast(ubyte[])read(file));
    check(image1);

    // export
    testOutput("export");
    write(baseName(file).tempLocation, image1.toBytes());
    
    // import 2
    testOutput("import 2");
    auto image2 = loadPNG!RGBA16(cast(ubyte[])read(baseName(file).tempLocation));
    check(image2);

    // compare import1 with import2
    testOutput("compare");

    foreach(x; 0 .. headerImage.IHDR.width) {
        foreach(y; 0 .. headerImage.IHDR.height) {
            RGBA16 p1 = image1[x, y];
            RGBA16 p2 = image2[x, y];

            void checkp(ushort a, ushort b) {
                if (mustBeExact) {
                    assert(a == b);
                } else {
                    if (a > b && a - b > 3)
                        assert(0);
                    else if (a < b && b - a > 3)
                        assert(0);
                }
            }

            checkp(p1.r, p2.r);
            checkp(p1.g, p2.g);
            checkp(p1.b, p2.b);
            checkp(p1.a, p2.a);
        }
    }
    
    // cleanup
    baseName(file).tempLocation.remove();

    exitTest(file);
}

unittest {
    string file = "tests/png/assets/basi0g01.png";
    entryTest(file);

    HeadersOnlyPNGFileFormat headerImage = loadPNGHeaders(cast(ubyte[])read(file));
    assert(headerImage.checkIDHR(32, 32,
        PngIHDRBitDepth.BitDepth1,
        PngIHDRColorType.Grayscale,
        PngIHDRCompresion.DeflateInflate,
        PngIHDRFilter.Adaptive,
        PngIHDRInterlaceMethod.Adam7));

    assert(headerImage.PLTE is null);
    assert(headerImage.tRNS is null);

    assert(headerImage.gAMA !is null);
    assert(headerImage.gAMA.value == 100_000);

    assert(headerImage.cHRM is null);
    assert(headerImage.sRGB is null);
    assert(headerImage.iCCP is null);
    assert(headerImage.bKGD is null);
    assert(headerImage.pPHs is null);
    assert(headerImage.sBIT is null);
    assert(headerImage.tIME is null);

    assert(headerImage.tEXt.__internalKeys.length == 0);
    assert(headerImage.zEXt.__internalKeys.length == 0);

    assert(headerImage.sPLT.length == 0);
    assert(headerImage.hIST.length == 0);

    exitTest(file);
}

unittest {
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        
        assert(image.gAMA !is null);
        assert(image.gAMA.value == 100_000);
        
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);

        assert(image.tEXt.__internalKeys.length == 0);
        assert(image.zEXt.__internalKeys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn0g01.png", true);

    png_test1!q{
        //import std.stdio;writeln(image.toString());

        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        
        assert(image.gAMA !is null);
        assert(image.gAMA.value == 100_000);
        
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.__internalKeys.length == 0);
        assert(image.zEXt.__internalKeys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn0g02.png", true);

    png_test1!q{
        //import std.stdio;writeln(image.toString());
        
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        
        assert(image.gAMA !is null);
        assert(image.gAMA.value == 100_000);
        
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.__internalKeys.length == 0);
        assert(image.zEXt.__internalKeys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn0g04.png", true);
}