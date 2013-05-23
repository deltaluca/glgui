package glgui;

#if glfw3

import glfw3.GLFW;
import glgui.Gui;
import ogl.GLM;

class GLFWGui {

    public var window   (default,null):Window;
    public var mouseOver(default,null):Bool;

    var proj:Mat3x2;
    var scroll:Float;

    public function new(w:Window) {
        window = w;
        var pos  = GLFW.getWindowPos(w);
        var size = GLFW.getWindowSize(w);
        var xy   = GLFW.getCursorPos(w);
        mouseOver = xy.x >= pos.x
                 && xy.y >= pos.y
                 && xy.x < pos.x+size.width
                 && xy.y < pos.y+size.height;
        scroll = 0;
        proj = Mat3x2.viewportMap(size.width, size.height);
        GLFW.setCursorEnterCallback(window, enterCallback);
        GLFW.setScrollCallback(window, scrollCallback);
    }

    function enterCallback(_, entered) {
        mouseOver = entered;
    }
    function scrollCallback(_,_, y:Float) {
        scroll += y;
    }

    public function updateState(gui:Gui) {
        gui.projection(proj)
           .mouseLeft  (GLFW.getMouseButton(window, GLFW.MOUSE_BUTTON_LEFT))
           .mouseRight (GLFW.getMouseButton(window, GLFW.MOUSE_BUTTON_RIGHT))
           .mouseMiddle(GLFW.getMouseButton(window, GLFW.MOUSE_BUTTON_MIDDLE))
           .mousePos(if (mouseOver) GLFW.getCursorPos(window) else null)
           .mouseScroll(scroll);
        scroll = 0;
    }
}

#end
