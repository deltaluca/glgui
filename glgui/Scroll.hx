package glgui;

import glgui.Gui;
import ogl.GLM;
import ogl.GL;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;

class Scroll<T> implements Element<Scroll<T>> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    @:builder var occluder = false;

    // Scroll
    @:builder var scroll:Mat3x2 = Mat3x2.identity(); // general sub-transform
    @:lazyVar @:builder var element:Element<T>;

    public function new() {
    }

    // Element
    public function destroy() {
        getElement().destroy();
    }

    // Element
    public function bounds():Maybe<Vec4> {
        var bounds = getElement().bounds();
        if (bounds == null) return null;

        var fit = getFit();
        var bounds = getScroll() * bounds.extract();
        bounds.x += fit.x;
        bounds.y += fit.y;

        // intersectino of element bounds (after sub-transform) and bounds.
        var x = Math.max(fit.x, bounds.x);
        var y = Math.max(fit.y, bounds.y);
        return [
            x, y,
            Math.min(fit.x+fit.z, bounds.x+bounds.z) - x,
            Math.min(fit.y+fit.w, bounds.y+bounds.w) - y
        ];
    }

    // Element
    public function internal(x:Vec2) {
        var fit = getFit();
        if (x.x < fit.x || x.y < fit.y ||
            x.x > fit.x+fit.z || x.y > fit.y+fit.w) return false;
        return getElement().internal(getScroll().inverse() * (x - new Vec2([fit.x, fit.y])));
    }

    // Element
    public function commit() {
        return this;
    }

    // Element
    public function render(gui:Gui, mousePos:Maybe<Vec2>, xform:Mat3x2) {
        var fit = getFit();
        if (mousePos != null) {
            var pos = mousePos.extract();
            if (pos.x < fit.x || pos.y < fit.y ||
                pos.x > fit.x+fit.z || pos.y > fit.y+fit.w) mousePos = null;
            mousePos = getScroll().inverse() * (pos - new Vec2([fit.x, fit.y]));
        }
        GL.scissor(Std.int(fit.x), Std.int(600-fit.y-fit.w), Std.int(fit.z), Std.int(fit.w));
        getElement().render(gui, mousePos, xform * Mat3x2.translate(fit.x, fit.y) * getScroll());
        GL.scissor(0,0, 800,600);
    }
}
