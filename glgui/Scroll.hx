package glgui;

import glgui.Gui;
import ogl.GLM;
import ogl.GL;
import glgui.Panel;
import glgui.Mouse;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;

using glgui.Transform;

class Scroll<T> implements Element<Scroll<T>> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    @:builder var occluder = false; //unused

    // Scroll
    @:builder var scroll:Vec2 = [0,0];
    @:lazyVar @:builder var element:Element<T>;

    @:builder var hscroll = false;
    @:builder var vscroll = false;
    @:builder var scrollColour:Vec4 = [0.5,0.5,0.5,1];
    @:builder var sliderColour:Vec4 = [0.9,0.9,0.9,1];
    @:builder var scrollSize:Float = 15;

    var hscrollPanel:Panel;
    var hscrollSlider:PanelButton;
    var vscrollPanel:Panel;
    var vscrollSlider:PanelButton;

    var hpercent:Float = 0.0;
    var vpercent:Float = 0.0;

    public static inline var gapf = 1/4;
    public static inline var railf = 1/4;
    public var y0:Float; public var x0:Float;
    public var yd:Float; public var xd:Float;

    public function new() {
        hscrollPanel = new Panel().occluder(false);
        vscrollPanel = new Panel().occluder(false);
        hscrollSlider = new PanelButton()
            .drag(function (mpos) {
                if (mpos == null) return;
                var mpos = mpos.extract();
                hpercent = Math.max(0, Math.min(1, (mpos.x-getScrollSize()/2-x0)/xd));
            });
        vscrollSlider = new PanelButton()
            .drag(function (mpos) {
                if (mpos == null) return;
                var mpos = mpos.extract();
                vpercent = Math.max(0, Math.min(1, (mpos.y-getScrollSize()/2-y0)/yd));
            });
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
        return getElement().internal(stransform().inverse() * (x - new Vec2([fit.x, fit.y])));
    }

    // Element
    public function commit() {
        var fit = getFit();
        var scrollSize = getScrollSize();
        hscrollSlider
            .fit([0, fit.y + fit.w - scrollSize*(1+gapf), scrollSize, scrollSize])
            .radius(scrollSize/2)
            .thickness(2)
            .colour(getSliderColour())
            .active(getHscroll())
            .commit();
        vscrollSlider
            .fit([fit.x + fit.z - scrollSize*(1+gapf), 0, scrollSize, scrollSize])
            .radius(scrollSize/2)
            .thickness(2)
            .colour(getSliderColour())
            .active(getVscroll())
            .commit();
        hscrollPanel
            .fit([fit.x + scrollSize*(3/2 + gapf - railf/2),
                  fit.y + fit.w - scrollSize*(gapf + 1/2 + railf/2),
                  fit.z - scrollSize*(2 + gapf*2 + (1 - railf)),
                  scrollSize * railf])
            .radius(scrollSize*railf/2)
            .colour(getScrollColour())
            .active(getHscroll())
            .commit();
        vscrollPanel
            .fit([fit.x + fit.z - scrollSize*(gapf + 1/2 + railf/2),
                  fit.y + scrollSize*(3/2 + gapf - railf/2),
                  scrollSize * railf,
                  fit.w - scrollSize*(2 + gapf*2 + (1 - railf))])
            .radius(scrollSize*railf/2)
            .colour(getScrollColour())
            .active(getVscroll())
            .commit();

        x0 = fit.x + scrollSize*(1 + gapf);
        y0 = fit.y + scrollSize*(1 + gapf);
        xd = fit.z - scrollSize*(3 + 2*gapf);
        yd = fit.w - scrollSize*(3 + 2*gapf);

        return this;
    }

    function stransform() {
        return Mat3x2.translate(getScroll().x, getScroll().y);
    }

    // Element
    public function render(gui:Gui, mousePos:Maybe<Vec2>, proj:Mat3x2, xform:Mat3x2) {
        var fit = getFit();
        var scrollSize = getScrollSize();
        var bounds = getElement().bounds();
        var bounds = if (bounds == null) new Vec4([0,0,0,0]) else bounds.extract();
        if (getHscroll()) {
            var s = getScroll();
            s.x = Math.min(0, -hpercent*(bounds.z - fit.z)) - bounds.x;
            scroll(s);
        }
        if (getVscroll()) {
            var s = getScroll();
            s.y = Math.min(0, -vpercent*(bounds.w - fit.w)) - bounds.y;
            scroll(s);
        }
        var tmousePos = null;
        if (mousePos != null) {
            var pos = mousePos.extract();
            if (!gui.getMouseLeft() &&
               (pos.x < fit.x || pos.y < fit.y ||
                pos.x > fit.x+fit.z || pos.y > fit.y+fit.w))
                tmousePos = null;
            else
                tmousePos = stransform().inverse() * (pos - new Vec2([fit.x, fit.y]));
        }
        gui.flushRender();
        gui.pushScissor(xform * fit);
        getElement().render(gui, tmousePos, proj, xform * Mat3x2.translate(fit.x, fit.y) * stransform());
        gui.flushRender();
        gui.popScissor();
        if (getHscroll()) {
            do {
                var mod:Vec4 = [0,0,0,0];
                if (mousePos != null) {
                    var mx = mousePos.extract().x;
                    var dx = if (mx > fit.x && mx < fit.x + fit.z) 0
                             else Math.min(Math.abs(mx - fit.x), Math.abs(mx - fit.x - fit.z));
                    var dy = mousePos.extract().y - (fit.y + fit.w - scrollSize*(1/2+gapf));
                    var del = Math.sqrt(dx*dx+dy*dy);
                    if (del > 40) break;
                    else del = Math.cos(del*Math.PI/80);
                    mod = [del,del,del,del];
                }else break;
                hscrollPanel
                    .colour(getScrollColour() * mod)
                    .commit()
                    .render(gui, mousePos, proj, xform);

                hscrollSlider
                    .colour(getSliderColour() * mod)
                    .borderColour(new Vec4([0.3,0.3,0.3,1.0])*mod)
                    .posx(x0 + xd*hpercent)
                    .commit()
                    .render(gui, mousePos, proj, xform);
            } while(false);
        }
        if (getVscroll()) {
            do {
                var mod:Vec4 = [0,0,0,0];
                if (mousePos != null) {
                    var dx = mousePos.extract().x - (fit.x + fit.z - scrollSize*(1/2+gapf));
                    var my = mousePos.extract().y;
                    var dy = if (my > fit.y && my < fit.y + fit.w) 0
                             else Math.min(Math.abs(my - fit.y), Math.abs(my - fit.y - fit.w));
                    var del = Math.sqrt(dx*dx+dy*dy);
                    if (del > 40) break;
                    else del = Math.cos(del*Math.PI/80);
                    mod = [del,del,del,del];
                }else break;
                vscrollPanel
                    .colour(getScrollColour() * mod)
                    .commit()
                    .render(gui, mousePos, proj, xform);
                vscrollSlider
                    .colour(getSliderColour() * mod)
                    .borderColour(new Vec4([0.3,0.3,0.3,1.0])*mod)
                    .posy(y0 + yd*vpercent)
                    .commit()
                    .render(gui, mousePos, proj, xform);
            } while(false);
        }
    }

    public function suplRender(gui:Gui, xform:Mat3x2, f:Mat3x2->Void) {
        var fit = getFit();
        gui.flushRender();
        gui.pushScissor(xform * fit);
        f(xform * Mat3x2.translate(fit.x, fit.y) * stransform());
        gui.flushRender();
        gui.popScissor();
    }
}
