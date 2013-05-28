package glgui;

import ogl.GL;
import ogl.GLM;
import gl3font.Font;
import goodies.Builder;
import goodies.Maybe;
import glgui.Image;
import glgui.Drawing;

/**
 * @:noCompletion
 */
enum GuiState {
    GSNone;
    GSText;
    GSImage;
    GSDrawing;
}

enum KeyState {
    KSPress;
    KSHold;
    KSDelayedHold;
    KSRelease;
}

// Made to match those of GLFW3 library.
class KeyCode {
    public static inline var SPACE         = 32;
    public static inline var APOSTROPHE    = 39;
    public static inline var COMMA         = 44;
    public static inline var MINUS         = 45;
    public static inline var PERIOD        = 46;
    public static inline var SLASH         = 47;
    public static inline var ZERO          = 48;
    public static inline var ONE           = 49;
    public static inline var TW0           = 50;
    public static inline var THREE         = 51;
    public static inline var FOUR          = 52;
    public static inline var FIVE          = 53;
    public static inline var SIX           = 54;
    public static inline var SEVEN         = 55;
    public static inline var EIGHT         = 56;
    public static inline var NINE          = 57;
    public static inline var SEMICOLON     = 59;
    public static inline var EQUALS        = 61;
    public static inline var A             = 65;
    public static inline var B             = 66;
    public static inline var C             = 67;
    public static inline var D             = 68;
    public static inline var E             = 69;
    public static inline var F             = 70;
    public static inline var G             = 71;
    public static inline var H             = 72;
    public static inline var I             = 73;
    public static inline var J             = 74;
    public static inline var K             = 75;
    public static inline var L             = 76;
    public static inline var M             = 77;
    public static inline var N             = 78;
    public static inline var O             = 79;
    public static inline var P             = 80;
    public static inline var Q             = 81;
    public static inline var R             = 82;
    public static inline var S             = 83;
    public static inline var T             = 84;
    public static inline var U             = 85;
    public static inline var V             = 86;
    public static inline var W             = 87;
    public static inline var X             = 88;
    public static inline var Y             = 89;
    public static inline var Z             = 90;
    public static inline var LEFT_BRACKET  = 91;
    public static inline var BACKSLASH     = 92;
    public static inline var RIGHT_BRACKET = 93;
    public static inline var GRAVE         = 96;
    public static inline var WORLD_1       = 161;
    public static inline var WORLD_2       = 162;
    public static inline var ESCAPE        = 256;
    public static inline var ENTER         = 257;
    public static inline var TAB           = 258;
    public static inline var BACKSPACE     = 259;
    public static inline var INSERT        = 260;
    public static inline var DELETE        = 261;
    public static inline var RIGHT         = 262;
    public static inline var LEFT          = 263;
    public static inline var DOWN          = 264;
    public static inline var UP            = 265;
    public static inline var PAGE_UP       = 266;
    public static inline var PAGE_DOWN     = 267;
    public static inline var HOME          = 268;
    public static inline var END           = 269;
    public static inline var CAPS_LOCK     = 280;
    public static inline var SCROLL_LOCK   = 281;
    public static inline var NUM_LOCK      = 282;
    public static inline var PRINT_SCREEN  = 283;
    public static inline var PAUSE         = 284;
    public static inline var F1            = 290;
    public static inline var F2            = 291;
    public static inline var F3            = 292;
    public static inline var F4            = 293;
    public static inline var F5            = 294;
    public static inline var F6            = 295;
    public static inline var F7            = 296;
    public static inline var F8            = 297;
    public static inline var F9            = 298;
    public static inline var F10           = 299;
    public static inline var F11           = 300;
    public static inline var F12           = 301;
    public static inline var F13           = 302;
    public static inline var F14           = 303;
    public static inline var F15           = 304;
    public static inline var F16           = 305;
    public static inline var F17           = 306;
    public static inline var F18           = 307;
    public static inline var F19           = 308;
    public static inline var F20           = 309;
    public static inline var F21           = 310;
    public static inline var F22           = 311;
    public static inline var F23           = 312;
    public static inline var F24           = 313;
    public static inline var F25           = 314;
    public static inline var KP_0          = 320;
    public static inline var KP_1          = 321;
    public static inline var KP_2          = 322;
    public static inline var KP_3          = 323;
    public static inline var KP_4          = 324;
    public static inline var KP_5          = 325;
    public static inline var KP_6          = 326;
    public static inline var KP_7          = 327;
    public static inline var KP_8          = 328;
    public static inline var KP_9          = 329;
    public static inline var KP_DECIMAL    = 330;
    public static inline var KP_DIVIDE     = 331;
    public static inline var KP_MULTIPLY   = 332;
    public static inline var KP_SUBTRACT   = 333;
    public static inline var KP_ADD        = 334;
    public static inline var KP_ENTER      = 335;
    public static inline var KP_EQUALS     = 336;
    public static inline var LEFT_SHIFT    = 340;
    public static inline var LEFT_CONTROL  = 341;
    public static inline var LEFT_ALT      = 342;
    public static inline var LEFT_SUPER    = 343;
    public static inline var RIGHT_SHIFT   = 344;
    public static inline var RIGHT_CONTROL = 345;
    public static inline var RIGHT_ALT     = 346;
    public static inline var RIGHT_SUPER   = 347;
    public static inline var MENU          = 348;
}

