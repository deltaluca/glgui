package glgui;

import glgui.Gui;
import ogl.GLM;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;

class Custom implements Element<Custom> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    @:builder var occluder = false;

    @:builder var applyInternal:Maybe<Vec2->Bool>;
    @:builder var apply:Maybe<Gui->Maybe<Vec2>->Mat3x2->Mat3x2->Void>;

    public function new() {}

    // Element
    public function destroy() {}

    // Element
    public function bounds():Maybe<Vec4> return null;

    // Element
    public function internal(x:Vec2) {
        return getApplyInternal().runOr(function (f) return f(x), false);
    }

    // Element
    public function commit() return this;

    // Element
    public function render(gui:Gui, mousePos:Maybe<Vec2>, proj:Mat3x2, xform:Mat3x2) {
        var app = getApply();
        if (app == null) return;
        app.extract()(gui, mousePos, proj, xform);
    }
}
