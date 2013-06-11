package glgui;

import glgui.Gui;
import ogl.GLM;
import ogl.GL;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;

class Group implements Element<Group> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0]; //zw unused.
    @:builder var occluder = false; //unused

    public inline function element(e:Dynamic) {
        elements.push(e);
        return this;
    }
    public inline function removeElement(e:Dynamic) {
        elements.remove(e);
        return this;
    }
    public inline function bringToFront(e:Dynamic) {
        elements.remove(e);
        elements.push(e);
        return this;
    }

    public var elements:Array<Dynamic>;
    public function new() {
        elements = [];
    }

    // Element
    public function destroy() {
        while (elements.length != 0) elements.pop().destroy();
    }

    // Element
    public function bounds():Maybe<Vec4> {
        var fit:Vec4 = [1e100, 1e100, -1e100, -1e100];
        for (e in elements) {
            var bounds:Maybe<Vec4> = e.bounds();
            if (bounds != null) {
                var bounds = bounds.extract();
                if (bounds.x < fit.x) fit.x = bounds.x;
                if (bounds.y < fit.y) fit.y = bounds.y;
                if (bounds.x+bounds.z > fit.z) fit.z = bounds.x+bounds.z;
                if (bounds.y+bounds.w > fit.w) fit.w = bounds.y+bounds.w;
            }
        }
        if (fit.x >= 1e100) return null;
        else {
            fit.z -= fit.x;
            fit.w -= fit.y;
            fit.x += getFit().x;
            fit.y += getFit().y;
            return fit;
        }
    }

    // Element
    public function internal(x:Vec2) {
        var y:Vec2 = x - new Vec2([getFit().x, getFit().y]);
        for (e in elements) {
            if (e.internal(y)) return true;
        }
        return false;
    }

    // Element
    public function commit() {
        return this;
    }

    // Element
    public function render(gui:Gui, mousePos:Maybe<Vec2>, proj:Mat3x2, xform:Mat3x2) {
        xform = xform * Mat3x2.translate(getFit().x, getFit().y);
        if (mousePos != null) mousePos = Mat3x2.translate(-getFit().x, -getFit().y) * mousePos.extract();
        for (e in elements)
            e.render(gui, mousePos, proj, xform);
    }
}
