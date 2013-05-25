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

    var keysPressed:Array<{key:Int,state:KeyState}>;
    var charsPressed:Array<Int>;

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

        GLFW.setKeyCallback (window, keyCallback);
        GLFW.setCharCallback(window, charCallback);
        keysPressed = [];
        charsPressed = [];
    }

    function enterCallback(_, entered) {
        mouseOver = entered;
    }
    function scrollCallback(_,_, y:Float) {
        scroll += y;
    }
    function keyCallback(_, key:Int, state:Int, _) {
        if (state != GLFW.RELEASE) {
            if (key == GLFW.KEY_TAB)
                charsPressed.push('\t'.code);
        }

        if (state == GLFW.PRESS)
            keysPressed.push({key:key,state:KSPress});
        else if (state == GLFW.REPEAT) {
            for (k in keysPressed) {
                if (k.key == key) {
                    k.state = KSDelayedHold;
                    break;
                }
            }
        }
        else if (state == GLFW.RELEASE) {
            for (k in keysPressed) {
                if (k.key == key) {
                    k.state = KSRelease;
                    break;
                }
            }
        }
    }
    function charCallback(_, char:Int) {
        charsPressed.push(char);
    }

    public function updateState(gui:Gui) {
        gui.projection(proj)
           .time(GLFW.getTime())
           .mouseLeft  (GLFW.getMouseButton(window, GLFW.MOUSE_BUTTON_LEFT))
           .mouseRight (GLFW.getMouseButton(window, GLFW.MOUSE_BUTTON_RIGHT))
           .mouseMiddle(GLFW.getMouseButton(window, GLFW.MOUSE_BUTTON_MIDDLE))
           .mousePos(if (mouseOver) GLFW.getCursorPos(window) else null)
           .mouseScroll(scroll)
           .keysPressed(keysPressed.copy())
           .charsPressed(charsPressed.copy());
        scroll = 0;
        charsPressed = [];
        for (k in keysPressed) {
            if (k.state == KSPress)
                keysPressed.push({key:k.key, state:KSHold});
        }
        keysPressed = keysPressed.filter(function (k) return switch (k.state) {
            case KSHold | KSDelayedHold: true;
            default: false;
        });
    }
}

#end
