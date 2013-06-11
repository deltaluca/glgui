package glgui;

import ogl.GLM;
import gl3font.Font;
import gl3font.GLString;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;
import cpp.vm.Tls;

class Vector implements Element<Vector> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    @:builder var occluder = false; //unused

    @:builder @:lazyVar var image:Font;
    @:builder var uv:Vec4 = [0,0,1,1];
    @:builder var colour:Vec4 = [1,1,1,1];

    public var buffer:StringBuffer;
    public function new() {
        buffer = new StringBuffer(null);
    }

    // Element
    public function bounds():Maybe<Vec4> return getFit();

    // Element
    public function destroy() {}

    // Element
    public function internal(x:Vec2) return false;

    // Element
    public function commit() {
        buffer.font = getImage();
        var col = getColour();
        var uv = getUv();

        var d = StringBuffer.VERTEX_SIZE;
        var index = buffer.reserve(6) - d;

        buffer.vertex(index+=d, 0,0, uv.x,     uv.y,      col);
        buffer.vertex(index+=d, 1,0, uv.x+uv.z,uv.y,      col);
        buffer.vertex(index+=d, 1,1, uv.x+uv.z,uv.y+uv.w, col);

        buffer.vertex(index+=d, 0,0, uv.x,     uv.y,      col);
        buffer.vertex(index+=d, 1,1, uv.x+uv.z,uv.y+uv.w, col);
        buffer.vertex(index+=d, 0,1, uv.x,     uv.y+uv.w, col);

        return this;
    }

    // Element
    public function render(gui:Gui, mpos:Maybe<Vec2>, proj:Mat3x2, xform:Mat3x2) {
        var fit = getFit();
        var tform = Mat3x2.translate(fit.x, fit.y) *
                    Mat3x2.scale(fit.z, fit.w);
        gui.textRenderer()
            .setTransform(proj * xform * tform)
            .render(buffer);
    }
}
