/**
 * PNG file format image loader/exporter
 *
 * Copyright: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors: $(LINK2 http://cattermole.co.nz, Richard Andrew Cattermole)
 * 
 * Standards:
 *      Close to $(LINK2 http://www.w3.org/TR/PNG/, PNG 1.2) standard
 */
module std.experimental.graphic.image.fileformats.png;
import std.experimental.graphic.image.fileformats.defs : HeadersOnly, ImageNotLoadableException, ImageNotExportableException;
import std.experimental.graphic.image.interfaces;
import std.experimental.graphic.image.primitives : isImage, ImageColor;
import std.experimental.graphic.image.storage.base : ImageStorageHorizontal;
import std.experimental.allocator : IAllocator, theAllocator, makeArray, make, expandArray, dispose;
import std.experimental.graphic.color : isColor, RGB8, RGBA8;
import std.experimental.graphic.color.conv : convertColor;
import std.experimental.graphic.color.rgb : RGB;
import std.experimental.memory.managed;
import std.range : isInputRange, ElementType;
import std.datetime : DateTime;
import std.traits : isPointer;

///
alias HeadersOnlyPNGFileFormat = PNGFileFormat!HeadersOnly;

/**
 * PNG file format representation
 * 
 * Does not actually support color correction/alteration for the chunks: cHRM, sRGB, iCCP and gAMA.
 * Use them once you have already performed the alterations upon IDAT and respective data.
 * 
 * FIXME:
 *      Reliance on e.g. GC/processAllocator for when compressing/decompressing via zlib.
 *      Exporters use of filters 2, 3 and 4. Creates artifacts.
 */
struct PNGFileFormat(Color) if (isColor!Color || is(Color == HeadersOnly)) {
    import std.bitmanip : bigEndianToNative, nativeToBigEndian;
    import std.experimental.containers.map;
    import std.experimental.containers.list;
    
    ///
    IHDR_Chunk IHDR;
    
    ///
    PLTE_Chunk* PLTE;
    
    ///
    tRNS_Chunk* tRNS;
    
    ///
    gAMA_Chunk* gAMA;
    
    ///
    cHRM_Chunk* cHRM;
    
    ///
    sRGB_Chunk* sRGB;
    
    ///
    iCCP_Chunk* iCCP;
    
    /// tEXt values are really latin-1 but treated as UTF-8 in D code, may originate from iEXt
    managed!(Map!(PngTextKeywords, string)) tEXt = void;
    /// zEXt values are really latin-1 but treated as UTF-8 in D code, may originate from iEXt
    managed!(Map!(PngTextKeywords, string)) zEXt = void;
    
    ///
    bKGD_Chunk* bKGD;
    
    ///
    pPHs_Chunk* pPHs;
    
    ///
    sBIT_Chunk* sBIT;
    
    ///
    managed!(List!sPLT_Chunk) sPLT = void;
    
    ///
    managed!(List!ushort) hIST = void;
    
    ///
    DateTime* tIME;

    static if (!is(Color == HeadersOnly)) {
        /// Only available when Color is specified as not HeadersOnly
        ImageStorage!Color value;
        alias value this;
        
        ///
        managed!(ubyte[]) toBytes() {
            return performExport();
        }
    }
    
    string toString() {
        import std.conv : text;
        char[] ret;
        
        void addText(string[] toAdd...) {
            import std.algorithm : sum, map;
            size_t len = ret.length;
            allocator.expandArray(ret, toAdd.map!`a.length`.sum);
            
            foreach(v; toAdd) {
                ret[len .. len + v.length] = v[];
                len += v.length;
            }
        }
        
        addText("PNGFileFormat!", Color.stringof, " [\n\tChunks: [\n");
        
        addText("\t\t", IHDR.text, ",\n");
        
        if (tEXt.keys.length > 0)
            addText("\t\ttEXt(", tEXt.text, "),\n");
        if (zEXt.keys.length > 0)
            addText("\t\tzEXt(", tEXt.text, "),\n");
        
        if (PLTE !is null)
            addText("\t\t", (*PLTE).text, ",\n");
        if (tRNS !is null)
            addText("\t\t", (*tRNS).text, ",\n");
        if (gAMA !is null)
            addText("\t\t", (*gAMA).text, ",\n");
        if (cHRM !is null)
            addText("\t\t", (*cHRM).text, ",\n");
        if (sRGB !is null)
            addText("\t\t", (*sRGB).text, ",\n");
        if (iCCP !is null)
            addText("\t\t", (*iCCP).text, ",\n");
        if (bKGD !is null)
            addText("\t\t", (*bKGD).text, ",\n");
        if (pPHs !is null)
            addText("\t\t", (*pPHs).text, ",\n");
        if (sBIT !is null)
            addText("\t\t", (*sBIT).text, ",\n");
        if (tIME !is null)
            addText("\t\t", (*tIME).text, ",\n");
        
        if (sPLT.length > 0)
            addText("\t\t", sPLT.text, ",\n");
        if (hIST.length > 0)
            addText("\t\t", hIST.text, ",\n");
        
        addText("\t]\n");
        static if (!is(Color == HeadersOnly)) {
            addText("\tData: [\n");
            
            foreach(y; 0 .. value.height) {
                addText("\t\t(y: ", y.text, " ");
                foreach(x; 0 .. value.width) {
                    addText("(x: ", x.text, " ", value.getPixel(x, y).text, ")"); // FIXME: text allocates
                    if (x + 1 < value.width)
                        addText(", ");
                }
                addText(")");
                if (y + 1 < value.height)
                    addText(",\n");
                else
                    addText("\n");
            }
            
            addText("\t]\n");
        }
        
        addText("]");
        return cast(string)ret;
    }
    
    @property {
        ///
        IAllocator allocator() {
            return alloc;
        }
    }
    
	this(IAllocator allocator) @safe {
		this.alloc = allocator;
		tEXt = Map!(PngTextKeywords, string)(allocator);
		zEXt = Map!(PngTextKeywords, string)(allocator);
		sPLT = List!sPLT_Chunk(allocator);
		hIST = List!ushort(allocator);
	}

	~this() @trusted {
		if (PLTE !is null)
			allocator.dispose(PLTE);
		if (tRNS !is null)
			allocator.dispose(tRNS);
		if (gAMA !is null)
			allocator.dispose(gAMA);
		if (cHRM !is null)
			allocator.dispose(cHRM);
		if (sRGB !is null)
			allocator.dispose(sRGB);
		if (iCCP !is null)
			allocator.dispose(iCCP);
		if (bKGD !is null)
			allocator.dispose(bKGD);
		if (pPHs !is null)
			allocator.dispose(pPHs);
		if (sBIT !is null)
			allocator.dispose(sBIT);
		if (tIME !is null)
			allocator.dispose(tIME);
		
		static if (!is(Color == HeadersOnly)) {
			if (IDAT !is null) {
				allocator.dispose(IDAT.data);
				allocator.dispose(IDAT);
				allocator.dispose(value);
			}
		}
	}

