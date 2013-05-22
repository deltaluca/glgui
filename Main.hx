package;

import glfw3.GLFW;
import ogl.GL;
import ogl.GLM;
import gl3font.Font;
import glgui.Gui;
import glgui.Cache;
import glgui.Text;

using glgui.Transform;

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

        var gui = new Gui(800, 600);
        var cache = new Cache();
        var dejavu = new Font("../gl3font/dejavu/sans.dat", "../gl3font/dejavu/sans.png");

        while (!GLFW.windowShouldClose(w)) {
            GLFW.pollEvents();

            GL.clear(GL.COLOR_BUFFER_BIT);

            var title = cache.cache("title",
                new Text()
                .font(dejavu)
                .text("Hello World!")
                .size(30)
                .position([400,300])
                .commit()
            );

            gui.render(title);
            gui.flush();

            GLFW.swapBuffers(w);
        }

        GLFW.destroyWindow(w);
        GLFW.terminate();
    }
}
