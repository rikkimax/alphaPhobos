module std.experimental.ui.window.context.vram;
import std.experimental.ui.window.defs;
import std.experimental.graphic.image : ImageStorage;
import std.experimental.graphic.color : RGB8, RGBA8;

interface Have_VRamCtx {
    void assignVRamContext(bool withAlpha=false);
}

void assignVRamContext(T)(T self, bool withAlpha=false) if (is(T : IWindowCreator)) {
    if (self is null)
        return;
    if (Have_VRamCtx ss = cast(Have_VRamCtx)self) {
        ss.assignVRamContext(withAlpha);
    }
}

interface Have_VRam {
    Feature_VRam __getFeatureVRam();
}

interface Feature_VRam {
    @property {
        ImageStorage!RGB8 vramBuffer();
        ImageStorage!RGBA8 vramAlphaBuffer();
    }
}

@property {
    ImageStorage!RGB8 vramBuffer(T)(T self) if (is(T : IContext)) {
        if (self is null)
            return null;
        if (Have_VRam ss = cast(Have_VRam)self) {
            return ss.__getFeatureVRam().vramBuffer;
        }
        
        return null;
    }

    ImageStorage!RGB8 vramAlphaBuffer(T)(T self) if (is(T : IContext)) {
        if (self is null)
            return null;
        if (Have_VRam ss = cast(Have_VRam)self) {
            return ss.__getFeatureVRam().vramAlphaBuffer;
        }
        
        return null;
    }
}