    private {
        IAllocator alloc;
        
        void delegate(size_t width, size_t height) @trusted theImageAllocator;
        
        static if (!is(Color == HeadersOnly)) {
            IDAT_Chunk!Color* IDAT;
            
            void allocateTheImage(ImageImpl)(size_t width, size_t height) @trusted {
                static if (is(ImageImpl : ImageStorage!Color)) {
                    value = alloc.make!(ImageImpl)(width, height, alloc);
                } else {
                    value = imageObject!(ImageImpl)(width, height, alloc);
                }
            }
        } else {
            // this gets checked for so many places, that it would be a pain to actually fix it there.
            // instead declare it as an untyped pointer to emulate 'is null'.
            // it should _never_ be assigned to!
            void* IDAT = null;
        }
        
        /*
         * The importer
         */
        
        void performInput(IR)(IR input) @trusted {
            import std.range;
            ubyte[] buffer = allocator.makeArray!ubyte(1024 * 1024 * 8); // 8mb
            
            ubyte popReadValue() {
                scope(exit) {
                    if (input.empty)
                        throw allocator.make!ImageNotLoadableException("Input was not long enough");
                    input.popFront;
                }
                
                return input.front;
            }
            
            bool checkHasPNGText() {
                if (!popReadValue == 0x89)
                    return false;
                if (!popReadValue == 0x50)
                    return false;
                if (!popReadValue == 0x4E)
                    return false;
                if (!popReadValue == 0x47)
                    return false;
                if (!popReadValue == 0x0D)
                    return false;
                if (!popReadValue == 0x0A)
                    return false;
                if (!popReadValue == 0x1A)
                    return false;
                if (!popReadValue == 0x0A)
                    return false;
                return true;
            }
            if (!checkHasPNGText()) {
                throw allocator.make!ImageNotLoadableException("Input was not a PNG image");
            }
            
            ubyte[] readChunk(out char[4] name) {
                import std.digest.crc : crc32Of, crcHexString;
                import std.conv : to;
                ubyte[4] tuintbuff;
                
                // chunk length
                tuintbuff[0] = popReadValue;
                tuintbuff[1] = popReadValue;
                tuintbuff[2] = popReadValue;
                tuintbuff[3] = popReadValue;
                uint chunkLength = bigEndianToNative!uint(tuintbuff);
                
                // chunk name
                name[0] = popReadValue;
                name[1] = popReadValue;
                name[2] = popReadValue;
                name[3] = popReadValue;
                
                // chunk data
                if (buffer.length < chunkLength + 4)
                    allocator.expandArray(buffer, chunkLength + 4);
                
                buffer[0 .. 4] = cast(ubyte[4])name[];
                foreach(index; 4 .. chunkLength + 4) {
                    buffer[index] = popReadValue;
                }
                
                // get the CRC code for chunk
                tuintbuff[0] = popReadValue;
                tuintbuff[1] = popReadValue;
                tuintbuff[2] = popReadValue;
                tuintbuff[3] = popReadValue;
                uint crcCode = bigEndianToNative!uint(tuintbuff);
                
                // check the chunk has not been "tampered" with
                // FIXME: probably allocated in crcHexString ew
                if (crcHexString(crc32Of(buffer[0 .. chunkLength + 4])) != crcHexString((cast(ubyte*)&crcCode)[0 .. 4])) {
                    throw allocator.make!ImageNotLoadableException("CRC code did not match for chunk");
                }
                
                return buffer[4 .. chunkLength + 4];
            }
            
        WL: while(!input.empty) {
                char[4] chunkName;
                ubyte[] chunkData = readChunk(chunkName);
                
                switch(chunkName) {
                    case "IHDR":
                        readChunk_IHDR(chunkData);
                        break;
                    case "cHRM":
                        // preceede IDAT, PLTE _only_
                        if (IDAT !is null || PLTE !is null)
                            throw allocator.make!ImageNotLoadableException("cHRM chunk must preceede IDAT or PLTE chunks");
                        else if (cHRM !is null) // must not have a iCCP chunk as well
                            throw allocator.make!ImageNotLoadableException("Only one cHRM chunk can exist");
                        
                        readChunk_cHRM(chunkData);
                        break;
                    case "sRGB":
                        // preceede IDAT, PLTE _only_
                        if (IDAT !is null || PLTE !is null)
                            throw allocator.make!ImageNotLoadableException("sRGB chunk must preceede IDAT or PLTE chunks");
                        else if (iCCP !is null) // must not have a iCCP chunk as well
                            throw allocator.make!ImageNotLoadableException("sRGB chunk must not exist along with iCCP chunk");
                        else if (sRGB !is null) // must not have a sRGB chunk as well
                            throw allocator.make!ImageNotLoadableException("Only one sRGB chunk can exist");
                        
                        readChunk_sRGB(chunkData);
                        break;
                    case "iCCP":
                        // preceede IDAT, PLTE _only_
                        if (IDAT !is null || PLTE !is null)
                            throw allocator.make!ImageNotLoadableException("iCCP chunk must preceede IDAT or PLTE chunks");
                        else if (sRGB !is null) // must not have a sRGB chunk as well
                            throw allocator.make!ImageNotLoadableException("iCCP chunk must not exist along with sRGB chunk");
                        else if (iCCP !is null) // must not have a iCCP chunk as well
                            throw allocator.make!ImageNotLoadableException("Only one iCCP chunk can exist");
                        
                        readChunk_iCCP(chunkData);
                        break;
                    case "PLTE":
                        if (IDAT !is null || bKGD !is null)
                            throw allocator.make!ImageNotLoadableException("iCCP chunk must preceede IDAT and bKGD chunk(s)");
                        else if (PLTE !is null) // must not have a PLTE chunk as well
                            throw allocator.make!ImageNotLoadableException("Only one PLTE chunk can exist");
                        
                        readChunk_PLTE(chunkData);
                        break;
                    case "gAMA":
                        if (IDAT !is null || PLTE !is null)
                            throw allocator.make!ImageNotLoadableException("gAMA chunk must preceede IDAT or PLTE chunks");
                        else if (gAMA !is null) // must not have a gAMA chunk as well
                            throw allocator.make!ImageNotLoadableException("Only one gAMA chunk can exist");
                        
                        readChunk_gAMA(chunkData);
                        break;
                    case "tRNS":
                        if (IDAT !is null || PLTE !is null)
                            throw allocator.make!ImageNotLoadableException("tRNS chunk must preceede IDAT or PLTE chunks");
                        else if (tRNS !is null) // must not have a tRNS chunk as well
                            throw allocator.make!ImageNotLoadableException("Only one tRNS chunk can exist");
                        
                        readChunk_tRNS(chunkData);
                        break;
                    case "tEXt":
                        readChunk_tEXt(chunkData);
                        break;
                    case "zEXt":
                        readChunk_zEXt(chunkData);
                        break;
                    case "iTXt":
                        readChunk_iEXt(chunkData);
                        break;
                    case "bKGD":
                        if (IDAT !is null)
                            throw allocator.make!ImageNotLoadableException("bKGD chunk must preceede IDAT chunks");
                        else if (bKGD !is null) // must not have a tRNS chunk as well
                            throw allocator.make!ImageNotLoadableException("Only one bKGD chunk can exist");
                        
                        readChunk_bKGD(chunkData);
                        break;
                    case "pPHs":
                        if (IDAT !is null)
                            throw allocator.make!ImageNotLoadableException("pPHs chunk must preceede IDAT chunks");
                        else if (pPHs !is null) // must not have a tRNS chunk as well
                            throw allocator.make!ImageNotLoadableException("Only one pPHs chunk can exist");
                        
                        readChunk_pPHs(chunkData);
                        break;
                    case "sBIT":
                        if (IDAT !is null)
                            throw allocator.make!ImageNotLoadableException("sBIT chunk must preceede IDAT chunks");
                        else if (sBIT !is null) // must not have a tRNS chunk as well
                            throw allocator.make!ImageNotLoadableException("Only one sBIT chunk can exist");
                        
                        readChunk_sBIT(chunkData);
                        break;
                    case "sPLT":
                        if (IDAT !is null)
                            throw allocator.make!ImageNotLoadableException("sPLT chunk must preceede IDAT chunks");
                        
                        readChunk_sPLT(chunkData);
                        break;
                    case "hIST":
                        if (IDAT !is null)
                            throw allocator.make!ImageNotLoadableException("hIST chunk must preceede IDAT chunks");
                        else if (PLTE !is null)
                            throw allocator.make!ImageNotLoadableException("hIST chunk must proceed PLTE chunk");
                        
                        readChunk_hIST(chunkData);
                        break;
                        
                    case "tIME":
                        readChunk_tIME(chunkData);
                        break;
                        
                        static if (!is(Color == HeadersOnly)) {
                            case "IDAT":
                            if (hIST.length > 0 && PLTE.colors.length != hIST.length)
                                throw allocator.make!ImageNotLoadableException("hIST and PLTE chunks must have the same index length");
                            if ((IHDR.colorType & PngIHDRColorType.Palette) == PngIHDRColorType.Palette && tRNS !is null && tRNS.indexAlphas.length < PLTE.colors.length)
                                allocator.expandArray(tRNS.indexAlphas, tRNS.indexAlphas.length - PLTE.colors.length, 255);
                            
                            if (IDAT is null) {// allocate the image storage
                                IDAT = allocator.make!(IDAT_Chunk!Color);
                                theImageAllocator(IHDR.width, IHDR.height);
                            }
                            
                            allocator.expandArray(IDAT.data, chunkData.length);
                            IDAT.data[$-chunkData.length .. $] = chunkData[];
                            break;
                        }
                        
                    case "IEND":
                        static if (!is(Color == HeadersOnly)) {
                            if (IDAT is null)
                                throw allocator.make!ImageNotLoadableException("No IDAT chunk present");

                            readChunk_IDAT(IDAT.data);
                        }
                        
                        readChunk_IEND(chunkData);
                        break WL;
                    default:
                        break;
                }
            }
            
            allocator.dispose(buffer);
        }
        
        void readChunk_IHDR(ubyte[] chunkData) @trusted {
            if (chunkData.length != 13)
                throw allocator.make!ImageNotLoadableException("IHDR chunk size must be 13 bytes long");
            
            IHDR = IHDR_Chunk(
                bigEndianToNative!uint(cast(ubyte[4])chunkData[0 .. 4]),
                bigEndianToNative!uint(cast(ubyte[4])chunkData[4 .. 8]),
                cast(PngIHDRBitDepth) chunkData[8],
                cast(PngIHDRColorType) chunkData[9],
                cast(PngIHDRCompresion) chunkData[10],
                cast(PngIHDRFilter) chunkData[11],
                cast(PngIHDRInterlaceMethod) chunkData[12]);
        }
        
        void readChunk_cHRM(ubyte[] chunkData) @trusted {
            if (chunkData.length != 32)
                throw allocator.make!ImageNotLoadableException("cHRM chunk must be 32 bytes long");
            
            cHRM = allocator.make!cHRM_Chunk(
                bigEndianToNative!uint(cast(ubyte[4])chunkData[0 .. 4]),
                bigEndianToNative!uint(cast(ubyte[4])chunkData[4 .. 8]),
                bigEndianToNative!uint(cast(ubyte[4])chunkData[8 .. 12]),
                bigEndianToNative!uint(cast(ubyte[4])chunkData[12 .. 16]),
                bigEndianToNative!uint(cast(ubyte[4])chunkData[16 .. 20]),
                bigEndianToNative!uint(cast(ubyte[4])chunkData[20 .. 24]),
                bigEndianToNative!uint(cast(ubyte[4])chunkData[24 .. 28]),
                bigEndianToNative!uint(cast(ubyte[4])chunkData[28 .. 32]));
        }
        
        void readChunk_sRGB(ubyte[] chunkData) @trusted {
            if (chunkData.length != 1)
                throw allocator.make!ImageNotLoadableException("cHRM chunk must be 1 byte long");
            
            sRGB = allocator.make!sRGB_Chunk(cast(PngRenderingIntent)chunkData[0]);
        }
        
        void readChunk_iCCP(ubyte[] chunkData) @trusted {
            import std.zlib : uncompress;
            
            char[] profileName;
            foreach(i, c; chunkData) {
                if (i >= 80)
                    throw allocator.make!ImageNotLoadableException("iCCP chunk profile name must be less then 80 characters long (c-string\\0)");
                
                if (c == 0)  {// null terminator
                    if (i == 0) // error
                        throw allocator.make!ImageNotLoadableException("iCCP chunk profile name must be atleast 1 character in length");
                    
                    profileName = cast(char[])chunkData[0 .. i];
                    
                    if (i + 2 < chunkData.length)
                        throw allocator.make!ImageNotLoadableException("iCCP chunk data is not long enough");
                    chunkData = chunkData[i + 1 .. $];
                    break;
                }
            }
            
            iCCP = allocator.make!iCCP_Chunk();
            
            // profile name
            iCCP.profileName = cast(string)allocator.makeArray!char(profileName.length);
            cast(char[])iCCP.profileName[] = profileName[];
            
            // compression method deflate/inflate
            iCCP.compressionMethod = cast(PngIHDRCompresion)chunkData[0];
            
            //
            if (iCCP.compressionMethod == PngIHDRCompresion.DeflateInflate) {
                iCCP.profile = cast(ubyte[])uncompress(chunkData[1 .. $]);
            } else {
                throw allocator.make!ImageNotLoadableException("Unknown iCCP chunk compression method");
            }
        }
        
        void readChunk_PLTE(ubyte[] chunkData) @trusted {
            PLTE = allocator.make!PLTE_Chunk;
            
            if ((chunkData.length % 3) > 0)
                throw allocator.make!ImageNotLoadableException("PLTE chunk size must be devisible by 3");
            else if ((chunkData.length / 3) > 256)
                throw allocator.make!ImageNotLoadableException("PLTE chunk must contain at the most 256 entries");
            
            PLTE.colors = allocator.makeArray!(PLTE_Chunk.Color)(chunkData.length / 3);

            size_t offset;
            for (size_t i; i < (chunkData.length / 3); i++) {
                PLTE.colors[i] = PLTE_Chunk.Color(chunkData[offset], chunkData[offset + 1], chunkData[offset + 2]);
                offset += 3;
            }
        }
        
        void readChunk_gAMA(ubyte[] chunkData) @trusted {
            if (chunkData.length != 4)
                throw allocator.make!ImageNotLoadableException("gAMA chunk must be 4 bytes in size");
            
            gAMA = allocator.make!gAMA_Chunk(bigEndianToNative!uint(cast(ubyte[4])chunkData[0 .. 4]));    
        }
        
        void readChunk_tRNS(ubyte[] chunkData) @trusted {
            import std.range : inputRangeObject;
            tRNS = allocator.make!tRNS_Chunk();
            
            if (IHDR.colorType & PngIHDRColorType.Palette) {
                tRNS.indexAlphas = allocator.makeArray!ubyte(chunkData.length);
                tRNS.indexAlphas[] = chunkData[];
            } else if (IHDR.colorType & PngIHDRColorType.Grayscale) {
                if (chunkData.length != 2)
                    throw allocator.make!ImageNotLoadableException("tRNS chunk size must be 2 bytes when it is grayscale");
                
                if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                    ushort c = bigEndianToNative!ushort(cast(ubyte[2])chunkData[0 .. 2]);
                    tRNS.b16 = RGB16(c, c, c);
                } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                    // TODO: confirm that it is the first byte and not the second?
                    tRNS.b8 = RGB8(chunkData[0], chunkData[0], chunkData[0]);
                } else {
                    ubyte c = cast(ubyte)(chunkData[0] * cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1));
                    tRNS.b8 = RGB8(c, c, c);
                }
            } else if (IHDR.colorType & PngIHDRColorType.ColorUsed) {
                if (chunkData.length != 3)
                    throw allocator.make!ImageNotLoadableException("tRNS chunk size must be 2 bytes when it is grayscale");
                
                if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                    ushort r = bigEndianToNative!ushort(cast(ubyte[2])chunkData[0 .. 2]);
                    ushort g = bigEndianToNative!ushort(cast(ubyte[2])chunkData[2 .. 4]);
                    ushort b = bigEndianToNative!ushort(cast(ubyte[2])chunkData[4 .. 6]);
                    tRNS.b16 = RGB16(r, g, b);
                } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                    // TODO: confirm that it is the first byte and not the second?
                    tRNS.b8 = RGB8(chunkData[0], chunkData[2], chunkData[4]);
                } else {
                    tRNS.b8 = RGB8(cast(ubyte)(chunkData[0] * cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1)),
                        cast(ubyte)(chunkData[2] * cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1)),
                        cast(ubyte)(chunkData[4] * cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1)));
                }
            }
        }
        
        void readChunk_tEXt(ubyte[] chunkData) @trusted {
            size_t sinceLast;
            ubyte[] buffer;
            ubyte[] keyword;
            
            if (chunkData.length < 2)
                throw allocator.make!ImageNotLoadableException("tEXt chunk must be atleast 2 bytes");
            
            foreach(i, c; chunkData) {
                if (c == 0) {
                    keyword = buffer;
                    buffer = null;
                    sinceLast = i + 1;
                } else {
                    buffer = chunkData[sinceLast .. i + 1];
                }
            }
            
            char[] keyword2 = allocator.makeArray!char(keyword.length);
            keyword2[] = cast(char[])keyword[];
            char[] buffer2 = allocator.makeArray!char(buffer.length);
            buffer2[] = cast(char[])buffer[];
            
            tEXt[cast(PngTextKeywords)keyword2] = cast(string)buffer2;
        }
        
        void readChunk_zEXt(ubyte[] chunkData) @trusted {
            import std.zlib : uncompress;
            
            size_t sinceLast;
            ubyte[] buffer;
            ubyte[] keyword;
            
            if (chunkData.length < 2)
                throw allocator.make!ImageNotLoadableException("zEXt chunk must be atleast 2 bytes");
            
            foreach(i, c; chunkData) {
                if (c == 0) {
                    keyword = buffer;
                    buffer = null;
                    sinceLast = i + 1;
                } else {
                    buffer = chunkData[sinceLast .. i + 1];
                }
            }
            
            char[] keyword2 = allocator.makeArray!char(keyword.length);
            keyword2[] = cast(char[])keyword[];
            
            if (buffer.length > 0)
                throw allocator.make!ImageNotLoadableException("zEXt chunk must have a compression method");
            
            ubyte compressionMethod = buffer[0];
            if (compressionMethod > 0)
                throw allocator.make!ImageNotLoadableException("zEXt chunk unknown compression method");
            
            buffer = cast(ubyte[])uncompress(buffer);
            
            char[] buffer2 = allocator.makeArray!char(buffer.length - 1);
            buffer2[] = cast(char[])buffer[1 .. $];
            
            tEXt[cast(PngTextKeywords)keyword2] = cast(string)buffer2;
        }
        
        void readChunk_iEXt(ubyte[] chunkData) @trusted {
            import std.zlib : uncompress;
            
            size_t sinceLast;
            ubyte[] buffer;
            ubyte[] keyword;
            
            if (chunkData.length < 2)
                throw allocator.make!ImageNotLoadableException("iEXt chunk must be atleast 2 bytes");
            
            foreach(i, c; chunkData) {
                if (c == 0 && keyword !is null) {
                    //keyword = buffer;
                    buffer = null;
                    sinceLast = i + 1;
                } else {
                    buffer = chunkData[sinceLast .. i + 1];
                }
            }
            
            if (buffer.length > 0)
                throw allocator.make!ImageNotLoadableException("iEXt chunk must have a compression method");
            bool useCompression = cast(bool)buffer[0];
            ubyte compressionMethod = buffer[1];
            if (useCompression && compressionMethod > 0)
                throw allocator.make!ImageNotLoadableException("iEXt chunk unknown compression method");
            buffer = buffer[1 .. $];
            
            if (buffer.length > 0)
                throw allocator.make!ImageNotLoadableException("iEXt chunk must have a language");
            
            ubyte[] buffer2;
            ubyte[] language;
            foreach(i, c; buffer) {
                if (c == 0 && language !is null) {
                    language = buffer2;
                    buffer2 = null;
                    sinceLast = i + 1;
                } else {
                    buffer2 = buffer[sinceLast .. i + 1];
                }
            }
            buffer = buffer2;
            
            if (buffer.length > 0)
                throw allocator.make!ImageNotLoadableException("iEXt chunk must have a translated keyword");
            
            foreach(i, c; buffer) {
                if (c == 0 && language !is null) {
                    keyword = buffer2;
                    buffer2 = null;
                    sinceLast = i + 1;
                } else {
                    buffer2 = buffer[sinceLast .. i + 1];
                }
            }
            buffer = buffer2;
            
            if (useCompression && compressionMethod == 0)
                buffer = cast(ubyte[])uncompress(buffer);
            
            char[] keyword2 = allocator.makeArray!char(keyword.length);
            keyword2[] = cast(char[])keyword[];
            
            char[] buffer3 = allocator.makeArray!char(buffer.length);
            buffer3 = cast(char[])buffer[];
            
            if (useCompression)
                zEXt[cast(PngTextKeywords)keyword2] = cast(string)buffer3;
            else
                tEXt[cast(PngTextKeywords)keyword2] = cast(string)buffer3;
        }
        
        void readChunk_bKGD(ubyte[] chunkData) @trusted {
            bKGD = allocator.make!bKGD_Chunk();
            
            if (IHDR.colorType & PngIHDRColorType.Palette) {
                if (chunkData.length != 2)
                    throw allocator.make!ImageNotLoadableException("bKGD chunk size must be 1 bytes when it is palette");
                
                bKGD.index = chunkData[0];
            } else if (IHDR.colorType & PngIHDRColorType.Grayscale) {
                if (chunkData.length != 2)
                    throw allocator.make!ImageNotLoadableException("bKGD chunk size must be 2 bytes when it is grayscale");
                
                if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                    ushort c = bigEndianToNative!ushort(cast(ubyte[2])chunkData[0 .. 2]);
                    bKGD.b16 = RGB16(c, c, c);
                } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                    // TODO: confirm that it is the first byte and not the second?
                    bKGD.b8 = RGB8(chunkData[0], chunkData[0], chunkData[0]);
                } else {
                    ubyte c = cast(ubyte)(chunkData[0] * cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1));
                    bKGD.b8 = RGB8(c, c, c);
                }
            } else if (IHDR.colorType & PngIHDRColorType.ColorUsed) {
                if (chunkData.length != 3)
                    throw allocator.make!ImageNotLoadableException("bKGD chunk size must be 2 bytes when it is grayscale");
                
                if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                    ushort r = bigEndianToNative!ushort(cast(ubyte[2])chunkData[0 .. 2]);
                    ushort g = bigEndianToNative!ushort(cast(ubyte[2])chunkData[2 .. 4]);
                    ushort b = bigEndianToNative!ushort(cast(ubyte[2])chunkData[4 .. 6]);
                    bKGD.b16 = RGB16(r, g, b);
                } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                    // TODO: confirm that it is the first byte and not the second?
                    bKGD.b8 = RGB8(chunkData[0], chunkData[2], chunkData[4]);
                } else {
                    bKGD.b8 = RGB8(cast(ubyte)(chunkData[0] * cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1)),
                        cast(ubyte)(chunkData[2] * cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1)),
                        cast(ubyte)(chunkData[4] * cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1)));
                }
            }
        }
        
        void readChunk_pPHs(ubyte[] chunkData) @trusted {
            pPHs = allocator.make!pPHs_Chunk();
            if (chunkData.length != 9)
                throw allocator.make!ImageNotLoadableException("pPHs chunk size must be 9 bytes");
            
            pPHs.ppx = bigEndianToNative!uint(cast(ubyte[4])chunkData[0 .. 4]);
            pPHs.ppy = bigEndianToNative!uint(cast(ubyte[4])chunkData[4 .. 8]);
            pPHs.unit = cast(PngPhysicalPixelUnit)chunkData[8];
        }
        
        void readChunk_sBIT(ubyte[] chunkData) @trusted {
            sBIT = allocator.make!sBIT_Chunk();
            
            if (IHDR.colorType & PngIHDRColorType.Palette) {
                if (chunkData.length != 3)
                    throw allocator.make!ImageNotLoadableException("sBIT chunk size must be 3 byte for palette color type");
                
                sBIT.indexed[] = chunkData[0 .. 3];
            } else if (IHDR.colorType & PngIHDRColorType.Grayscale) {
                bool withAlpha = (IHDR.colorType & PngIHDRColorType.AlphaChannelUsed) == PngIHDRColorType.AlphaChannelUsed;
                
                if ((!withAlpha && chunkData.length != 1) || (withAlpha && chunkData.length != 2))
                    throw allocator.make!ImageNotLoadableException("sBIT chunk size must be 1 byte for grayscale color type and 2 for grayscale with alpha");
                
                if (withAlpha)
                    sBIT.grayScaleAlpha[] = chunkData[0 .. 2];
                else
                    sBIT.grayScale = chunkData[0];
            } else if (IHDR.colorType & PngIHDRColorType.ColorUsed) {
                bool withAlpha = (IHDR.colorType & PngIHDRColorType.AlphaChannelUsed) == PngIHDRColorType.AlphaChannelUsed;
                
                if ((!withAlpha && chunkData.length != 3) || (withAlpha && chunkData.length != 4))
                    throw allocator.make!ImageNotLoadableException("sBIT chunk size must be 3 bytes for truecolor color type and 4 for truecolor with alpha");
                
                if (withAlpha)
                    sBIT.trueColorAlpha[] = chunkData[0 .. 4];
                else
                    sBIT.trueColor[] = chunkData[0 .. 3];
            }
        }
        
        void readChunk_sPLT(ubyte[] chunkData) @trusted {
            sPLT_Chunk chunk;
            
            if (chunkData.length < 2)
                throw allocator.make!ImageNotLoadableException("sPLT chunk size must greater than 2 bytes");
            
            ubyte[] buffer;
            char[] name;
            size_t sinceLast;
            
            foreach(i, c; chunkData) {
                if (c == 0 && name !is null) {
                    name = cast(char[])buffer;
                    buffer = null;
                    sinceLast = i + 1;
                } else {
                    buffer = buffer[sinceLast .. i + 1];
                }
            }
            
            chunk.paletteName = cast(string)allocator.makeArray!char(buffer.length);
            (cast(char[])chunk.paletteName)[] = name;
            
            if (buffer.length < 2)
                throw allocator.make!ImageNotLoadableException("sPLT chunk size must be greater than 1 byte for sample depth");
            
            chunk.sampleDepth = cast(PngIHDRBitDepth)buffer[0];
            buffer = buffer[1 .. $];
            
            size_t count;
            if (chunk.sampleDepth == PngIHDRBitDepth.BitDepth8) {
                if (buffer.length % 6 == 0) {
                    chunk.colors = allocator.makeArray!(sPLT_Chunk.Entry)(buffer.length / 6);
                    
                    for(size_t i; i < buffer.length; i += 6) {
                        ubyte[2] values;
                        values[] = chunkData[i + 4 .. i + 6];
                        
                        chunk.colors[count].color.b8 = RGBA8(chunkData[i], chunkData[i + 1], chunkData[i + 2], chunkData[i + 3]);
                        chunk.colors[count].frequency = bigEndianToNative!ushort(values);
                        count++;
                    }
                } else {
                    throw allocator.make!ImageNotLoadableException("sPLT chunk palette must be devisible by 6 for sample depth of 8");
                }
            } else if (chunk.sampleDepth == PngIHDRBitDepth.BitDepth16) {
                if (buffer.length % 10 == 0) {
                    chunk.colors = allocator.makeArray!(sPLT_Chunk.Entry)(buffer.length / 10);
                    
                    for(size_t i; i < buffer.length; i += 10) {
                        ubyte[2][5] values;
                        values[0][] = chunkData[i .. i + 2];
                        values[1][] = chunkData[i + 2 .. i + 4];
                        values[2][] = chunkData[i + 4 .. i + 6];
                        values[3][] = chunkData[i + 6 .. i + 8];
                        values[4][] = chunkData[i + 8 .. i + 10];
                        
                        chunk.colors[count].color.b16 = RGBA16(
                            bigEndianToNative!ushort(values[0]),
                            bigEndianToNative!ushort(values[1]),
                            bigEndianToNative!ushort(values[2]),
                            bigEndianToNative!ushort(values[3]));
                        chunk.colors[count].frequency = bigEndianToNative!ushort(values[4]);
                        count++;
                    }
                } else {
                    throw allocator.make!ImageNotLoadableException("sPLT chunk palette must be devisible by 10 for sample depth of 16");
                }
            } else {
                throw allocator.make!ImageNotLoadableException("sPLT chunk must have a bit depth of either 8 or 16");
            }
            
            sPLT ~= chunk;
        }
        
        void readChunk_hIST(ubyte[] chunkData) @trusted {
            if (chunkData.length % 2 == 1)
                throw allocator.make!ImageNotLoadableException("hIST chunk must be devisible by 2");
            size_t count = chunkData.length / 2;
            
            size_t ci;
            foreach(i; hIST.length - count .. hIST.length) {
                ubyte[2] values;
                values[] = chunkData[ci .. ci + 2];
                hIST ~= bigEndianToNative!ushort(values);
                
                ci += 2;
            }
        }
        
        void readChunk_tIME(ubyte[] chunkData) @trusted {
            if (chunkData.length != 7)
                throw allocator.make!ImageNotLoadableException("tIME chunk must be 7 bytes");
            
            int[6] values = [
                bigEndianToNative!short(cast(ubyte[2])chunkData[0 .. 2]),
                chunkData[2], chunkData[3], chunkData[4], chunkData[5], chunkData[6]
            ];
            
            if ((values[1] >= 1 && values[1] <= 12) &&
                (values[2] >= 1 && values[2] <= 31) &&
                (values[3] >= 0 && values[3] <= 23) &&
                (values[4] >= 0 && values[4] <= 59) &&
                (values[5] >= 0 && values[5] <= 60)) {}
            else
                throw allocator.make!ImageNotLoadableException("tIME chunk date time value is invalid");
            
            tIME = allocator.make!DateTime(values[0], values[1], values[2], values[3], values[4], values[5]);
        }
        
        static if (!is(Color == HeadersOnly)) {
            void readChunk_IDAT(ubyte[] chunkData) @trusted {
                import std.zlib : uncompress; // FIXME: std.zlib allocates without using the allocator *grumbles*
                import std.math : ceil, floor;

                // a simple check
                if (IHDR.interlaceMethod == PngIHDRInterlaceMethod.Adam7 || IHDR.interlaceMethod == PngIHDRInterlaceMethod.NoInterlace)
                {} else
                    throw allocator.make!ImageNotLoadableException("IDAT unknown interlace method");

                if (IHDR.compressionMethod == PngIHDRCompresion.DeflateInflate) {}
                else
                    throw allocator.make!ImageNotLoadableException("IDAT unknown compression method");

                // constants
                size_t pixelPreviousByteAmount;
                size_t totalSize, scanLineSize;
                size_t[7] /+rowsPerPass, +/scanLinesSize;

                bool withAlpha = (IHDR.colorType & PngIHDRColorType.AlphaChannelUsed) == PngIHDRColorType.AlphaChannelUsed;
                bool isGrayScale = (IHDR.colorType & PngIHDRColorType.Grayscale) == PngIHDRColorType.Grayscale;
                bool isPalette = (IHDR.colorType & PngIHDRColorType.Palette) == PngIHDRColorType.Palette;
                bool isColor = (IHDR.colorType & PngIHDRColorType.ColorUsed) == PngIHDRColorType.ColorUsed;

                // some needed variables, in future processing
                ubyte[] decompressed, previousScanLine, tempBitDepth124, myAdaptiveOffsets;
                ubyte pass, sampleSize, pixelSampleSize;
                size_t offsetX, offsetY, offset, currentRow;

                final switch(IHDR.colorType) {
                    case PngIHDRColorType.AlphaChannelUsed:
                        sampleSize = 2;
                        break;
                    case PngIHDRColorType.PalletteWithColorUsed:
                    case PngIHDRColorType.Palette:
                    case PngIHDRColorType.Grayscale:
                        sampleSize = 1;
                        break;
                    case PngIHDRColorType.ColorUsedWithAlpha:
                        sampleSize = 4;
                        break;
                    case PngIHDRColorType.ColorUsed:
                        sampleSize = 3;
                        break;
                }

                if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                    pixelSampleSize = cast(ubyte)(sampleSize + sampleSize);
                    pixelPreviousByteAmount = pixelSampleSize;
                    scanLineSize = pixelSampleSize * IHDR.width;
                } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                    pixelSampleSize = sampleSize;
                    pixelPreviousByteAmount = sampleSize;
                    scanLineSize = sampleSize * IHDR.width;
                } else {
                    pixelSampleSize = sampleSize;
                    pixelPreviousByteAmount = 1;
                    tempBitDepth124 = alloc.makeArray!ubyte(8);
                    
                    if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth1)
                        scanLineSize = cast(size_t)ceil((sampleSize * IHDR.width) / 8f);
                    else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth2)
                        scanLineSize = cast(size_t)ceil((sampleSize * IHDR.width) / 4f);
                    else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth4)
                        scanLineSize = cast(size_t)ceil((sampleSize * IHDR.width) / 2f);
                }

                totalSize = IHDR.width * pixelSampleSize * IHDR.height;

                if (IHDR.filterMethod == PngIHDRFilter.Adaptive) {
                    scanLineSize += 1;
                    totalSize += IHDR.height;
                }
                
                // no point calculating this if we are not gonna use it!
                if (IHDR.interlaceMethod == PngIHDRInterlaceMethod.Adam7) {
                    if (IHDR.filterMethod == PngIHDRFilter.Adaptive)
                        myAdaptiveOffsets = alloc.makeArray!ubyte(IHDR.height);
                
                    // calculates the length of each scan line per pass (Adam7)
                    for(pass = 0; pass < 7; pass++) {
                        if (starting_row[pass] >= IHDR.height) {
                            scanLinesSize[pass] = 0;
                        } else {
                            float tscanLineSize = IHDR.width * pixelSampleSize;
                            tscanLineSize -= starting_col[pass];
                            tscanLineSize /= col_increment[pass];

                            if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth1)
                                tscanLineSize /= 8f;
                            else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth2)
                                tscanLineSize /= 4f;
                            else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth4)
                                tscanLineSize /= 2f;

                            tscanLineSize = ceil(tscanLineSize);

                            if (IHDR.filterMethod == PngIHDRFilter.Adaptive)
                                tscanLineSize += 1;

                            if (tscanLineSize <= 1)
                                tscanLineSize = 0;

                            scanLinesSize[pass] = cast(size_t)tscanLineSize;
                        }
                    }
                }
                
                // decompress
                decompressed = cast(ubyte[])uncompress(chunkData, totalSize);

                void assignPixel(ColorP)(ColorP valuec) {
                    // store color at coordinate
                    static if (is(ColorP == Color))
                        value.setPixel(offsetX, offsetY, valuec);
                    else
                        value.setPixel(offsetX, offsetY, valuec.convertColor!Color);

                    // changes x and y coordinates for no interlace
                    if (IHDR.interlaceMethod == PngIHDRInterlaceMethod.NoInterlace) {
                        offsetX++;
                        
                        if (offsetX == IHDR.width) {
                            offsetX = 0;
                            offsetY++;
                        }
                    } else if (IHDR.interlaceMethod == PngIHDRInterlaceMethod.Adam7)
                        offsetX += col_increment[pass];
                }

                void grabPixelsFromScanLine(ubyte[] scanLine) {
                    bool useMultiByte = IHDR.bitDepth == PngIHDRBitDepth.BitDepth16;
                    
                    void handleSamples(ubyte[] samples) {
                        while(samples.length > 0) {
                            if (isPalette) {
                                    ubyte v = samples[0];
                                    if (v >= PLTE.colors.length)
                                        throw allocator.make!ImageNotLoadableException("IDAT unknown palette color");

                                    assignPixel(PLTE.colors[v]);
                                    samples = samples[1 .. $];
                            } else if (useMultiByte) {
                                if (isColor) {
                                    ushort[4] values;
                                    values[0] = bigEndianToNative!ushort(cast(ubyte[2])samples[0 .. 2]);
                                    values[1] = bigEndianToNative!ushort(cast(ubyte[2])samples[2 .. 4]);
                                    values[2] = bigEndianToNative!ushort(cast(ubyte[2])samples[4 .. 6]);
                                    
                                    if (withAlpha) {
                                        values[3] = bigEndianToNative!ushort(cast(ubyte[2])samples[6 .. 8]);
                                        assignPixel(RGBA16(values[0], values[1], values[2], values[3]));
                                        samples = samples[8 .. $];
                                    } else {
                                        assignPixel(RGB16(values[0], values[1], values[2]));
                                        samples = samples[6 .. $];
                                    }
                                } else if (isGrayScale) {
                                    ushort v = bigEndianToNative!ushort(cast(ubyte[2])samples[0 .. 2]);
                                    
                                    if (withAlpha) {
                                        assignPixel(RGBA16(v, v, v, bigEndianToNative!ushort(cast(ubyte[2])samples[2 .. 4])));
                                        samples = samples[4 .. $];
                                    } else {
                                        assignPixel(RGB16(v, v, v));
                                        samples = samples[2 .. $];
                                    }
                                }
                            } else {
                                if (isColor) {
                                    if (withAlpha) {
                                        assignPixel(RGBA8(samples[0], samples[1], samples[2], samples[3]));
                                        samples = samples[4 .. $];
                                    } else {
                                        assignPixel(RGB8(samples[0], samples[1], samples[2]));
                                        samples = samples[3 .. $];
                                    }
                                } else if (isGrayScale) {
                                    ubyte v = samples[0];
                                    
                                    if (withAlpha) {
                                        assignPixel(RGBA8(v, v, v, samples[1]));
                                        samples = samples[2 .. $];
                                    } else {
                                        assignPixel(RGB8(v, v, v));
                                        samples = samples[1 .. $];
                                    }
                                }
                            }
                        }
                    }

                    if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16 || IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                        handleSamples(scanLine);
                    } else {
                        ptrdiff_t maxSamples = IHDR.width;
                        if (IHDR.interlaceMethod == PngIHDRInterlaceMethod.Adam7)
                            maxSamples = cast(size_t)ceil((maxSamples - starting_col[pass]) / cast(float)col_increment[pass]);
                        maxSamples *= sampleSize;

                        // 1, 2, 4 bit depths
                        foreach(scb; scanLine) {
                            ubyte[] samples;
                            
                            if (maxSamples <= 0)
                                return;
                            
                            if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth4) {
                                samples = tempBitDepth124[0 .. 2];

                                samples[1] = cast(ubyte)((scb & 15) >> 0);
                                samples[0] = cast(ubyte)((scb & 240) >> 4);
                                
                                if (!isPalette) {
                                    samples[0] *= 17;
                                    samples[1] *= 17;
                                }
                            } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth2) {
                                samples = tempBitDepth124[0 .. 4];

                                samples[3] = cast(ubyte)((scb & 3) >> 0);
                                samples[2] = cast(ubyte)((scb & 12) >> 2);
                                samples[1] = cast(ubyte)((scb & 48) >> 4);
                                samples[0] = cast(ubyte)((scb & 192) >> 6);
                                
                                if (!isPalette) {
                                    samples[0] *= 85;
                                    samples[1] *= 85;
                                    samples[2] *= 85;
                                    samples[3] *= 85;
                                }
                            } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth1) {
                                samples = tempBitDepth124[0 .. 8];

                                samples[7] = cast(ubyte)((scb & 1) >> 0);
                                samples[6] = cast(ubyte)((scb & 2) >> 1);
                                samples[5] = cast(ubyte)((scb & 4) >> 2);
                                samples[4] = cast(ubyte)((scb & 8) >> 3);
                                samples[3] = cast(ubyte)((scb & 16) >> 4);
                                samples[2] = cast(ubyte)((scb & 32) >> 5);
                                samples[1] = cast(ubyte)((scb & 64) >> 6);
                                samples[0] = cast(ubyte)((scb & 128) >> 7);
                                
                                if (!isPalette) {
                                    samples[0] *= 255;
                                    samples[1] *= 255;
                                    samples[2] *= 255;
                                    samples[3] *= 255;
                                    samples[4] *= 255;
                                    samples[5] *= 255;
                                    samples[6] *= 255;
                                    samples[7] *= 255;
                                }
                            }

                            if (samples.length <= maxSamples)
                                handleSamples(samples);
                            else
                                handleSamples(samples[0 .. maxSamples]);
                            maxSamples -= samples.length;
                        }
                    }
                }

                // defilters the scan line
                previousScanLine = null;
                void scanLineDefilter(ubyte adaptiveOffset, ubyte[] scanLine) {
                    // defilter
                    if (IHDR.filterMethod == PngIHDRFilter.Adaptive) {
                        if (scanLine.length <= 0) {
                            previousScanLine = null;
                            return;
                        }
                        
                        foreach(i; 0 .. scanLine.length) {
                            switch(adaptiveOffset) {
                                case 1: // sub
                                    // Sub(x) + Raw(x-bpp)
                                    
                                    if (i >= pixelPreviousByteAmount) {
                                        ubyte rawSub = scanLine[i-pixelPreviousByteAmount];
                                        scanLine[i] = cast(ubyte)(scanLine[i] + rawSub);
                                    } else {
                                        // no changes needed
                                    }
                                    
                                    break;
                                    
                                case 2: // up
                                    // Up(x) + Prior(x)
                                    
                                    if (previousScanLine.length > i) {
                                        ubyte prior = previousScanLine[i];
                                        scanLine[i] = cast(ubyte)(scanLine[i] + prior);
                                    } else {
                                        // no changes needed
                                    }
                                    break;
                                    
                                case 3: // average
                                    // Average(x) + floor((Raw(x-bpp)+Prior(x))/2)
                                    
                                    if (previousScanLine.length > i) {
                                        if (i >= pixelPreviousByteAmount) {
                                            ubyte prior = previousScanLine[i];
                                            ubyte rawSub = scanLine[i-pixelPreviousByteAmount];
                                            scanLine[i] = cast(ubyte)(scanLine[i] + floor(cast(real)(rawSub + prior) / 2f));
                                        } else {
                                            ubyte prior = previousScanLine[i];
                                            ubyte rawSub = 0;
                                            scanLine[i] = cast(ubyte)(scanLine[i] + floor(cast(real)(rawSub + prior) / 2f));
                                        }
                                    } else if (i >= pixelPreviousByteAmount) {
                                        ubyte prior = 0;
                                        ubyte rawSub = scanLine[i-pixelPreviousByteAmount];
                                        scanLine[i] = cast(ubyte)(scanLine[i] + floor(cast(real)(rawSub + prior) / 2f));
                                    } else {
                                        // no changes needed
                                    }
                                    break;
                                    
                                case 4: // paeth
                                    //  Paeth(x) + PaethPredictor(Raw(x-bpp), Prior(x), Prior(x-bpp))
                                    
                                    if (previousScanLine.length > i) {
                                        if (i >= pixelPreviousByteAmount) {
                                            ubyte prior = previousScanLine[i];
                                            ubyte rawSub = scanLine[i-pixelPreviousByteAmount];
                                            ubyte priorRawSub = previousScanLine[i-pixelPreviousByteAmount];
                                            scanLine[i] = cast(ubyte)(scanLine[i] + PaethPredictor(rawSub, prior, priorRawSub));
                                        } else {
                                            ubyte prior = previousScanLine[i];
                                            ubyte rawSub = 0;
                                            ubyte priorRawSub = 0;
                                            scanLine[i] = cast(ubyte)(scanLine[i] + PaethPredictor(rawSub, prior, priorRawSub));
                                        }
                                    } else if (i >= pixelPreviousByteAmount) {
                                        ubyte prior = 0;
                                        ubyte rawSub = scanLine[i-pixelPreviousByteAmount];
                                        ubyte priorRawSub = 0;
                                        scanLine[i] = cast(ubyte)(scanLine[i] + PaethPredictor(rawSub, prior, priorRawSub));
                                    } else {
                                        // no changes needed
                                    }
                                    
                                    break;
                                    
                                default:
                                case 0: // none
                                    break;
                            }
                        }
                    }

                    previousScanLine = scanLine;
                    grabPixelsFromScanLine(scanLine);
                }

                size_t lastYStart = size_t.max;

                // performs the actual parsing of the scanlines
                if (IHDR.interlaceMethod == PngIHDRInterlaceMethod.Adam7) {
                    pass = 0;
                    
                    while(pass < 7) {
                        offsetY = starting_row[pass];
                        scanLineSize = scanLinesSize[pass];
                        
                        if (scanLineSize == 0) {
                            pass++;
                            continue;
                        }
                        
                        while(offsetY < IHDR.height) {
                            offsetX = starting_col[pass];
                            bool thisScanLine = IHDR.bitDepth != PngIHDRBitDepth.BitDepth1 || !(offsetY == lastYStart && offsetX > 0);
                            
                            if (IHDR.filterMethod == PngIHDRFilter.Adaptive) {
                                if (thisScanLine) {
                                    myAdaptiveOffsets[offsetY] = decompressed[offset];
                                    scanLineDefilter(myAdaptiveOffsets[offsetY], decompressed[offset + 1 .. offset + scanLineSize]);
                                    offset += scanLineSize;
                                } else {
                                    scanLineDefilter(myAdaptiveOffsets[offsetY], decompressed[offset .. offset + (scanLineSize - 1)]);
                                    offset += (scanLineSize - 1);
                                }
                            } else {
                                assert(0);
                            }
                            
                            lastYStart = offsetY;
                            offsetY += row_increment[pass];
                        }

                        pass++;
                    }
                } else {
                    while(offset < decompressed.length) {
                        if (IHDR.filterMethod == PngIHDRFilter.Adaptive) {
                            scanLineDefilter(decompressed[offset], decompressed[offset + 1 .. offset + scanLineSize]);
                        } else {
                            assert(0);
                        }
                        offset += scanLineSize;
                    }
                }
                
                alloc.dispose(tempBitDepth124);
            }
        }
        
        void readChunk_IEND(ubyte[] chunkData) @safe {
            // IEND chunk should be the last one.
            // It doesn't do anything special other then say, this is the end.
            // Now stop looking for more chunks!
        }
        
        /*
         * The exporter
         */
        
        managed!(ubyte[]) performExport() @trusted {
            import std.digest.crc : crc32Of;
            ubyte[] buffer = allocator.makeArray!ubyte((1024 * 1024 * 8) + 4); // 8mb
			assert(buffer.length > 0);

            import core.memory : GC;
            GC.disable;
            
            ubyte[] ret = allocator.makeArray!ubyte(8);
            ret[0 .. 8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
            
            void writeChunk(char[4] name, ubyte[] data) @trusted {
                size_t len = data.length + 12; // name + length + crc
                allocator.expandArray(ret, len);

                ret[$-len .. $][0 .. 4] = nativeToBigEndian(cast(uint)data.length);
                ret[$-len .. $][4 .. 8] = cast(ubyte[4])name[];
                ret[$-len .. $][8 .. $-4] = data[];
                
                buffer[0 .. 4] = cast(ubyte[4])name[];
                ret[$-4 .. $] = nativeToBigEndian(*cast(uint*)crc32Of(buffer[0 .. data.length + 4]).ptr);
            }
            
            writeChunk_IHDR(buffer[4 .. $], &writeChunk);
            if (gAMA !is null)
                writeChunk_gAMA(buffer[4 .. $], &writeChunk);
            if (PLTE !is null)
                writeChunk_PLTE(buffer[4 .. $], &writeChunk);
            if (tRNS !is null)
                writeChunk_tRNS(buffer[4 .. $], &writeChunk);
            if (cHRM !is null)
                writeChunk_cHRM(buffer[4 .. $], &writeChunk);
            if (sRGB !is null)
                writeChunk_sRGB(buffer[4 .. $], &writeChunk);
            if (iCCP !is null)
                writeChunk_iCCP(buffer[4 .. $], &writeChunk);
                
            writeChunk_tEXt(buffer[4 .. $], &writeChunk);
            writeChunk_zEXt(buffer[4 .. $], &writeChunk);

            if (bKGD !is null)
                writeChunk_bKGD(buffer[4 .. $], &writeChunk);
            if (pPHs !is null)
                writeChunk_pPHs(buffer[4 .. $], &writeChunk);
            if (sBIT !is null)
                writeChunk_sBIT(buffer[4 .. $], &writeChunk);
            if (sPLT.length > 0)
                writeChunk_sPLT(buffer[4 .. $], &writeChunk);
            if (hIST.length > 0)
                writeChunk_hIST(buffer[4 .. $], &writeChunk);
            if (tIME !is null)
                writeChunk_tIME(buffer[4 .. $], &writeChunk);

            static if (!is(Color == HeadersOnly)) {
                writeChunk_IDAT(buffer[4 .. $], &writeChunk);
            }

            // it contains nothing, so why bother having a dedicated method?
            writeChunk(cast(char[4])"IEND", null);
            
			GC.enable;
			allocator.dispose(buffer);
            return managed!(ubyte[])(ret, managers(), Ownership.Secondary, alloc);
        }
        
        void writeChunk_IHDR(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite;
            
            towrite = buffer[0 .. 13];
            towrite[0 .. 4] = nativeToBigEndian(IHDR.width);
            towrite[4 .. 8] = nativeToBigEndian(IHDR.height);
            towrite[8 .. 9] = nativeToBigEndian(IHDR.bitDepth);
            towrite[9 .. 10] = nativeToBigEndian(IHDR.colorType);
            towrite[10 .. 11] = nativeToBigEndian(IHDR.compressionMethod);
            towrite[11 .. 12] = nativeToBigEndian(IHDR.filterMethod);
            towrite[12 .. 13] = nativeToBigEndian(IHDR.interlaceMethod);
            
            write(cast(char[4])"IHDR", towrite);
        }
        
        void writeChunk_PLTE(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite;
            
            towrite = buffer[0 .. PLTE.colors.length * 3];

            size_t offset;
            foreach(i, c; PLTE.colors) {
                towrite[offset] = c.r;
                towrite[offset + 1] = c.g;
                towrite[offset + 2] = c.b;

                offset += 3;
            }

            write(cast(char[4])"PLTE", towrite);
        }
        
        void writeChunk_tRNS(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite;
            
            if (IHDR.colorType & PngIHDRColorType.Palette) {
                towrite = buffer[0 .. tRNS.indexAlphas.length];
                towrite[] = tRNS.indexAlphas[];
            } else if (IHDR.colorType & PngIHDRColorType.Grayscale) {
                if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                    towrite = buffer[0 .. 2];
                    towrite[] = nativeToBigEndian(tRNS.b16.r);
                } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                    towrite = buffer[0 .. 2];
                    towrite[0] = tRNS.b8.r;
                } else {
                    towrite = buffer[0 .. 2];
                    towrite[0] = cast(ubyte)(tRNS.b8.r / cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1));
                }
            } else if (IHDR.colorType & PngIHDRColorType.ColorUsed) {
                if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                    towrite = buffer[0 .. 6];
                    towrite[0 .. 2] = nativeToBigEndian(tRNS.b16.r);
                    towrite[2 .. 4] = nativeToBigEndian(tRNS.b16.g);
                    towrite[4 .. 6] = nativeToBigEndian(tRNS.b16.b);
                } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                    towrite = buffer[0 .. 6];
                    towrite[0] = tRNS.b8.r;
                    towrite[2] = tRNS.b8.g;
                    towrite[4] = tRNS.b8.b;
                } else {
                    towrite = buffer[0 .. 6];
                    towrite[0] = cast(ubyte)(tRNS.b8.r / cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1));
                    towrite[2] = cast(ubyte)(tRNS.b8.g / cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1));
                    towrite[4] = cast(ubyte)(tRNS.b8.b / cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1));
                }
            }
            
            write(cast(char[4])"tRNS", towrite);
        }
        
        void writeChunk_gAMA(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite = buffer[0 .. 4];
            towrite[] = nativeToBigEndian(gAMA.value);
            write(cast(char[4])"gAMA", towrite);
        }
        
        void writeChunk_cHRM(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite = buffer[0 .. 32];
            towrite[0 .. 4] = nativeToBigEndian(cHRM.white_x);
            towrite[4 .. 8] = nativeToBigEndian(cHRM.white_y);
            towrite[8 .. 12] = nativeToBigEndian(cHRM.red_x);
            towrite[12 .. 16] = nativeToBigEndian(cHRM.red_y);
            towrite[16 .. 20] = nativeToBigEndian(cHRM.green_x);
            towrite[20 .. 24] = nativeToBigEndian(cHRM.green_y);
            towrite[24 .. 28] = nativeToBigEndian(cHRM.blue_x);
            towrite[28 .. 32] = nativeToBigEndian(cHRM.blue_y);
            write(cast(char[4])"cHRM", towrite);
        }
        
        void writeChunk_sRGB(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite = buffer[0 .. 1];
            towrite[0] = sRGB.intent;
            write(cast(char[4])"sRGB", towrite);
        }
        
        void writeChunk_iCCP(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            import std.zlib : compress;
            ubyte[] towrite;
            
            towrite = buffer[0 .. iCCP.profileName.length + 2];
            towrite[0 .. $-2] = cast(ubyte[])iCCP.profileName[];
            towrite[$-2] = '\0';
            towrite[$-1] = cast(ubyte)iCCP.compressionMethod;
            
            ubyte[] compressed = cast(ubyte[])compress(iCCP.profile);
            towrite = buffer[0 .. towrite.length + compressed.length];
            towrite[$-compressed.length .. $] = compressed[];
            
            write(cast(char[4])"iCCP", towrite);
        }
        
        void writeChunk_tEXt(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            foreach(keyword, value; tEXt) {
                ubyte[] towrite = buffer[0 .. keyword.length + 1];
                
                towrite[0 .. $-1] = cast(ubyte[])keyword[];
                towrite[$-1] = '\0';
                
                towrite = buffer[0 .. towrite.length + value.length];
                towrite[$-value.length .. $] = cast(ubyte[])value[];
                
                write(cast(char[4])"tEXt", towrite);
            }
        }
        
        void writeChunk_zEXt(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            import std.zlib : compress;
            
            foreach(keyword, value; zEXt) {
                ubyte[] towrite = buffer[0 .. keyword.length + 2];
                
                towrite[0 .. $-2] = cast(ubyte[])keyword[];
                towrite[$-2] = '\0';
                towrite[$-1] = PngIHDRCompresion.DeflateInflate;
                
                // FIXME: allocates
                ubyte[] compressed = cast(ubyte[])compress(value);
                
                towrite = buffer[0 .. towrite.length + compressed.length];
                towrite[$-compressed.length .. $] = compressed[];
                
                write(cast(char[4])"zEXt", towrite);
            }
        }
        
        void writeChunk_bKGD(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite;
            
            if (IHDR.colorType & PngIHDRColorType.Palette) {
                towrite = buffer[0 .. 1];
                towrite[0] = bKGD.index;
            } else if (IHDR.colorType & PngIHDRColorType.Grayscale) {
                if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                    towrite = buffer[0 .. 2];
                    towrite[] = nativeToBigEndian(bKGD.b16.r);
                } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                    towrite = buffer[0 .. 2];
                    towrite[0] = bKGD.b8.r;
                } else {
                    towrite = buffer[0 .. 2];
                    towrite[0] = cast(ubyte)(bKGD.b8.r / cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1));
                }
            } else if (IHDR.colorType & PngIHDRColorType.ColorUsed) {
                if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                    towrite = buffer[0 .. 6];
                    towrite[0 .. 2] = nativeToBigEndian(bKGD.b16.r);
                    towrite[2 .. 4] = nativeToBigEndian(bKGD.b16.g);
                    towrite[4 .. 6] = nativeToBigEndian(bKGD.b16.b);
                } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                    towrite = buffer[0 .. 6];
                    towrite[0] = bKGD.b8.r;
                    towrite[2] = bKGD.b8.g;
                    towrite[4] = bKGD.b8.b;
                } else {
                    towrite = buffer[0 .. 6];
                    towrite[0] = cast(ubyte)(bKGD.b8.r / cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1));
                    towrite[2] = cast(ubyte)(bKGD.b8.g / cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1));
                    towrite[4] = cast(ubyte)(bKGD.b8.b / cast(ubyte)(256f/(2^(cast(ubyte)IHDR.bitDepth))-1));
                }
            }
            
            write(cast(char[4])"bKGD", towrite);
        }
        
        void writeChunk_pPHs(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite = buffer[0 .. 9];
            
            towrite[0 .. 4] = nativeToBigEndian(pPHs.ppx);
            towrite[4 .. 8] = nativeToBigEndian(pPHs.ppy);
            towrite[8] = pPHs.unit;
            
            write(cast(char[4])"pPHs", towrite);
        }
        
        void writeChunk_sBIT(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite;
            
            if (IHDR.colorType & PngIHDRColorType.Palette) {
                towrite = buffer[0 .. 3];
                towrite[] = sBIT.indexed[];
            } else if (IHDR.colorType & PngIHDRColorType.Grayscale) {
                bool withAlpha = (IHDR.colorType & PngIHDRColorType.AlphaChannelUsed) == PngIHDRColorType.AlphaChannelUsed;
                
                if (withAlpha) {
                    towrite = buffer[0 .. 2];
                    towrite[] = sBIT.grayScaleAlpha[];
                } else {
                    towrite = buffer[0 .. 1];
                    towrite[0] = sBIT.grayScale;
                }
            } else if (IHDR.colorType & PngIHDRColorType.ColorUsed) {
                bool withAlpha = (IHDR.colorType & PngIHDRColorType.AlphaChannelUsed) == PngIHDRColorType.AlphaChannelUsed;
                
                if (withAlpha) {
                    towrite = buffer[0 .. 4];
                    towrite[] = sBIT.trueColorAlpha[];
                } else {
                    towrite = buffer[0 .. 3];
                    towrite[] = sBIT.trueColor[];
                }
            }
            
            write(cast(char[4])"sBIT", towrite);
        }
        
        void writeChunk_sPLT(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite;
            
            foreach(chunk; sPLT) {
                towrite = buffer[towrite.length .. towrite.length + chunk.paletteName.length + 2];
                towrite[$-(chunk.paletteName.length + 2) .. $-2] = cast(ubyte[])chunk.paletteName[];
                towrite[$-2] = '\0';
                towrite[$-1] = chunk.sampleDepth;
                
                size_t count;
                if (chunk.sampleDepth == PngIHDRBitDepth.BitDepth8) {
                    size_t offset = towrite.length;
                    towrite = buffer[0 .. towrite.length + (chunk.colors.length * 6)];
                    
                    foreach(c; chunk.colors) {
                        towrite[offset] = c.color.b8.r;
                        towrite[offset + 1] = c.color.b8.g;
                        towrite[offset + 2] = c.color.b8.b;
                        towrite[offset + 3] = c.color.b8.a;
                        towrite[offset + 4 .. offset + 6] = nativeToBigEndian(c.frequency);
                        
                        offset += 6;
                    }
                } else if (chunk.sampleDepth == PngIHDRBitDepth.BitDepth16) {
                    size_t offset = towrite.length;
                    towrite = buffer[0 .. towrite.length + (chunk.colors.length * 10)];
                    
                    foreach(c; chunk.colors) {
                        towrite[offset .. offset + 2] = nativeToBigEndian(c.color.b16.r);
                        towrite[offset + 2 .. offset + 4] = nativeToBigEndian(c.color.b16.g);
                        towrite[offset + 4 .. offset + 6] = nativeToBigEndian(c.color.b16.b);
                        towrite[offset + 6 .. offset + 8] = nativeToBigEndian(c.color.b16.a);
                        towrite[offset + 8 .. offset + 10] = nativeToBigEndian(c.frequency);
                        
                        offset += 10;
                    }
                } else {
                    // TODO: ugh oh, this is not good!
                }
            }
            
            write(cast(char[4])"sPLT", towrite);
        }
        
        void writeChunk_hIST(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite = buffer[0 .. hIST.length * 2];
            
            size_t offset;
            foreach(v; hIST) {
                towrite[offset .. offset + 2] = nativeToBigEndian(v);
                
                offset += 2;
            }
            
            write(cast(char[4])"hIST", towrite);
        }
        
        void writeChunk_tIME(ubyte[] buffer, void delegate(char[4], ubyte[]) write) @trusted {
            ubyte[] towrite = buffer[0 .. 7];
            
            towrite[0 .. 2] = nativeToBigEndian(tIME.year);
            towrite[2] = tIME.month;
            towrite[3] = tIME.day;
            towrite[4] = tIME.hour;
            towrite[5] = tIME.minute;
            towrite[6] = tIME.second;
            
            write(cast(char[4])"tIME", towrite);
        }
        
        static if (!is(Color == HeadersOnly)) {
            void writeChunk_IDAT(ubyte[] buffer, void delegate(char[4], ubyte[]) theWriteFunc) @trusted {
                import std.zlib : compress;
                import std.math : ceil, floor;

                ubyte findPLTEColor(Color c1) {
                    RGB8 c = convertColor!RGB8(c1);
                    
                    foreach(i, c2; PLTE.colors) {
                        if (i >= 256)
                            break;
                        
                        if (c2 == c) {
                            return cast(ubyte)i;
                        }
                    }
                    
                    throw alloc.make!ImageNotExportableException("Palette not completed with all colors.");
                }

                // a simple check
                if (IHDR.interlaceMethod == PngIHDRInterlaceMethod.Adam7 || IHDR.interlaceMethod == PngIHDRInterlaceMethod.NoInterlace)
                {} else
                    throw allocator.make!ImageNotLoadableException("IDAT unknown interlace method");

                if (IHDR.compressionMethod == PngIHDRCompresion.DeflateInflate) {}
                else
                    throw allocator.make!ImageNotLoadableException("IDAT unknown compression method");

                // constants
                size_t pixelPreviousByteAmount, rowSize;
                ubyte sampleSize, pixelSampleSize, scanLineFilterMethodOffset;

                bool withAlpha = (IHDR.colorType & PngIHDRColorType.AlphaChannelUsed) == PngIHDRColorType.AlphaChannelUsed;
                bool isGrayScale = (IHDR.colorType & PngIHDRColorType.Grayscale) == PngIHDRColorType.Grayscale;
                bool isPalette = (IHDR.colorType & PngIHDRColorType.Palette) == PngIHDRColorType.Palette;
                bool isColor = (IHDR.colorType & PngIHDRColorType.ColorUsed) == PngIHDRColorType.ColorUsed;

                // some needed variables, in future processing
                ubyte[] decompressed, previousScanLine, tempFilterPrevious, tempFilterCurrent, tempScanLine, currentScanLine;
                ubyte pass, byteToOffset;
                size_t offsetX, offsetY;
                
                final switch(IHDR.colorType) {
                    case PngIHDRColorType.AlphaChannelUsed:
                        sampleSize = 2;
                        break;
                    case PngIHDRColorType.PalletteWithColorUsed:
                    case PngIHDRColorType.Palette:
                    case PngIHDRColorType.Grayscale:
                        sampleSize = 1;
                        break;
                    case PngIHDRColorType.ColorUsedWithAlpha:
                        sampleSize = 4;
                        break;
                    case PngIHDRColorType.ColorUsed:
                        sampleSize = 3;
                        break;
                }

                if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                    pixelSampleSize = cast(ubyte)(sampleSize + sampleSize);
                    pixelPreviousByteAmount = pixelSampleSize;
                } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                    pixelSampleSize = sampleSize;
                    pixelPreviousByteAmount = sampleSize;
                } else {
                    pixelSampleSize = sampleSize;
                    pixelPreviousByteAmount = 1;
                }

                rowSize = IHDR.width * pixelSampleSize;
                if (IHDR.filterMethod == PngIHDRFilter.Adaptive)
                    rowSize++;

                tempFilterPrevious = alloc.makeArray!ubyte(rowSize);
                tempFilterCurrent = alloc.makeArray!ubyte(rowSize);
                tempScanLine = alloc.makeArray!ubyte(rowSize);

                // filters the scan line
                previousScanLine = null;
                void filterScanLine(ubyte[] scanLine) {
                    // filter
                    tempFilterCurrent[0 .. scanLine.length] = scanLine[];

                    if (IHDR.filterMethod == PngIHDRFilter.Adaptive) {
                        if (scanLine.length <= 1) {
                            previousScanLine = tempFilterPrevious[0 .. 0];
                            return;
                        }
                        ubyte adaptiveOffset = scanLine[0];

                        foreach(i; 1 .. scanLine.length) {
                            switch(adaptiveOffset) {
                                case 1: // sub
                                    // Sub(x) - Raw(x-bpp)
                                    
                                    if (i-1 >= pixelPreviousByteAmount) {
                                        ubyte rawSub = tempFilterCurrent[i-pixelPreviousByteAmount];
                                        scanLine[i] = cast(ubyte)(scanLine[i] - rawSub);
                                    } else {
                                        // no changes needed
                                    }
                                    break;
                                    
                                case 2: // up
                                    // Up(x) - Prior(x)
                                    
                                    if (previousScanLine.length > i) {
                                        ubyte prior = previousScanLine[i];
                                        scanLine[i] = cast(ubyte)(scanLine[i] - prior);
                                    } else {
                                        // no changes needed
                                    }
                                    break;
                                    
                                case 3: // average
                                    // Average(x) - floor((Raw(x-bpp)+Prior(x))/2)
                                    
                                    if (previousScanLine.length > i) {
                                        if (i-1 >= pixelPreviousByteAmount) {
                                            ubyte prior = previousScanLine[i];
                                            ubyte rawSub = tempFilterCurrent[i-pixelPreviousByteAmount];
                                            scanLine[i] = cast(ubyte)(scanLine[i] - floor(cast(real)(rawSub + prior) / 2f));
                                        } else {
                                            ubyte prior = previousScanLine[i];
                                            ubyte rawSub = 0;
                                            scanLine[i] = cast(ubyte)(scanLine[i] - floor(cast(real)(rawSub + prior) / 2f));
                                        }
                                    } else if (i-1 >= pixelPreviousByteAmount) {
                                        ubyte prior = 0;
                                        ubyte rawSub = tempFilterCurrent[i-pixelPreviousByteAmount];
                                        scanLine[i] = cast(ubyte)(scanLine[i] - floor(cast(real)(rawSub + prior) / 2f));
                                    } else {
                                        // no changes needed
                                    }
                                    break;
                                    
                                case 4: // paeth
                                    //  Paeth(x) - PaethPredictor(Raw(x-bpp), Prior(x), Prior(x-bpp))
                                    
                                    if (previousScanLine.length > i) {
                                        if (i-1 >= pixelPreviousByteAmount) {
                                            ubyte prior = previousScanLine[i];
                                            ubyte rawSub = tempFilterCurrent[i-pixelPreviousByteAmount];
                                            ubyte priorRawSub = previousScanLine[i-pixelPreviousByteAmount];
                                            scanLine[i] = cast(ubyte)(scanLine[i] - PaethPredictor(rawSub, prior, priorRawSub));
                                        } else {
                                            ubyte prior = previousScanLine[i];
                                            ubyte rawSub = 0;
                                            ubyte priorRawSub = 0;
                                            scanLine[i] = cast(ubyte)(scanLine[i] - PaethPredictor(rawSub, prior, priorRawSub));
                                        }
                                    } else if (i-1 >= pixelPreviousByteAmount) {
                                        ubyte prior = 0;
                                        ubyte rawSub = tempFilterCurrent[i-pixelPreviousByteAmount];
                                        ubyte priorRawSub = 0;
                                        scanLine[i] = cast(ubyte)(scanLine[i] - PaethPredictor(rawSub, prior, priorRawSub));
                                    } else {
                                        // no changes needed
                                    }
                                    break;
                                    
                                default:
                                case 0: // none
                                    break;
                            }
                        }
                    }

                    alloc.expandArray(decompressed, scanLine.length-scanLineFilterMethodOffset);
                    decompressed[$-(scanLine.length - scanLineFilterMethodOffset) .. $] = scanLine[scanLineFilterMethodOffset .. $];

                    previousScanLine = tempFilterPrevious[0 .. scanLine.length];
                    previousScanLine[] = tempFilterCurrent[0 .. scanLine.length][];
                }
                
                const ubyte bitByteCount = cast(ubyte)(8 / IHDR.bitDepth);

                void storeChannel(ubyte v) {
                    if (byteToOffset == bitByteCount)
                        byteToOffset = 0;
                    if (byteToOffset == 0)
                        currentScanLine = tempScanLine[0 .. currentScanLine.length + 1];

                    if (byteToOffset > 0) {
                        v = cast(ubyte)(v << ((8-IHDR.bitDepth)-(IHDR.bitDepth * byteToOffset)));
                        currentScanLine[$-1] |= v;
                    } else
                        currentScanLine[$-1] = cast(ubyte)(v << (8-IHDR.bitDepth));
                    
                    byteToOffset++;
                }
                
                void serializeScanLine(Color c) {
                    // serailize the color as apropriete form into the scanLineBuffer

                    if (isPalette) {
                        if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8 || IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                            currentScanLine = tempScanLine[0 .. currentScanLine.length + 1];
                            currentScanLine[$-1] = findPLTEColor(c);
                        } else {
                           storeChannel(findPLTEColor(c));
                        }
                    } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8 || IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                        currentScanLine = tempScanLine[0 .. currentScanLine.length + pixelSampleSize];

                        if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth16) {
                            RGBA16 pixToUse = convertColor!RGBA16(c);
                            
                            if (isColor) {
                                if (withAlpha) {
                                    currentScanLine[$-8 .. $-6] = nativeToBigEndian(pixToUse.r);
                                    currentScanLine[$-6 .. $-4] = nativeToBigEndian(pixToUse.g);
                                    currentScanLine[$-4 .. $-2] = nativeToBigEndian(pixToUse.b);
                                    currentScanLine[$-2 .. $] = nativeToBigEndian(pixToUse.a);
                                } else {
                                    currentScanLine[$-6 .. $-4] = nativeToBigEndian(pixToUse.r);
                                    currentScanLine[$-4 .. $-2] = nativeToBigEndian(pixToUse.g);
                                    currentScanLine[$-2 .. $] = nativeToBigEndian(pixToUse.b);
                                }
                            } else if (isGrayScale) {
                                float pixG = (pixToUse.r / 3f) + (pixToUse.g / 3f) + (pixToUse.b / 3f);
                                
                                if (withAlpha) {
                                    currentScanLine[$-4 .. $-2] = nativeToBigEndian(cast(ushort)pixG);
                                    currentScanLine[$-2 .. $] = nativeToBigEndian(pixToUse.a);
                                } else {
                                    currentScanLine[$-2 .. $] = nativeToBigEndian(cast(ushort)pixG);
                                }
                            }
                        } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth8) {
                            RGBA8 pixToUse = convertColor!RGBA8(c);
                            
                            if (isColor) {
                                if (withAlpha) {
                                    currentScanLine[$-4 .. $-3] = pixToUse.r;
                                    currentScanLine[$-3 .. $-2] = pixToUse.g;
                                    currentScanLine[$-2 .. $-1] = pixToUse.b;
                                    currentScanLine[$-1 .. $] = pixToUse.a;
                                } else {
                                    currentScanLine[$-3 .. $-2] = pixToUse.r;
                                    currentScanLine[$-2 .. $-1] = pixToUse.g;
                                    currentScanLine[$-1 .. $] = pixToUse.b;
                                }
                            } else if (isGrayScale) {
                                float pixG = (pixToUse.r / 3f) + (pixToUse.g / 3f) + (pixToUse.b / 3f);
                                
                                if (withAlpha) {
                                    currentScanLine[$-2 .. $-1] = cast(ubyte)pixG;
                                    currentScanLine[$-1 .. $] = pixToUse.a;
                                } else {
                                    currentScanLine[$-1 .. $] = cast(ubyte)pixG;
                                }
                            }
                        }
                    } else {
                        // 1, 2, 4 bit depths
                        ubyte bitMaxValue;
                        ubyte samplesPerPixel;

                        if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth4) {
                            bitMaxValue = 15;
                        } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth2) {
                            bitMaxValue = 3;
                        } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth1) {
                            bitMaxValue = 1;
                        }
                        
                        if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth4) {
                            samplesPerPixel = 2;
                        } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth2) {
                            samplesPerPixel = 4;
                        } else if (IHDR.bitDepth == PngIHDRBitDepth.BitDepth1) {
                            samplesPerPixel = 8;
                        } else
                            samplesPerPixel = 1;
                        
                        RGBA8 pixToUse = convertColor!RGBA8(c);
                        ubyte[4] bitDepthValues = [
                            cast(ubyte)ceil((pixToUse.r / 256f) * bitMaxValue),
                            cast(ubyte)ceil((pixToUse.g / 256f) * bitMaxValue),
                            cast(ubyte)ceil((pixToUse.b / 256f) * bitMaxValue),
                            cast(ubyte)ceil((pixToUse.a / 256f) * bitMaxValue)
                        ];
                        
                        if (isColor) {
                            storeChannel(bitDepthValues[0]);
                            storeChannel(bitDepthValues[1]);
                            storeChannel(bitDepthValues[2]);
                            
                            if (withAlpha)
                                storeChannel(bitDepthValues[3]);
                        } else if (isGrayScale) {
                            storeChannel(bitDepthValues[0]);
                            
                            if (withAlpha)
                                storeChannel(bitDepthValues[3]);
                        }
                    }
                }

                void startScanLine() {
                    if (IHDR.filterMethod == PngIHDRFilter.Adaptive) {
                        const ubyte[] filtersToApply = [cast(ubyte)0, 1];
                        currentScanLine = tempScanLine[0 .. 1];
                        
                        //if (isPalette)
                            currentScanLine[0] = 0;
                        //else
                        //    currentScanLine[0] = filtersToApply[offsetY % filtersToApply.length];
                        
                        scanLineFilterMethodOffset = 0;
                        if (IHDR.interlaceMethod == PngIHDRInterlaceMethod.Adam7) {
                            if (offsetX > 0) {
                                //scanLineFilterMethodOffset = 1;
                            }
                        }
                    } else
                        currentScanLine = tempScanLine[0 .. 0];
                    byteToOffset = 0; // 1, 2, 4 bit depth
                }
                
                bool[size_t][size_t] doneSets;

                if (IHDR.interlaceMethod == PngIHDRInterlaceMethod.Adam7) {
                    pass = 0;
                    while(pass < 7) {
                        offsetY = starting_row[pass];

                        while(offsetY < IHDR.height) {
                            offsetX = starting_col[pass];
                            startScanLine();

                            while(offsetX < IHDR.width) {
                                assert(doneSets.get(offsetY, null).get(offsetX, true));
                                doneSets[offsetY][offsetX] = true;
                                serializeScanLine(value[offsetX, offsetY]);
                                offsetX += col_increment[pass];
                            }

                            filterScanLine(currentScanLine);
                            offsetY += row_increment[pass];
                        }
                        
                        pass++;
                    }
                } else if (IHDR.interlaceMethod == PngIHDRInterlaceMethod.NoInterlace) {
                    foreach(y; 0 .. IHDR.height) {
                        offsetY = y;
                        offsetX = 0;
                        startScanLine();

                        foreach(x; 0 .. IHDR.width) {
                            offsetX = x;
                            
                            assert(doneSets.get(offsetY, null).get(offsetX, true));
                                doneSets[offsetY][offsetX] = true;
                            serializeScanLine(value[offsetX, offsetY]);
                        }
                        
                        filterScanLine(currentScanLine);
                    }
                }

                foreach(x; 0 .. IHDR.width) {
                    foreach(y; 0 .. IHDR.height) {
                        assert(doneSets.get(y, null).get(x, false));
                    }
                }
                
                ubyte[] compressed;

                // compress
                if (IHDR.compressionMethod == PngIHDRCompresion.DeflateInflate) {
                    compressed = cast(ubyte[])compress(decompressed);
                } else {
                    throw allocator.make!ImageNotLoadableException("IDAT unknown compression method");
                }

                ubyte[] bfr2 = buffer[0 .. compressed.length];
                bfr2[] = compressed[];

                theWriteFunc(cast(char[4])"IDAT", bfr2);
                
                alloc.dispose(tempFilterPrevious);
                alloc.dispose(tempFilterCurrent);
                alloc.dispose(decompressed);
            }
        }
        
        /*
         * Misc functions
         */
        
        void performCompatConfigure() {
            static if (!is(Color == HeadersOnly)) {
                IHDR.width = cast(uint)value.width;
                IHDR.height = cast(uint)value.height;
                
                // TODO: better color space guessing
                
                IHDR.bitDepth = PngIHDRBitDepth.BitDepth8;
                IHDR.colorType = PngIHDRColorType.ColorUsed;
                IHDR.compressionMethod = PngIHDRCompresion.DeflateInflate;
                IHDR.filterMethod = PngIHDRFilter.Adaptive;
            }
        }
    }
}

