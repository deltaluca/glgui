package;

import glfw3.GLFW;
import ogl.GL;
import ogl.GLM;
import gl3font.Font;
import gl3font.GLString;
import glgui.Gui;
import glgui.Cache;
import glgui.Text;
import glgui.Panel;
import glgui.Mouse;
import glgui.Image;
import glgui.Scroll;
import glgui.GLFWGui;
import glgui.PanelButton;
import glgui.TextInput;

using glgui.Transform;
using glgui.Colour;

class Main {
    static function main () {
        GLFW.init();

        var w = GLFW.createWindow(800, 600, "Main");
        GLFW.makeContextCurrent(w);

        GL.init();
        GL.disable(GL.SCISSOR_TEST);
        GL.enable(GL.BLEND);
        GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

        var glfw = new GLFWGui(w);
        var gui = new Gui();
        var cache = new Cache();

        var dejavu = new Font("../gl3font/dejavu/sans.dat", "../gl3font/dejavu/sans.png");

        var debug = new nape.util.OGLDebug(800, 600);
        function drawRect(v:goodies.Maybe<Vec4>, col:Int) {
            if (v == null) return;
            var v = v.extract();
            debug.drawAABB(new nape.geom.AABB(v.x, v.y, v.z, v.w), col);
        }

        while (!GLFW.windowShouldClose(w)) {
            debug.clear();
            GL.clear(GL.COLOR_BUFFER_BIT);
            GLFW.pollEvents();
            var size = GLFW.getWindowSize(w);
            GL.viewport(0, 0, size.width, size.height);
            glfw.updateState(gui);

//            var image = cache.cache("image",
//                Image.fromPNG("background01.png")
//                .fit([0,0,800,600])
//               .commit()
//            );
//            gui.render(image);
//
//            var text = cache.cache("text",
//                new Text()
//                    .fit([150,150,100,100])
//                    .text(GLString.make("Hello", [1,1,1,1]) + GLString.make(" World", [1,0,1,1]))
//                    .font(dejavu)
//                    .commit()
//            );
//            gui.render(text);
//
//            //gui.render(open);
//            var save = cache.cache("save",
//                new PanelButton(true)
//                .fit([50,50,150,120])
//                .radius(25)
//                .thickness(20)
//                .font(dejavu)
//                .text(GLString.make("Save", [1,1,1,1]))
//                .disabledText(GLString.make("Save", [1,0,1,1]))
//                .press(function (enabled) {
//                    trace("save "+enabled);
//                })
//                .disabled(false)
//                .commit()
//            );
//            gui.render(save);
//            drawRect(image.bounds(), 0xff0000);
//
//            var panel = cache.cache("panel",
//                new Panel()
//                .fit([100,100,600,400])
//                .hex(0x40ff0000)
//                .radius(100)
//                .commit()
//            );
//            var scroll = cache.cache("scroll",
//                new Scroll()
//                .fit([300,200,100,100])
//                .element(panel)
//                .commit()
//            );
//            var mouseX = GLFW.getCursorPos(w).x;
//            var mouseY = GLFW.getCursorPos(w).y;
//            scroll.scroll(Mat3x2.translate(-mouseX, -mouseY));
//            gui.render(scroll);

//
//            var mouse = cache.cache("mouse",
//                new Mouse()
//                .interior(image.internal)
////                .enter(function () trace("enter"))
////                .exit(function () trace("exit"))
//                .press(function (pos, but) {
////                    trace("press "+but);
//                    trace(title.pointIndex(GLFW.getCursorPos(w)));
//                })
////                .release(function (but,over) trace("release "+but+" "+over))
////                .scroll(function (delta) trace("scroll "+delta))
////                .character(function (chars) trace("chars "+chars))
////                .key(function (keys) trace("keys "+keys))
//            );
//            gui.render(mouse);
//
//            var button1 = cache.cache("button1",
//                new PanelButton(true)
//                .fit([200,200,200,80])
//                .radius(20)
//                .font(dejavu)
//                .text("Test")
//                .press(function (enabled) {
//                    trace("button1 "+enabled);
//                })
//                .disabled(false)
//                .commit()
//            );
//            gui.render(button1);
//            drawRect(button1.bounds(), 0xff0000);
////
////            var button = cache.cache("button",
////                new PanelButton()
////                .fit([300,200,100,30])
////                .radius(0)
////                .font(dejavu)
////                .text("Test")
////                .press(function (enabled) {
////                    trace("button1 "+enabled);
////                })
////                .commit()
////            );
////            gui.render(button);
////
////            var button2 = cache.cache("button2",
////                new PanelButton(true)
////                .fit([400,200,100,30])
////                .radius(10)
////                .font(dejavu)
////                .text("Test")
////                .press(function (enabled) {
////                    trace("button2 "+enabled);
////                    button1.disabled(!enabled);
////                })
////                .commit()
////            );
////            gui.render(button2);
////
////            var panel2 = cache.cache("panel2",
////                new Panel()
////                .fit([400,250,200,100])
////                .hex(0x4000ff00)
////                .radius(50)
////                .commit()
////            );
////            gui.render(panel2);*/
////
////            var panel2 = cache.cache("panel2",
////                new Panel()
////                .fit([100-3,100-3,200+6,90+6])
////                .hex(0xffffff)
////                .radius(2)
////                .commit()
////            );
////            gui.render(panel2);
////
            var t:GLString = GLString.make("cwd=..", [1,1,1,1]);
            t += "\n   ";
            t += "hello";
            t += "\n   ";
            t += "hiya";
            var input = cache.cache("input", new TextInput()
                .fileInput(true)
                .font(dejavu)
                .size(20)
                .hex(0xffffff)
                .fit([0,0,550,400])
                .text(t)
//                .text(GLString.make("AB\nCD\nEF", [1,1,1,1]))
                .multiline(true)
//                .allowed(~/[0-9.\-]/)
                .commit()
            );
            gui.render(input);
//
//            var panel3 = cache.cache("panel3",
//                new Panel()
//                .fit([400-3,100-3,200+6,90+6])
//                .hex(0xffffff)
//                .radius(5)
//                .commit()
//            );
//            gui.render(panel3);
//            drawRect(panel3.bounds(), 0xff0000);
////
////            var input2 = cache.cache("input2", new TextInput()
////                .font(dejavu)
////                .size(20)
////                .hex(0)
////                .fit([400,100,200,90])
////                .text("120")
////                .multiline(true)
//////                .maxChars(8)
//////                .allowed(~/[0-9.\-]/)
////                .commit()
////            );
////            gui.render(input2);
////            drawRect(input2.bounds(), 0xff0000);

            gui.flush();
            debug.flush();

            GLFW.swapBuffers(w);
        }

        GLFW.destroyWindow(w);
        GLFW.terminate();
    }
}