/**
 * GUI alpha and omega
 */

class Gui implements Builder implements MaybeEnv {
    var renderState:GuiState;
    var registeredMice:Array<Mouse>;

    var textRender:FontRenderer;
    var imageRender:ImageRenderer;
    var drawing:Drawing;

    public function new() {
        textRender  = new FontRenderer();
        imageRender = new ImageRenderer();
        drawing  = new Drawing();

        renderState = GSNone;
        registeredMice = [];

        sightLeft   = [];
        sightRight  = [];
        sightMiddle = [];

        focus = [];
        scissorStack = [];
    }

    /**
     * Destroy the GUI, opengl memory released etc.
     */
    public function destroy() {
        textRender .destroy();
        imageRender.destroy();
        drawing .destroy();
    }

    /**
     * Finish drawing GUI, this will flush any pending
     * draw calls, and process any remaining events.
     */
    public function flushRender() {
        switch (renderState) {
        case GSText:  textRender .end();
        case GSImage: imageRender.end();
        case GSDrawing: drawing  .end();
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
            for (m in sightLeft) m.releasedLeft(getMousePos());
            sightLeft = [];
        }
        if (!getMouseMiddle()) {
            for (m in sightMiddle) m.releasedMiddle(getMousePos());
            sightMiddle = [];
        }
        if (!getMouseRight()) {
            for (m in sightRight) m.releasedRight(getMousePos());
            sightRight = [];
        }
        var keys = getKeysPressed();
        var chars = getCharsPressed();
        for (f in focus) {
            if (keys.length  != 0) f.getKey()      .call1(keys);
            if (chars.length != 0) f.getCharacter().call1(chars);
            f.getFocus().call();
        }
    }

    @:builder var time:Float = 0.0;

    /**
     * Set screen width/height
     */
    @:builder var screen:Vec2;

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

    var scissorStack:Array<Vec4>;
    @:allow(glgui)
    function pushScissor(x:Vec4) {
        GL.enable(GL.SCISSOR_TEST);
        GL.scissor(Math.floor(x.x), Math.floor(getScreen().y-x.y-x.w), Math.ceil(x.z), Math.ceil(x.w));
        scissorStack.push(x);
    }
    @:allow(glgui)
    function popScissor() {
        scissorStack.pop();
        if (scissorStack.length == 0) {
            GL.scissor(0, 0, Math.ceil(getScreen().x), Math.ceil(getScreen().y));
        }
        else {
            var x = scissorStack[scissorStack.length-1];
            GL.disable(GL.SCISSOR_TEST);
        }
    }

    /*
     * Render a GUI element
     */
    public function render<S,T:Element<S>>(x:T) {
        if (x.getActive()) {
            if (getMousePos().runOr(x.internal, false) && x.getOccluder()) {
                for (m in registeredMice) m.outside(this);
                registeredMice = [];
            }
            x.render(this, getMousePos(), Mat3x2.viewportMap(getScreen().x, getScreen().y), Mat3x2.identity());
        }
    }

    public function projection()
        return Mat3x2.viewportMap(getScreen().x, getScreen().y);

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

    public function drawings() {
        switch (renderState) {
        case GSDrawing:
        default:
            flushRender();
            renderState = GSDrawing;
            drawing.begin();
        }
        return drawing;
    }
}
