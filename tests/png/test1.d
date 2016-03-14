module tests.png.test1;
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
    
    testOutput("header check");
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
    //baseName(file).tempLocation.remove();
    
    exitTest(file);
}

// basn0g**
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
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn0g01.png", true);
    
    png_test1!q{
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
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn0g02.png", true);
    
    png_test1!q{
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
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn0g04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
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
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn0g08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth16,
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
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn0g16.png", true);
}

// basi0g**
unittest {
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
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
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi0g01.png", true);

    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
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
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi0g02.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
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
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi0g04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
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
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi0g08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth16,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
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
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi0g16.png", true);
}

//filters
unittest {
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/f00n0g08.png", true);

    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/f00n2c08.png", true);

    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/f01n0g08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/f01n2c08.png", true);

    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/f02n0g08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/f02n2c08.png", true);

    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/f03n0g08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/f03n2c08.png", true);

    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.Grayscale,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/f04n0g08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/f04n2c08.png", true);
}

// s**nP**
unittest {
    png_test1!q{
        assert(image.checkIDHR(1, 1,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s01n3p01.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(2, 2,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s02n3p01.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(3, 3,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s03n3p01.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(4, 4,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s04n3p01.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(5, 5,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s05n3p02.png", true);

    png_test1!q{
        assert(image.checkIDHR(6, 6,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s06n3p02.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(7, 7,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s07n3p02.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(8, 8,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s08n3p02.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(9, 9,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s09n3p02.png", true);
}

// s**iP**
unittest {
    png_test1!q{
        assert(image.checkIDHR(1, 1,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s01i3p01.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(2, 2,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s02i3p01.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(3, 3,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s03i3p01.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(4, 4,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s04i3p01.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(5, 5,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s05i3p02.png", true);

    png_test1!q{
        assert(image.checkIDHR(6, 6,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s06i3p02.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(7, 7,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s07i3p02.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(8, 8,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s08i3p02.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(9, 9,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s09i3p02.png", true);
}

// s**i*p0*
unittest {
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s32i3p04.png", true);
    
        png_test1!q{
        assert(image.checkIDHR(33, 33,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s33i3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(34, 34,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s34i3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(35, 35,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s35i3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(36, 36,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s36i3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(37, 37,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s37i3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(38, 38,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s38i3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(39, 39,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s39i3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(40, 40,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s40i3p04.png", true);
}

// s**n*p0*
unittest {
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s32n3p04.png", true);
    
        png_test1!q{
        assert(image.checkIDHR(33, 33,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s33n3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(34, 34,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s34n3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(35, 35,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s35n3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(36, 36,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s36n3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(37, 37,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s37n3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(38, 38,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s38n3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(39, 39,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s39n3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(40, 40,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/s40n3p04.png", true);
}

// basi*c**
unittest {
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi2c08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth16,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi2c16.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi3p01.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi3p02.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi3p08.png", true);
}

// basn*c**
unittest {
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn2c08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth16,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn2c16.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth1,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn3p01.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth2,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn3p02.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth4,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT !is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn3p04.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.PalletteWithColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE !is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn3p08.png", true);
}

// basi*a**
unittest {
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.GrayscaleWithAlpha,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi4a08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth16,
                PngIHDRColorType.GrayscaleWithAlpha,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi4a16.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsedWithAlpha,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi6a08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth16,
                PngIHDRColorType.ColorUsedWithAlpha,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.Adam7));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basi6a16.png", true);
}

// basn*a**
unittest {
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.GrayscaleWithAlpha,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn4a08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth16,
                PngIHDRColorType.GrayscaleWithAlpha,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn4a16.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsedWithAlpha,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn6a08.png", true);
    
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth16,
                PngIHDRColorType.ColorUsedWithAlpha,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA !is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/basn6a16.png", true);
}

// z**n2c08
unittest {
    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/z00n2c08.png", true);

    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/z03n2c08.png", true);

    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);
        
        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/z06n2c08.png", true);

    png_test1!q{
        assert(image.checkIDHR(32, 32,
                PngIHDRBitDepth.BitDepth8,
                PngIHDRColorType.ColorUsed,
                PngIHDRCompresion.DeflateInflate,
                PngIHDRFilter.Adaptive,
                PngIHDRInterlaceMethod.NoInterlace));
        
        assert(image.PLTE is null);
        assert(image.tRNS is null);
        assert(image.gAMA is null);
        assert(image.cHRM is null);
        assert(image.sRGB is null);
        assert(image.iCCP is null);
        assert(image.bKGD is null);
        assert(image.pPHs is null);
        assert(image.sBIT is null);
        assert(image.tIME is null);

        assert(image.tEXt.keys.length == 0);
        assert(image.zEXt.keys.length == 0);
        
        assert(image.sPLT.length == 0);
        assert(image.hIST.length == 0);
    }("tests/png/assets/z09n2c08.png", true);
}