package glgui;

import ogl.GLM;
import gl3font.Font;
import glgui.Macros;

enum TextAlign {
    TextAlignLeft;
    TextAlignTop;
    TextAlignRight;
    TextAlignBottom;
    TextAlignCentre;
}

/**
 * Text rendering GUI element.
 */
class Text implements Element<Text> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    @:builder var occluder = false;

    // Text
    /** Text colour */
    @:builder var colour:Vec4 = [1.0,1.0,1.0,1.0];
    /** Text GL3 Font */
    @:builder var font:Font = null;
    /** Text horizontal align */
    @:builder var halign = TextAlignCentre;
    /** Text vertical align */
    @:builder var valign = TextAlignCentre;
    /** Justified rendering for multiline text **/
    @:builder var justified = false;
    /** Font pixel size (<=0 -> fixed aspect scaling to fill 'fit') */
    @:builder var size = 0.0;
    /** Text... text */
    @:builder var text:String;

    var transform:Mat3x2;
    var buffer:StringBuffer;
    /**
     * Optional: Instantiate text with some string.
     *           Result will be a 'static' text element whose
     *           text should not be changed anymore.
     */
    public function new(text:String="") {
        this.text(text);
        buffer = new StringBuffer(null, text.length, text.length != 0);
        transform = Mat3x2.identity();
    }

    // Element
    public function destroy() {
        buffer.destroy();
    }

    // Element
    public function internal(x:Vec2):Bool {
        var y = transform.inverse() * x;
        y.x -= textBounds.x;
        y.y -= textBounds.y;
        return y.x >= 0 && y.x <= textBounds.z &&
               y.y >= 0 && y.y <= textBounds.w;
    }

    // Element
    var textBounds:Vec4;
    public function bounds():Null<Vec4> return textBounds;

    // Element
    public function commit() {
        if (getText().length == 0) return this;

        // Compute text textBounds, set vertex buffers.
        buffer.font = getFont();
        textBounds = buffer.set(getText(),
            switch (getHalign()) {
                case TextAlignLeft:  getJustified() ? AlignLeftJustified   : AlignLeft;
                case TextAlignRight: getJustified() ? AlignRightJustified  : AlignRight;
                default:             getJustified() ? AlignCentreJustified : AlignCentre;
            });

        // Determine text scaling.
        var scale = if (getSize() > 0.0) getSize()
            else Math.min(getFit().z / textBounds.z, getFit().w / textBounds.w);

        // And final (local) transform.
        transform[0] = transform[3] = scale;
        transform[1] = transform[2] = 0.0;
        transform[4] = (getFit().x - scale*textBounds.x)
            +  (switch (getHalign()) {
                case TextAlignLeft:  0.0;
                case TextAlignRight: 1.0;
                default:             0.5;
            })*(getFit().z - scale*textBounds.z);
        transform[5] = (getFit().y - scale*textBounds.y)
            +  (switch (getValign()) {
                case TextAlignTop:    0.0;
                case TextAlignBottom: 1.0;
                default:              0.5;
            })*(getFit().w - scale*textBounds.w);
        return this;
    }

    // Element
    public function render(gui:Gui, _, xform:Mat3x2) {
        gui.textRenderer()
            .setColour(getColour())
            .setTransform(xform * transform)
            .render(buffer);
    }
}
