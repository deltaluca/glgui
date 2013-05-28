package glgui;

import ogl.GLM;
import gl3font.Font;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;
import cpp.vm.Tls;

/**
 * Rounded rectangular panel GUI element.
 */
class Panel implements Element<Panel> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    @:builder var occluder = true;

    // Panel
    /** Panel corner radius */
    @:builder var radius:Float = 0.0;
    /** Panel colour **/
    @:builder var colour:Vec4 = [1.0,1.0,1.0,1.0];

    // Abuse GL3Font for this.
    @:lazyVar static var font:Tls<Font> = new Tls<Font>();
    var buffer:StringBuffer;
    public function new() {
        if (font.value == null) font.value = new Font(null, "quarter_circle.distance.png");
        buffer = new StringBuffer(font.value, 9, true);
    }

    // Element
    public function destroy() {
        buffer.destroy();
    }

    // Element
    public function bounds():Maybe<Vec4> return getFit();
    // Element
    public function internal(x:Vec2) {
        var fit = getFit();
        var r = getRadius();
        var x0 = fit.x;
        var y0 = fit.y;
        var x1 = x0 + fit.z;
        var y1 = y0 + fit.w;

        // top/left/right/bottom/middle
        if ((x.x >= x0+r && x.x <= x1-r && x.y >= y0 && x.y <= y1)
         || (x.y >= y0+r && x.y <= y1-r && x.x >= x0 && x.x <= x1))
            return true;

        // top-left
        var dx = x.x - (x0+r);
        var dy = x.y - (y0+r);
        if (dx*dx + dy*dy <= r*r) return true;
        // top-right
        var dx2 = x.x - (x1-r);
        if (dx2*dx2 + dy*dy <= r*r) return true;
        // bottom-left
        dy = x.y - (y1-r);
        if (dx*dx + dy*dy <= r*r) return true;
        // bottom-right
        if (dx2*dx2 + dy*dy <= r*r) return true;

        // external
        return false;
    }

    // Element
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

        var col = getColour();

        // top-left
        buffer.vertex(index+=d, x0,  y0,   t,t, col);
        buffer.vertex(index+=d, x0+r,y0,   1,t, col);
        buffer.vertex(index+=d, x0+r,y0+r, 1,1, col);
        buffer.vertex(index+=d, x0,  y0,   t,t, col);
        buffer.vertex(index+=d, x0+r,y0+r, 1,1, col);
        buffer.vertex(index+=d, x0  ,y0+r, t,1, col);

        // top-right
        buffer.vertex(index+=d, x1-r,y0,   1,t, col);
        buffer.vertex(index+=d, x1,  y0,   t,t, col);
        buffer.vertex(index+=d, x1,  y0+r, t,1, col);
        buffer.vertex(index+=d, x1-r,y0,   1,t, col);
        buffer.vertex(index+=d, x1,  y0+r, t,1, col);
        buffer.vertex(index+=d, x1-r,y0+r, 1,1, col);

        // bottom-left
        buffer.vertex(index+=d, x0,  y1-r, t,1, col);
        buffer.vertex(index+=d, x0+r,y1-r, 1,1, col);
        buffer.vertex(index+=d, x0+r,y1,   1,t, col);
        buffer.vertex(index+=d, x0,  y1-r, t,1, col);
        buffer.vertex(index+=d, x0+r,y1,   1,t, col);
        buffer.vertex(index+=d, x0  ,y1,   t,t, col);

        // bottom-right
        buffer.vertex(index+=d, x1-r,y1-r, 1,1, col);
        buffer.vertex(index+=d, x1,  y1-r, t,1, col);
        buffer.vertex(index+=d, x1,  y1,   t,t, col);
        buffer.vertex(index+=d, x1-r,y1-r, 1,1, col);
        buffer.vertex(index+=d, x1,  y1,   t,t, col);
        buffer.vertex(index+=d, x1-r,y1,   1,t, col);

        // top
        buffer.vertex(index+=d, x0+r,y0,   1,t, col);
        buffer.vertex(index+=d, x1-r,y0,   1,t, col);
        buffer.vertex(index+=d, x1-r,y0+r, 1,1, col);
        buffer.vertex(index+=d, x0+r,y0,   1,t, col);
        buffer.vertex(index+=d, x1-r,y0+r, 1,1, col);
        buffer.vertex(index+=d, x0+r,y0+r, 1,1, col);

        // bottom
        buffer.vertex(index+=d, x0+r,y1-r, 1,1, col);
        buffer.vertex(index+=d, x1-r,y1-r, 1,1, col);
        buffer.vertex(index+=d, x1-r,y1,   1,t, col);
        buffer.vertex(index+=d, x0+r,y1-r, 1,1, col);
        buffer.vertex(index+=d, x1-r,y1,   1,t, col);
        buffer.vertex(index+=d, x0+r,y1,   1,t, col);

        // left
        buffer.vertex(index+=d, x0,  y0+r, t,1, col);
        buffer.vertex(index+=d, x0+r,y0+r, 1,1, col);
        buffer.vertex(index+=d, x0+r,y1-r, 1,1, col);
        buffer.vertex(index+=d, x0,  y0+r, t,1, col);
        buffer.vertex(index+=d, x0+r,y1-r, 1,1, col);
        buffer.vertex(index+=d, x0,  y1-r, t,1, col);

        // right
        buffer.vertex(index+=d, x1-r,y0+r, 1,1, col);
        buffer.vertex(index+=d, x1,  y0+r, t,1, col);
        buffer.vertex(index+=d, x1,  y1-r, t,1, col);
        buffer.vertex(index+=d, x1-r,y0+r, 1,1, col);
        buffer.vertex(index+=d, x1,  y1-r, t,1, col);
        buffer.vertex(index+=d, x1-r,y1-r, 1,1, col);

        // middle
        buffer.vertex(index+=d, x0+r,y0+r, 1,1, col);
        buffer.vertex(index+=d, x1-r,y0+r, 1,1, col);
        buffer.vertex(index+=d, x1-r,y1-r, 1,1, col);
        buffer.vertex(index+=d, x0+r,y0+r, 1,1, col);
        buffer.vertex(index+=d, x1-r,y1-r, 1,1, col);
        buffer.vertex(index+=d, x0+r,y1-r, 1,1, col);

        return this;
    }

    // Element
    public function render(gui:Gui, _, proj:Mat3x2, xform:Mat3x2) {
        gui.textRenderer()
            .setTransform(proj * xform)
            .render(buffer);
    }
}
