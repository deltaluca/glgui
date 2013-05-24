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
import glgui.GLFWGui;
import glgui.PanelButton;

using glgui.Transform;
using glgui.Colour;

class Main {
    static function main () {
        GLFW.init();

        var w = GLFW.createWindow(800, 600, "Main");
        GLFW.makeContextCurrent(w);

        GL.init();
        GL.viewport(0, 0, 800, 600);
        GL.enable(GL.BLEND);
        GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

        var glfw = new GLFWGui(w);
        var gui = new Gui();
        var cache = new Cache();
        var dejavu = new Font("../gl3font/dejavu/sans.dat", "../gl3font/dejavu/sans.png");

        while (!GLFW.windowShouldClose(w)) {
            GL.clear(GL.COLOR_BUFFER_BIT);
            GLFW.pollEvents();
            glfw.updateState(gui);

            var panel = cache.cache("panel",
                new Panel()
                .fit([100,100,600,400])
                .hex(0x40ff0000)
                .radius(100)
                .commit()
            );
            gui.render(panel);

/*            var title = cache.cache("title",
                new Text()
                .font(dejavu)
                .text("Hello World!")
                .size(30)
                .position([400,300])
                .hex(0xff0000)
                .commit()
            );
            gui.render(title);*/

            var mouse = cache.cache("mouse",
                new Mouse()
                .interior(panel.internal)
                .enter(function () trace("enter"))
                .exit(function () trace("exit"))
                .press(function (but) trace("press "+but))
                .release(function (but,over) trace("release "+but+" "+over))
                .scroll(function (delta) trace("scroll "+delta))
            );
            gui.render(mouse);

            var button1 = cache.cache("button1",
                new PanelButton(true)
                .fit([200,200,100,30])
                .radius(10)
                .font(dejavu)
                .text("Test")
                .press(function (enabled) {
                    trace("button1 "+enabled);
                })
                .disabled(true)
                .commit()
            );
            gui.render(button1);

            var button = cache.cache("button",
                new PanelButton()
                .fit([300,200,100,30])
                .radius(10)
                .font(dejavu)
                .text("Test")
                .press(function (enabled) {
                    trace("button1 "+enabled);
                })
                .commit()
            );
            gui.render(button);

            var button2 = cache.cache("button2",
                new PanelButton(true)
                .fit([400,200,100,30])
                .radius(10)
                .font(dejavu)
                .text("Test")
                .press(function (enabled) {
                    trace("button2 "+enabled);
                    button1.disabled(!enabled);
                })
                .commit()
            );
            gui.render(button2);

            var panel2 = cache.cache("panel2",
                new Panel()
                .fit([400,250,200,100])
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
