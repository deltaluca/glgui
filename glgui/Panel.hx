package glgui;

import ogl.GLM;
import gl3font.Font;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;
import #if cpp cpp #else neko #end.vm.Tls;

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
    public inline function vert(data:Array<Float>, x:Float, y:Float, u:Float, v:Float, cr:Float, cg:Float, cb:Float, ca:Float) {
        data.push(x); data.push(y);
        data.push(u); data.push(v);
        data.push(cr);
        data.push(cg);
        data.push(cb);
        data.push(ca);
    }
    public function commit() {
        var fit = getFit();

        buffer.clear();
        var d = StringBuffer.VERTEX_SIZE;
        var index = buffer.reserve(6*9);

        var t = 60/814; // normalised gap left in corner piece image to avoid leaking edges.
        var r = getRadius();
        var x0 = fit.x;
        var y0 = fit.y;
        var x1 = x0 + fit.z;
        var y1 = y0 + fit.w;

        var col = getColour();
        var cr = col.r;
        var cg = col.g;
        var cb = col.b;
        var ca = col.a;

        // top-left
        var data = [];
        vert(data, x0,  y0,   t,t, cr,cg,cb,ca);
        vert(data, x0+r,y0,   1,t, cr,cg,cb,ca);
        vert(data, x0+r,y0+r, 1,1, cr,cg,cb,ca);
        vert(data, x0,  y0,   t,t, cr,cg,cb,ca);
        vert(data, x0+r,y0+r, 1,1, cr,cg,cb,ca);
        vert(data, x0  ,y0+r, t,1, cr,cg,cb,ca);

        // top-right
        vert(data, x1-r,y0,   1,t, cr,cg,cb,ca);
        vert(data, x1,  y0,   t,t, cr,cg,cb,ca);
        vert(data, x1,  y0+r, t,1, cr,cg,cb,ca);
        vert(data, x1-r,y0,   1,t, cr,cg,cb,ca);
        vert(data, x1,  y0+r, t,1, cr,cg,cb,ca);
        vert(data, x1-r,y0+r, 1,1, cr,cg,cb,ca);

        // bottom-left
        vert(data, x0,  y1-r, t,1, cr,cg,cb,ca);
        vert(data, x0+r,y1-r, 1,1, cr,cg,cb,ca);
        vert(data, x0+r,y1,   1,t, cr,cg,cb,ca);
        vert(data, x0,  y1-r, t,1, cr,cg,cb,ca);
        vert(data, x0+r,y1,   1,t, cr,cg,cb,ca);
        vert(data, x0  ,y1,   t,t, cr,cg,cb,ca);

        // bottom-right
        vert(data, x1-r,y1-r, 1,1, cr,cg,cb,ca);
        vert(data, x1,  y1-r, t,1, cr,cg,cb,ca);
        vert(data, x1,  y1,   t,t, cr,cg,cb,ca);
        vert(data, x1-r,y1-r, 1,1, cr,cg,cb,ca);
        vert(data, x1,  y1,   t,t, cr,cg,cb,ca);
        vert(data, x1-r,y1,   1,t, cr,cg,cb,ca);

        // top
        vert(data, x0+r,y0,   1,t, cr,cg,cb,ca);
        vert(data, x1-r,y0,   1,t, cr,cg,cb,ca);
        vert(data, x1-r,y0+r, 1,1, cr,cg,cb,ca);
        vert(data, x0+r,y0,   1,t, cr,cg,cb,ca);
        vert(data, x1-r,y0+r, 1,1, cr,cg,cb,ca);
        vert(data, x0+r,y0+r, 1,1, cr,cg,cb,ca);

        // bottom
        vert(data, x0+r,y1-r, 1,1, cr,cg,cb,ca);
        vert(data, x1-r,y1-r, 1,1, cr,cg,cb,ca);
        vert(data, x1-r,y1,   1,t, cr,cg,cb,ca);
        vert(data, x0+r,y1-r, 1,1, cr,cg,cb,ca);
        vert(data, x1-r,y1,   1,t, cr,cg,cb,ca);
        vert(data, x0+r,y1,   1,t, cr,cg,cb,ca);

        // left
        vert(data, x0,  y0+r, t,1, cr,cg,cb,ca);
        vert(data, x0+r,y0+r, 1,1, cr,cg,cb,ca);
        vert(data, x0+r,y1-r, 1,1, cr,cg,cb,ca);
        vert(data, x0,  y0+r, t,1, cr,cg,cb,ca);
        vert(data, x0+r,y1-r, 1,1, cr,cg,cb,ca);
        vert(data, x0,  y1-r, t,1, cr,cg,cb,ca);

        // right
        vert(data, x1-r,y0+r, 1,1, cr,cg,cb,ca);
        vert(data, x1,  y0+r, t,1, cr,cg,cb,ca);
        vert(data, x1,  y1-r, t,1, cr,cg,cb,ca);
        vert(data, x1-r,y0+r, 1,1, cr,cg,cb,ca);
        vert(data, x1,  y1-r, t,1, cr,cg,cb,ca);
        vert(data, x1-r,y1-r, 1,1, cr,cg,cb,ca);

        // middle
        vert(data, x0+r,y0+r, 1,1, cr,cg,cb,ca);
        vert(data, x1-r,y0+r, 1,1, cr,cg,cb,ca);
        vert(data, x1-r,y1-r, 1,1, cr,cg,cb,ca);
        vert(data, x0+r,y0+r, 1,1, cr,cg,cb,ca);
        vert(data, x1-r,y1-r, 1,1, cr,cg,cb,ca);
        vert(data, x0+r,y1-r, 1,1, cr,cg,cb,ca);

        buffer.vertexData.subData(data, index);

        return this;
    }

    // Element
    public function render(gui:Gui, mpos:Maybe<Vec2>, proj:Mat3x2, xform:Mat3x2) {
        gui.textRenderer()
            .setTransform(proj * xform)
            .render(buffer);
        if (mpos.runOr(internal, false) && getOccluder()) gui.occludes();
    }
}
