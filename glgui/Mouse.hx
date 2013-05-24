package glgui;

import ogl.GLM;
import goodies.Builder;
using goodies.Maybe;
import goodies.Lazy;
import goodies.Func;
import glgui.Gui;

enum MouseButton {
    MouseLeft;
    MouseMiddle;
    MouseRight;
}

/**
 * Virtual GUI element for mouse events.
 */
class Mouse implements Element<Mouse> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    @:builder var occluder = false;

    // Mouse
    /** Button disabled, still receive enter/exit, but not press/release **/
    @:builder var disabled = false;
    /** Button is a toggle mouse area **/
    @:builder var toggle   = false;

    /**
      * Function defining what it is to be in the mouse areas area.
      * If null, then the mouse areas 'fit' rectangle is used
      */
    @:builder var interior:Maybe<Vec2->Bool> = null;

    /** Handler for mouse-enter event */
    @:builder var enter  :Maybe<Void->Void> = null;
    /** Handler for mouse-exit event */
    @:builder var exit   :Maybe<Void->Void> = null;
    /** Handler for mouse-press event, with mouse area pressed */
    @:builder var press  :Maybe<MouseButton->Void> = null;
    /** Handler for mouse-release event, with mouse area released */
    @:builder var release:Maybe<MouseButton->Bool->Void> = null;
    /** Handler for mouse-scroll event */
    @:builder var scroll :Maybe<Float->Void>  = null;


    /** Handler for key event (in sight) */
    /** Handler for character event (in sight) */
    @:builder var key:Maybe<Array<{key:Int,state:KeyState}>->Void> = null;
    @:builder var character:Maybe<Array<Int>->Void> = null;

    /** If mouse is currently over mouse area */
    public var isOver         (default,null) = false;
    /** If mouse left button area is currently pressed on mouse area */
    public var isPressedLeft  (default,null) = false;
    /** If mouse right button area is currently pressed on mouse area */
    public var isPressedRight (default,null) = false;
    /** If mouse middle button area is currently pressed on mouse area */
    public var isPressedMiddle(default,null) = false;

    public function new() {}

    // Element
    public function destroy() {}
    // Element
    public function internal(x:Vec2) {
        var int = getInterior();
        return int.run(
            Func.call1.bind(_,x),
            function () {
                var fit = getFit();
                var dx = x.x - fit.x;
                var dy = x.y - fit.y;
                return dx >= 0 && dx <= fit.z &&
                       dy >= 0 && dy <= fit.w;
            }
        );
    }
    // Element
    public function bounds():Maybe<Vec4> return null;
    // Element
    public function commit() {
        return this;
    }

    // Called by Gui when mouse is definitely inside mouse area
    // (and not occluded)
    @:allow(glgui)
    function inside(gui:Gui) {
        if (!isOver) {
            isOver = true;
            getEnter().call();
        }
        if (!isPressedLeft && gui.mouseWasPressedLeft) {
            isPressedLeft = true;
            getPress().call1(MouseLeft);
            gui.sightLeft.push(this);
        }
        if (!isPressedRight && gui.mouseWasPressedRight) {
            isPressedRight = true;
            getPress().call1(MouseRight);
            gui.sightRight.push(this);
        }
        if (!isPressedMiddle && gui.mouseWasPressedMiddle) {
            isPressedMiddle = true;
            getPress().call1(MouseMiddle);
            gui.sightMiddle.push(this);
        }

        if (gui.getMouseScroll() != 0)
            getScroll().call1(gui.getMouseScroll());
    }

    // Called by Gui when mouse is definitely outside mouse area
    // or occluded.
    @:allow(glgui)
    function outside(gui:Gui) {
        if (isOver) {
            isOver = false;
            getExit().call();
        }
    }

    // Called by Gui when left key is released on pressed mouse area
    // etc for other buttons.
    @:allow(glgui)
    function releasedLeft() {
        isPressedLeft = false;
        getRelease().call2(MouseLeft, isOver);
    }
    @:allow(glgui)
    function releasedRight() {
        isPressedRight = false;
        getRelease().call2(MouseRight, isOver);
    }
    @:allow(glgui)
    function releasedMiddle() {
        isPressedMiddle = false;
        getRelease().call2(MouseMiddle, isOver);
    }

    // Element
    public function render(gui:Gui, mousePos:Maybe<Vec2>, _) {
        if (mousePos.runOr(internal, false)) gui.registerMouse(this);
        else outside(gui);
    }
}
