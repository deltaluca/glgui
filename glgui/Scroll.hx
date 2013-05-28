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
        return getFit();
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
    public function render(gui:Gui, mousePos:Maybe<Vec2>, proj:Mat3x2, xform:Mat3x2) {
        var fit = getFit();
        if (mousePos != null) {
            var pos = mousePos.extract();
            if (pos.x < fit.x || pos.y < fit.y ||
                pos.x > fit.x+fit.z || pos.y > fit.y+fit.w) mousePos = null;
            mousePos = getScroll().inverse() * (pos - new Vec2([fit.x, fit.y]));
        }
        gui.flushRender();
        gui.pushScissor(fit);
        getElement().render(gui, mousePos, proj, xform * Mat3x2.translate(fit.x, fit.y) * getScroll());
        gui.flushRender();
        gui.popScissor();
    }

    public function suplRender(gui:Gui, xform:Mat3x2, f:Mat3x2->Void) {
        var fit = getFit();
        gui.flushRender();
        gui.pushScissor(fit);
        f(xform * Mat3x2.translate(fit.x, fit.y) * getScroll());
        gui.flushRender();
        gui.popScissor();
    }
}
