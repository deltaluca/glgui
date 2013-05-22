package glgui;

import ogl.GLM;
import gl3font.Font;
import glgui.Macros;

class Text implements Element<Text> {

    // Element
    @:builder var visible = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    public var transform:Mat3x2;

    // Text
    @:builder var colour:Vec4 = [1.0,1.0,1.0,1.0];
    @:builder var font:Font = null;
    @:builder var halign = AlignCentre;
    @:builder var valign = AlignCentre;
    @:builder var justified = false;
    @:builder var size = 0.0;
    @:builder var text:String;

    var buffer:StringBuffer;
    public function new(text:String="", staticDraw:Bool=false) {
        this.text(text);
        buffer = new StringBuffer(null, text.length, staticDraw);
        transform = Mat3x2.identity();
    }

    public function destroy() {
        buffer.destroy();
    }

    public function commit() {
        if (getText().length == 0) return this;

        // Compute text bounds, set vertex buffers.
        buffer.font = getFont();
        var bounds = buffer.set(getText(),
            if (!getJustified()) getHalign() else switch (getHalign()) {
                case AlignLeft:  AlignLeftJustified;
                case AlignRight: AlignRightJustified;
                default:         AlignCentreJustified;
            });

        // Determine text scaling.
        var scale = if (getSize() > 0.0) getSize()
            else Math.min(getFit().z / bounds.z, getFit().w / bounds.w);

        // And final (local) transform.
        transform[0] = transform[3] = scale;
        transform[1] = transform[2] = 0.0;
        transform[4] = (getFit().x - scale*bounds.x)
            +  (switch (getHalign()) {
                case AlignLeft:  0.0;
                case AlignRight: 1.0;
                default:         0.5;
            })*(getFit().z - scale*bounds.z);
        transform[5] = (getFit().y - scale*bounds.y)
            +  (switch (getValign()) {
                case AlignLeft:  0.0;
                case AlignRight: 1.0;
                default:         0.5;
            })*(getFit().w - scale*bounds.w);
        return this;
    }

    public function render(gui:Gui, xform:Mat3x2) {
        if (!getVisible()) return;
        gui.textRenderer()
            .setColour(getColour())
            .setTransform(xform * transform)
            .render(buffer);
    }
}