/**
 * Loads a PNG file headers
 *
 * Can be used to determine which color type to use at runtime.
 *
 * Returns:
 *      A PNG files headers without the image data
 */
managed!(PNGFileFormat!HeadersOnly) loadPNGHeaders(IR)(IR input, IAllocator allocator = theAllocator()) @trusted if (isInputRange!IR && is(ElementType!IR == ubyte)) {
	managed!(PNGFileFormat!HeadersOnly) ret = managed!(PNGFileFormat!HeadersOnly)(managers(), tuple(allocator), allocator);
	ret.performInput(input);
    
    return ret;
}

/**
 * Loads a PNG file using specific color type
 *
 * Params:
 *      input       =   Input range that returns the files bytes
 *      allocator   =   The allocator to use the allocate the image
 *
 * Returns:
 *      A PNG file, loaded as an image along with its headers. Using specified image storage type.
 */
managed!(PNGFileFormat!Color) loadPNG(Color, ImageImpl=ImageStorageHorizontal!Color, IR)(IR input, IAllocator allocator = theAllocator()) @trusted if (isInputRange!IR && is(ElementType!IR == ubyte) && isImage!ImageImpl) {
	managed!(PNGFileFormat!Color) ret = managed!(PNGFileFormat!Color)(managers(), tuple(allocator), allocator);

    ret.theImageAllocator = &ret.allocateTheImage!ImageImpl;
    ret.performInput(input);
    
    return ret;
}

