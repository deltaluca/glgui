package glgui;

import ogl.GLM;
import gl3font.Font;
import goodies.Builder;
import goodies.Maybe;
import glgui.Image;

/**
 * @:noCompletion
 */
enum GuiState {
    GSNone;
    GSText;
    GSImage;
}

enum KeyState {
    KSPress;
    KSHold;
    KSRelease;
}

/**
 * GUI alpha and omega
 */
class Gui implements Builder implements MaybeEnv {
    var renderState:GuiState;
    var registeredMice:Array<Mouse>;

    var textRender:FontRenderer;
    var imageRender:ImageRenderer;

    public function new() {
        textRender  = new FontRenderer();
        imageRender = new ImageRenderer();
        renderState = GSNone;
        registeredMice = [];

        sightLeft   = [];
        sightRight  = [];
        sightMiddle = [];

        focus = [];
    }

    /**
     * Destroy the GUI, opengl memory released etc.
     */
    public function destroy() {
        textRender .destroy();
        imageRender.destroy();
    }

    /**
     * Finish drawing GUI, this will flush any pending
     * draw calls, and process any remaining events.
     */
    public function flushRender() {
        switch (renderState) {
        case GSText: textRender.end();
        case GSImage: imageRender.end();
        case GSNone:
        }
        renderState = GSNone;
    }
    public function flush() {
        flushRender();
        for (m in registeredMice) m.inside(this);
        registeredMice = [];

        if (sightLeft.length != 0)
             focus = sightLeft = sightLeft.filter(function (x) return x!=null);
        else sightLeft = sightLeft.filter(function (x) return x!=null);

        if (!getMouseLeft()) {
            for (m in sightLeft) m.releasedLeft();
            sightLeft = [];
        }
        if (!getMouseMiddle()) {
            for (m in sightMiddle) m.releasedMiddle();
            sightMiddle = [];
        }
        if (!getMouseRight()) {
            for (m in sightRight) m.releasedRight();
            sightRight = [];
        }
        var keys = getKeysPressed();
        var chars = getCharsPressed();
        for (f in focus) {
            if (keys.length  != 0) f.getKey()      .call1(keys);
            if (chars.length != 0) f.getCharacter().call1(chars);
        }
    }

    /**
     * Set projection matrix for gui rendering.
     * eg: Mat3x2.viewportMap(width, height)
     */
    @:builder var projection:Mat3x2 = Mat3x2.identity();

    /**
     * Set mouse position for event processing.
     * null indicates mouse is outside the screen.
     */
    @:builder var mousePos:Maybe<Vec2> = null;

    /**
     * Set mouse scroll offset
     */
    @:builder var mouseScroll:Float = 0.0;

    /**
     * Set mouse left/right/middle button states for
     * event processing.
     */
    @:builder(react = function (mouseLeft) {
        mouseWasPressedLeft = !getMouseLeft()&&mouseLeft;
        if (mouseWasPressedLeft)
            sightLeft.push(null);
    }) var mouseLeft = false;
    @:builder(react = function (mouseRight)
        mouseWasPressedRight = !getMouseRight()&&mouseRight
    ) var mouseRight = false;
    @:builder(react = function (mouseMiddle)
        mouseWasPressedMiddle = !getMouseMiddle()&&mouseMiddle
    ) var mouseMiddle = false;

    /*
     * Set of raw keys pressed for this frame
     * Set of 'characters' pressed for this frame
     */
    @:builder var keysPressed :Array<{key:Int,state:KeyState}> = [];
    @:builder var charsPressed:Array<Int> = [];

    /*
     * True if (based on provided state) the mouse button
     * was pressed exactly on this frame (not held)
     */
    public var mouseWasPressedLeft  (default,null) = false;
    public var mouseWasPressedRight (default,null) = false;
    public var mouseWasPressedMiddle(default,null) = false;

    /*
     * List of Mouse elements currently holding sight of
     * mouse buttons (Possibly many if overlapping and not occluded).
     */
    public var sightLeft  (default,null):Array<Mouse>;
    public var sightRight (default,null):Array<Mouse>;
    public var sightMiddle(default,null):Array<Mouse>;

    /*
     * List of Mouse elements currently in focus by left-click
     * selectino (Possibly many if overlapping and not occluded).
     */
    public var focus(default,null):Array<Mouse>;

    /*
     * Render a GUI element
     */
    public function render<S,T:Element<S>>(x:T) {
        if (x.getActive()) {
            if (getMousePos().runOr(x.internal, false) && x.getOccluder()) {
                for (m in registeredMice) m.outside(this);
                registeredMice = [];
            }
            x.render(this, getMousePos(), getProjection());
        }
    }

    @:allow(glgui)
    function registerMouse(x:Mouse) {
        registeredMice.push(x);
    }

    /*
     * Get GUI's GL3Font TextRenderer object.
     * Renderer's begin() end() calls are auto managed.
     */
    public function textRenderer() {
        switch (renderState) {
        case GSText:
        default:
            flushRender();
            renderState = GSText;
            textRender.begin();
        }
        return textRender;
    }

    public function imageRenderer() {
        switch (renderState) {
        case GSImage:
        default:
            flushRender();
            renderState = GSImage;
            imageRender.begin();
        }
        return imageRender;
    }
}
