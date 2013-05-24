package glgui;

import ogl.GLM;
import glgui.Panel;
import glgui.Text;
import glgui.Mouse;
import gl3font.Font;
import goodies.Maybe;

using glgui.Transform;
using glgui.Colour;

class PanelButton implements Element<PanelButton> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    @:builder var occluder = true;

    // PanelButton
    @:builder var radius   :Float = 0;
    @:builder var thickness:Float = 2;

    @:builder var disabled = false;

    public var toggleButton(default,null):Bool;
    @:builder var toggled = false;

    @:builder var font:Font;
    @:builder var text:String;

    @:builder var colour      :Vec4 = [0.1,0.1,0.1,1.0];
    @:builder var fontColour  :Vec4 = [1.0,1.0,1.0,1.0];
    @:builder var borderColour:Vec4 = [0.3,0.3,0.3,1.0];
    @:builder var overColour  :Vec4 = [0.0,0.0,0.0,0.2];
    @:builder var pressColour :Vec4 = [0.5,0.5,0.5,1.0];
    @:builder var disabledFontColour:Vec4 = [0.3,0.3,0.3,1.0];

    @:builder var press:Maybe<Bool->Void>;

    // Sub elements
    var buttonBorder:Panel;
    var buttonPress :Panel;
    var buttonMiddle:Panel;
    var buttonOver  :Panel;
    var buttonText  :Text;
    var buttonMouse :Mouse;

    public function new(toggleButton=false) {
        this.toggleButton = toggleButton;
        buttonBorder = new Panel();
        buttonPress  = new Panel().active(false);
        buttonMiddle = new Panel();
        buttonOver   = new Panel().active(true);
        buttonText   = new Text();
        buttonMouse  = new Mouse()
            .interior(buttonBorder.internal)
            .enter  (function () buttonOver .active(false))
            .exit   (function () buttonOver .active(true ))
            .press  (function (but) {
                if (Type.enumEq(but, MouseLeft))
                    buttonPress.active(true);
            })
            .release(function (but, over) {
                if (Type.enumEq(but, MouseLeft))
                    buttonPress.active(false);
                if (over && !getDisabled()) {
                    if (toggleButton) {
                        toggled(!getToggled());
                        getPress().call1(getToggled());
                    }
                    else getPress().call1(true);
                }
            });
    }

    // Element
    public function destroy() {
        buttonBorder.destroy();
        buttonPress .destroy();
        buttonMiddle.destroy();
        buttonOver  .destroy();
        buttonText  .destroy();
    }

    // Element
    public function bounds():Maybe<Vec4> {
        return buttonBorder.bounds();
    }

    // Element
    public function internal(x:Vec2):Bool {
        return buttonBorder.internal(x);
    }

    // Element
    public function commit() {
        var fit = getFit();
        var t = getThickness();
        var r = getRadius();
        buttonBorder
            .fit(fit)
            .colour(getBorderColour())
            .radius(r)
            .commit();
        buttonPress
            .fit(fit)
            .colour(getPressColour())
            .radius(r)
            .commit();
        buttonMiddle
            .fit(fit + new Vec4([t,t,-t*2,-t*2]))
            .colour(getColour())
            .radius(Math.max(0, r - t))
            .commit();
        buttonOver
            .fit(fit)
            .colour(getOverColour())
            .radius(r)
            .commit();
        buttonText
            .fit(fit + new Vec4([t+0.5*r,t+0.5*r,-(t+0.5*r)*2,-(t+0.5*r)*2]))
            .font(getFont())
            .text(getText())
            .colour(getFontColour())
            .commit();
        return this;
    }

    // Element
    public function render(gui:Gui, mousePos:Maybe<Vec2>, xform:Mat3x2) {
        buttonBorder.render(gui, mousePos, xform);

        if (getDisabled()) buttonPress.active(false);
        if (toggleButton) buttonPress.active(getToggled());
        if (buttonPress.getActive())
            buttonPress .render(gui, mousePos, xform);

        buttonMiddle.render(gui, mousePos, xform);

        buttonText.colour(getFontColour());
        if (getDisabled()) buttonText.colour(getDisabledFontColour());
        if (toggleButton)
            buttonText.colour(getToggled() ? getFontColour() : getDisabledFontColour());
        buttonText  .render(gui, mousePos, xform);

        if (getDisabled()) buttonOver.active(true);
        if (buttonOver.getActive())
            buttonOver  .render(gui, mousePos, xform);

        buttonMouse .render(gui, mousePos, xform);
    }
}
