package;

import glfw3.GLFW;
import ogl.GL;
import ogl.GLM;
import gl3font.Font;
import glgui.Gui;
import glgui.Cache;
import glgui.Text;
import glgui.Panel;
import glgui.Mouse;

using glgui.Transform;
using glgui.Colour;

class Main {
    static function main () {
        GLFW.init();
        GLFW.windowHint(GLFW.SAMPLES, 8);
        var w = GLFW.createWindow(800, 600, "Main");
        GLFW.makeContextCurrent(w);
        GL.init();

        GL.viewport(0, 0, 800, 600);
        GL.enable(GL.BLEND);
        GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

        var pos = GLFW.getCursorPos(w);
        var outsideScreen = pos.x < 0 || pos.y < 0 || pos.x >= 800 || pos.y >= 600;
        var scroll:Float = 0;
        GLFW.setCursorEnterCallback(w, function (_,entered) {
            outsideScreen = !entered;
        });
        GLFW.setScrollCallback(w, function(_,_, y:Float) {
            scroll += y;
        });

        var gui = new Gui().projection(Mat3x2.viewportMap(800, 600));
        var cache = new Cache();
        var dejavu = new Font("../gl3font/dejavu/sans.dat", "../gl3font/dejavu/sans.png");
        while (!GLFW.windowShouldClose(w)) {
            scroll = 0;
            GLFW.pollEvents();

            GL.clear(GL.COLOR_BUFFER_BIT);
            gui.mouseLeft  (GLFW.getMouseButton(w, GLFW.MOUSE_BUTTON_LEFT))
               .mouseRight (GLFW.getMouseButton(w, GLFW.MOUSE_BUTTON_RIGHT))
               .mouseMiddle(GLFW.getMouseButton(w, GLFW.MOUSE_BUTTON_MIDDLE))
               .mousePos(if (outsideScreen) null else GLFW.getCursorPos(w))
               .mouseScroll(scroll);

            var panel = cache.cache("panel",
                new Panel()
                .fit([100,100,600,400])
                .hex(0x40ff0000)
                .radius(100)
                .commit()
            );
            gui.render(panel);

            var title = cache.cache("title",
                new Text()
                .font(dejavu)
                .text("Hello World!")
                .size(30)
                .position([400,300])
                .hex(0xff0000)
                .commit()
            );
            gui.render(title);

            var mouse = cache.cache("mouse",
                new Mouse()
                .interior(panel.internal)
                .enter(function () trace("enter"))
                .exit(function () trace("exit"))
                .press(function (but) trace("press "+but))
                .release(function (but) trace("release "+but))
                .scroll(function (delta) trace("scroll "+delta))
            );
            gui.render(mouse);

            var panel2 = cache.cache("panel2",
                new Panel()
                .fit([300,250,200,100])
                .hex(0x4000ff00)
                .radius(50)
                .commit()
            );
            gui.render(panel2);


            gui.flush();
            GLFW.swapBuffers(w);
        }

        GLFW.destroyWindow(w);
        GLFW.terminate();
    }
}