///
unittest {
    import std.experimental.graphic.color;
    
    import std.file : read;
    auto input = cast(ubyte[])read("testAssets/test.png");
    
    PNGFileFormat!RGB8 image = loadPNG!RGB8(input);
}

/**
 * Constructs a compatible version of an image as PNG
 * 
 * Params:
 *      form    =   The image to construct from
 *
 * Returns:
 *      A compatible PNG image
 */
managed!(PNGFileFormat!Color) asPNG(From, Color = ImageColor!From, ImageImpl=ImageStorageHorizontal!Color)(From from, IAllocator allocator = theAllocator()) @safe if (isImage!From) {
    import std.experimental.graphic.image.primitives : copyTo;
    
    managed!(PNGFileFormat!Color) ret = managed!(PNGFileFormat!Color)(managers(), tuple(allocator), allocator);
    ret.allocateTheImage!ImageImpl(from.width, from.height);
    
    from.copyTo(ret.value);
    ret.performCompatConfigure();
    
    return ret;
}

///
unittest {
    import std.experimental.graphic.color;
    
    import std.file : read;
    auto input = cast(ubyte[])read("testAssets/test.png");
    
    ImageStorageHorizontal!RGB8 image = ImageStorageHorizontal!RGB8(2, 2);
    PNGFileFormat!RGB8 image2 = asPNG(&image);
    
    // modify some fields
    
    ubyte[] or = image2.toBytes();
}

