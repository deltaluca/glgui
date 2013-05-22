package glgui;

import ogl.GLM;
import gl3font.Font;
import glgui.Macros;

/**
 * @:noCompletion
 */
enum GuiState {
    GSText;
}

/**
 * GUI alpha and omega
 */
class Gui implements Builder {
    var renderState:GuiState;
    var textRender:FontRenderer;
    var registeredMice:Array<Mouse>;

    public function new() {
        textRender = new FontRenderer();
        renderState = null;

        registeredMice = [];

        focusLeft   = [];
        focusRight  = [];
        focusMiddle = [];
    }

    /**
     * Destroy the GUI, opengl memory released etc.
     */
    public function destroy() {
        textRender.destroy();
    }

    /**
     * Finish drawing GUI, this will flush any pending
     * draw calls, and process any remaining events.
     */
    public function flush() {
        if (renderState != null) {
            switch (renderState) {
                case GSText: textRender.end();
            }
            renderState = null;
        }

        for (m in registeredMice) m.inside(this);
        registeredMice = [];

        if (!getMouseLeft()) {
            for (m in focusLeft) m.releasedLeft();
            focusLeft = [];
        }
        if (!getMouseMiddle()) {
            for (m in focusMiddle) m.releasedMiddle();
            focusMiddle = [];
        }
        if (!getMouseRight()) {
            for (m in focusRight) m.releasedRight();
            focusRight = [];
        }
    }

    /**
     * Set projection matrix for gui rendering.
     * eg: Mat3x2.viewportMap(width, height)
     */
    @:builder var projection:Mat3x2;

    /**
     * Set mouse position for event processing.
     */
    @:builder var mousePos:Vec2;

    /**
     * Set mouse left/right/middle button states for
     * event processing.
     */
    @:builder(react = function (mouseLeft)
        mouseWasPressedLeft = !getMouseLeft()&&mouseLeft
    ) var mouseLeft = false;
    @:builder(react = function (mouseRight)
        mouseWasPressedRight = !getMouseRight()&&mouseRight
    ) var mouseRight = false;
    @:builder(react = function (mouseMiddle)
        mouseWasPressedMiddle = !getMouseMiddle()&&mouseMiddle
    ) var mouseMiddle = false;

    /*
     * True if (based on provided state) the mouse button
     * was pressed exactly on this frame (not held)
     */
    public var mouseWasPressedLeft  (default,null) = false;
    public var mouseWasPressedRight (default,null) = false;
    public var mouseWasPressedMiddle(default,null) = false;

    /*
     * List of Mouse elements currently holding focus of
     * mouse buttons (Possibly many if overlapping and not occluded).
     */
    public var focusLeft  (default,null):Array<Mouse>;
    public var focusRight (default,null):Array<Mouse>;
    public var focusMiddle(default,null):Array<Mouse>;

    /*
     * Render a GUI element
     */
    public function render<S,T:Element<S>>(x:T) {
        if (x.getActive()) {
            if (x.internal(getMousePos()) && x.getOccluder()) {
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
        if (renderState == null || !Type.enumEq(renderState, GSText)) {
            flush();
            renderState = GSText;
            textRender.begin();
        }
        return textRender;
    }
}
