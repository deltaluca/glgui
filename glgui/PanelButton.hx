package glgui;

import ogl.GLM;
import glgui.Panel;
import glgui.Text;
import glgui.Mouse;
import gl3font.Font;
import gl3font.GLString;
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
    @:builder var text:GLString = "";
    @:builder var disabledText:GLString = "";
    @:builder var size:Int = -1;

    @:builder var colour      :Vec4 = [0.1,0.1,0.1,1.0];
    @:builder var borderColour:Vec4 = [0.3,0.3,0.3,1.0];
    @:builder var overColour  :Vec4 = [1.0,1.0,1.0,0.2];
    @:builder var pressColour :Vec4 = [0.5,0.5,0.5,1.0];

    @:builder var press:Maybe<Bool->Void>;
    @:builder var drag:Maybe<Maybe<Vec2>->Void>;

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
        buttonOver   = new Panel().active(false);
        buttonText   = new Text();
        buttonMouse  = new Mouse()
            .interior(buttonBorder.internal)
            .enter  (function () buttonOver .active(true ))
            .exit   (function () buttonOver .active(false))
            .press  (function (_, but) {
                if (Type.enumEq(but, MouseLeft))
                    buttonPress.active(true);
            })
            .release(function (_, but, over) {
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
        return getFit();
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
        if (getText().length != 0)
            buttonText
                .fit(fit + new Vec4([t+0.5*r,t+0.5*r,-(t+0.5*r)*2,-(t+0.5*r)*2]))
                .font(getFont())
                .text(getText())
                .halign(TextAlignCentre)
                .valign(TextAlignCentre)
                .size(getSize())
                .commit();
        return this;
    }

    // Element
    public function render(gui:Gui, mousePos:Maybe<Vec2>, proj:Mat3x2, xform:Mat3x2) {
        buttonBorder.render(gui, mousePos, proj, xform);

        if (getDisabled()) buttonPress.active(false);
        if (toggleButton) buttonPress.active(getToggled());
        if (buttonPress.getActive())
            buttonPress .render(gui, mousePos, proj, xform);

        buttonMiddle.render(gui, mousePos, proj, xform);

        if (getText().length != 0) {
            buttonText.text(getText());
            if (getDisabled()) buttonText.text(getDisabledText());
            if (toggleButton)
                buttonText.text(getToggled() ? getText() : getDisabledText());
            buttonText.commit().render(gui, mousePos, proj, xform);
        }

        if (getDisabled()) buttonOver.active(false);
        if (buttonOver.getActive())
            buttonOver  .render(gui, mousePos, proj, xform);

        buttonMouse .render(gui, mousePos, proj, xform);

        if (buttonMouse.isPressedLeft)
            getDrag().call1(cast mousePos);
    }
}