///
enum PngTextKeywords : string {
    ///
    Title = "Title",
    ///
    Author = "Author",
    ///
    Description = "Description",
    ///
    Copyright = "Copyright",
    ///
    CreationTime = "Creation Time",
    ///
    Software = "Software",
    ///
    Disclaimer = "Disclaimer",
    ///
    Warning = "Warning",
    ///
    Source = "Source",
    ///
    Comment = "Comment"
}

///
enum PngIHDRColorType : ubyte {
    ///
    Grayscale = 0,                                          // valid (0)
    Palette = 1 << 0,                                       // not valid
    ///
    ColorUsed = 1 << 1,                                     // valid (2) rgb
    ///
    AlphaChannelUsed = 1 << 2,                              // valid (4) a
    ///
    PalletteWithColorUsed = Palette | ColorUsed,            // valid (1, 2) index + alpha
    ///
    ColorUsedWithAlpha = ColorUsed | AlphaChannelUsed,       // valid (2, 4) rgba
    ///
    GrayscaleWithAlpha = Grayscale | AlphaChannelUsed
}

///
enum PngIHDRBitDepth : ubyte {
    // valid with color type:
    ///    
    BitDepth1 = 1,                                          // 0, 3
    ///
    BitDepth2 = 2,                                          // 0, 3
    ///
    BitDepth4 = 4,                                          // 0, 3
    ///
    BitDepth8 = 8,                                          // 0, 2, 3, 4, 8
    ///
    BitDepth16 = 16                                         // 0, 2, 4, 8
}

