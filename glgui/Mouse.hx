package glgui;

import ogl.GLM;
import glgui.Macros;

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
    @:builder var interior:Null<Vec2->Bool> = null;

    /** Handler for mouse-enter event */
    @:builder var enter  :Null<Void->Void> = null;
    /** Handler for mouse-exit event */
    @:builder var exit   :Null<Void->Void> = null;
    /** Handler for mouse-press event, with mouse area pressed */
    @:builder var press  :Null<MouseButton->Void> = null;
    /** Handler for mouse-release event, with mouse area released */
    @:builder var release:Null<MouseButton->Void> = null;
    /** Handler for mouse-scroll event, TODO */
    @:builder var scroll :Null<Int->Void>  = null;

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
        if (int == null) {
            var fit = getFit();
            var dx = x.x - fit.x;
            var dy = x.y - fit.y;
            return dx >= 0 && dx <= fit.z &&
                   dy >= 0 && dy <= fit.w;
        }
        else return int(x);
    }
    // Element
    public function bounds():Null<Vec4> return null;
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
            if (getEnter() != null) getEnter()();
        }
        if (!isPressedLeft && gui.mouseWasPressedLeft) {
            isPressedLeft = true;
            if (getPress() != null) getPress()(MouseLeft);
            gui.focusLeft.push(this);
        }
        if (!isPressedRight && gui.mouseWasPressedRight) {
            isPressedRight = true;
            if (getPress() != null) getPress()(MouseRight);
            gui.focusRight.push(this);
        }
        if (!isPressedMiddle && gui.mouseWasPressedMiddle) {
            isPressedMiddle = true;
            if (getPress() != null) getPress()(MouseMiddle);
            gui.focusMiddle.push(this);
        }
    }

    // Called by Gui when mouse is definitely outside mouse area
    // or occluded.
    @:allow(glgui)
    function outside(gui:Gui) {
        if (isOver) {
            isOver = false;
            if (getExit() != null) getExit()();
        }
    }

    // Called by Gui when left key is released on pressed mouse area
    // etc for other buttons.
    @:allow(glgui)
    function releasedLeft() {
        isPressedLeft = false;
        if (getRelease() != null) getRelease()(MouseLeft);
    }
    @:allow(glgui)
    function releasedRight() {
        isPressedRight = false;
        if (getRelease() != null) getRelease()(MouseRight);
    }
    @:allow(glgui)
    function releasedMiddle() {
        isPressedMiddle = false;
        if (getRelease() != null) getRelease()(MouseMiddle);
    }

    // Element
    public function render(gui:Gui, mousePos:Vec2, _) {
        if (internal(mousePos)) gui.registerMouse(this);
        else outside(gui);
    }
}
