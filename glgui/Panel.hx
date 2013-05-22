package glgui;

import ogl.GLM;
import gl3font.Font;
import glgui.Macros;

class Panel implements Element<Panel> {

    // Element
    @:builder var visible = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    public var transform:Mat3x2;

    // Panel
    @:builder var radius:Float = 0.0;
    @:builder var colour:Vec4 = [1.0,1.0,1.0,1.0];

    // Abuse GL3Font for this.
    public static var font:Font;
    var buffer:StringBuffer;
    public function new() {
        if (font == null) font = new Font(null, "quarter_circle.distance.png");
        buffer = new StringBuffer(font, 9, true);
        transform = Mat3x2.identity();
    }

    public function destroy() {
        buffer.destroy();
    }

    public function commit() {
        var fit = getFit();

        buffer.clear();
        var d = StringBuffer.VERTEX_SIZE;
        var index = buffer.reserve(6*9) - d;

        var t = 60/814; // normalised gap left in corner piece image to avoid leaking edges.
        var r = getRadius();
        var x0 = fit.x;
        var y0 = fit.y;
        var x1 = x0 + fit.z;
        var y1 = y0 + fit.w;

        // top-left
        buffer.vertex(index+=d, x0,  y0,   t,t);
        buffer.vertex(index+=d, x0+r,y0,   1,t);
        buffer.vertex(index+=d, x0+r,y0+r, 1,1);
        buffer.vertex(index+=d, x0,  y0,   t,t);
        buffer.vertex(index+=d, x0+r,y0+r, 1,1);
        buffer.vertex(index+=d, x0  ,y0+r, t,1);

        // top-right
        buffer.vertex(index+=d, x1-r,y0,   1,t);
        buffer.vertex(index+=d, x1,  y0,   t,t);
        buffer.vertex(index+=d, x1,  y0+r, t,1);
        buffer.vertex(index+=d, x1-r,y0,   1,t);
        buffer.vertex(index+=d, x1,  y0+r, t,1);
        buffer.vertex(index+=d, x1-r,y0+r, 1,1);

        // bottom-left
        buffer.vertex(index+=d, x0,  y1-r, t,1);
        buffer.vertex(index+=d, x0+r,y1-r, 1,1);
        buffer.vertex(index+=d, x0+r,y1,   1,t);
        buffer.vertex(index+=d, x0,  y1-r, t,1);
        buffer.vertex(index+=d, x0+r,y1,   1,t);
        buffer.vertex(index+=d, x0  ,y1,   t,t);

        // bottom-right
        buffer.vertex(index+=d, x1-r,y1-r, 1,1);
        buffer.vertex(index+=d, x1,  y1-r, t,1);
        buffer.vertex(index+=d, x1,  y1,   t,t);
        buffer.vertex(index+=d, x1-r,y1-r, 1,1);
        buffer.vertex(index+=d, x1,  y1,   t,t);
        buffer.vertex(index+=d, x1-r,y1,   1,t);

        // top
        buffer.vertex(index+=d, x0+r,y0,   1,t);
        buffer.vertex(index+=d, x1-r,y0,   1,t);
        buffer.vertex(index+=d, x1-r,y0+r, 1,1);
        buffer.vertex(index+=d, x0+r,y0,   1,t);
        buffer.vertex(index+=d, x1-r,y0+r, 1,1);
        buffer.vertex(index+=d, x0+r,y0+r, 1,1);

        // bottom
        buffer.vertex(index+=d, x0+r,y1-r, 1,1);
        buffer.vertex(index+=d, x1-r,y1-r, 1,1);
        buffer.vertex(index+=d, x1-r,y1,   1,t);
        buffer.vertex(index+=d, x0+r,y1-r, 1,1);
        buffer.vertex(index+=d, x1-r,y1,   1,t);
        buffer.vertex(index+=d, x0+r,y1,   1,t);

        // left
        buffer.vertex(index+=d, x0,  y0+r, t,1);
        buffer.vertex(index+=d, x0+r,y0+r, 1,1);
        buffer.vertex(index+=d, x0+r,y1-r, 1,1);
        buffer.vertex(index+=d, x0,  y0+r, t,1);
        buffer.vertex(index+=d, x0+r,y1-r, 1,1);
        buffer.vertex(index+=d, x0,  y1-r, t,1);

        // right
        buffer.vertex(index+=d, x1-r,y0+r, 1,1);
        buffer.vertex(index+=d, x1,  y0+r, t,1);
        buffer.vertex(index+=d, x1,  y1-r, t,1);
        buffer.vertex(index+=d, x1-r,y0+r, 1,1);
        buffer.vertex(index+=d, x1,  y1-r, t,1);
        buffer.vertex(index+=d, x1-r,y1-r, 1,1);

        // middle
        buffer.vertex(index+=d, x0+r,y0+r, 1,1);
        buffer.vertex(index+=d, x1-r,y0+r, 1,1);
        buffer.vertex(index+=d, x1-r,y1-r, 1,1);
        buffer.vertex(index+=d, x0+r,y0+r, 1,1);
        buffer.vertex(index+=d, x1-r,y1-r, 1,1);
        buffer.vertex(index+=d, x0+r,y1-r, 1,1);

        return this;
    }

    public function render(gui:Gui, xform:Mat3x2) {
        if (!getVisible()) return;
        gui.textRenderer()
            .setColour(getColour())
            .setTransform(xform)
            .render(buffer);
    }
}