///
enum PngIHDRCompresion : ubyte {
    ///
    DeflateInflate = 0
}

///
enum PngIHDRFilter : ubyte {
    ///
    Adaptive = 0
}

///
enum PngIHDRInterlaceMethod : ubyte {
    ///
    NoInterlace =  0,
    ///
    Adam7 = 1
}

///
enum PngRenderingIntent : ubyte {
    ///
    Perceptual = 0,
    ///
    RelativeColorimetric = 1,
    ///
    Saturation = 2,
    ///
    AbsoluteColorimetric = 3,
    ///
    Unknown=255
}

///
enum PngPhysicalPixelUnit : ubyte {
    ///
    Unknown = 0,
    ///
    Meter = 1
}

///
struct IHDR_Chunk {
    ///
    uint width;
    ///
    uint height;
    ///
    PngIHDRBitDepth bitDepth;
    ///
    PngIHDRColorType colorType;
    ///
    PngIHDRCompresion compressionMethod;
    ///
    PngIHDRFilter filterMethod;
    ///
    PngIHDRInterlaceMethod interlaceMethod;
}

///
struct PLTE_Chunk {
    ///
    alias Color = RGB8;
    
    ///
    Color[] colors;
}

///
struct cHRM_Chunk {    
    ///
    uint white_x;
    ///
    uint white_y;
    
    ///
    uint red_x;
    ///
    uint red_y;
    
    ///
    uint green_x;
    ///
    uint green_y;
    
    ///
    uint blue_x;
    ///
    uint blue_y;
}

///
struct sRGB_Chunk {
    ///
    PngRenderingIntent intent;
}

///
struct iCCP_Chunk {
    ///
    string profileName;
    
    ///
    PngIHDRCompresion compressionMethod;
    
    ///
    ubyte[] profile;
}

///
struct gAMA_Chunk {   
    /// 
    uint value;
    
    ///
    @property void set(float value) {
        this.value = cast(uint)(value * 100000);
    }
    
    ///
    @property float get() {
        return value / 100000f;
    }
}

///
union tRNS_Chunk {
    ///
    ubyte[] indexAlphas;
    ///
    RGB8 b8;
    ///
    RGB16 b16;
}

///
union bKGD_Chunk {
    ///
    ubyte index;
    ///
    RGB8 b8;
    ///
    RGB16 b16;
}

///
struct pPHs_Chunk {
    ///
    uint ppx;
    
    ///
    uint ppy;
    
    ///
    PngPhysicalPixelUnit unit;
}

///
union sBIT_Chunk {
    ///
    ubyte grayScale;
    ///
    ubyte[3] trueColor;
    ///
    ubyte[3] indexed;
    ///
    ubyte[2] grayScaleAlpha;
    ///
    ubyte[4] trueColorAlpha;
}

///
struct sPLT_Chunk {
    ///
    string paletteName;
    
    ///
    PngIHDRBitDepth sampleDepth;
    
    ///
    struct Entry {
        ///
        union Color {
            ///
            RGBA8 b8;
            ///
            RGBA16 b16;
        }
        
        ///
        Color color;
        
        ///
        ushort frequency;
    }
    
    ///
    Entry[] colors;
}

/// Grumbles @ManuEvans...
alias RGBA16 = RGB!("rgba", ushort);
/// Grumbles @ManuEvans...
alias RGB16 = RGB!("rgb", ushort);

private {
    struct IDAT_Chunk(Color) {
        ubyte[] data;
    }
    
    enum {
        starting_row = [
            0, 0, 4, 0, 2, 0, 1
        ],
        
        starting_col  = [
            0, 4, 0, 2, 0, 1, 0
        ],
        
        row_increment = [
            8, 8, 8, 4, 4, 2, 2
        ],
        
        col_increment = [
            8, 8, 4, 4, 2, 2, 1
        ],
        
        block_height = [
            8, 8, 4, 4, 2, 2, 1
        ],
        
        block_width = [
            8, 4, 4, 2, 2, 1, 1
        ]
    }
    
    ubyte PaethPredictor(ubyte a, ubyte b, ubyte c) {
        import std.math : abs;
        
        // a = left, b = above, c = upper left
        int p = a + b - c;        // initial estimate
        int pa = abs(p - a);      // distances to a, b, c
        int pb = abs(p - b);
        int pc = abs(p - c);
        
        // return nearest of a,b,c,
        // breaking ties in order a,b,c.
        if (pa <= pb && pa <= pc) return a;
        else if (pb <= pc) return b;
        else return c;
    }
}
