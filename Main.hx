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
import glgui.Group;
import glgui.GLFWGui;
import glgui.PanelButton;
import glgui.TextInput;

using glgui.Transform;
using glgui.Colour;

class Main {
    static function main () {
        GLFW.init();

        GLFW.windowHint(GLFW.SAMPLES, 16);
        var w = GLFW.createWindow(550, 400, "Main");
        GLFW.makeContextCurrent(w);

        GL.init();
        GL.disable(GL.SCISSOR_TEST);
        GL.enable(GL.BLEND);
        GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

        var glfw = new GLFWGui(w);
        var gui = new Gui();
        var cache = new Cache();

        var dejavu = new Font("../gl3font/dejavu/sans.dat", "../gl3font/dejavu/sans.png");

        var debug = new nape.util.OGLDebug(550, 400);
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

            // Image test
            var image = cache.cache("image",
                Image.fromPNG("background01.png")
                .fit([0,0,200,100])
                .commit()
            );
            gui.render(image);

            // Text text
            var text1 = cache.cache("text1",
                new Text()
                .text(GLString.make("Hello!\n", [1,1,1,1]) +
                      GLString.make("Der", [1,0,0,1]))
                .font(dejavu)
                .size(15)
                .halign(TextAlignLeft)
                .valign(TextAlignTop)
                .spacing(1/dejavu.info.extract().height)
                .position([50,100])
                .commit()
            );
            gui.render(text1);
            var text2 = cache.cache("text2",
                new Text()
                .text(GLString.make("Hello!\n", [1,1,1,1]) +
                      GLString.make("Der", [1,0,0,1]))
                .font(dejavu)
                .size(15)
                .halign(TextAlignRight)
                .valign(TextAlignTop)
                .spacing(1/dejavu.info.extract().height)
                .position([50,130])
                .commit()
            );
            gui.render(text2);
            var text3 = cache.cache("text3",
                new Text()
                .text(GLString.make("Hello!\n", [1,1,1,1]) +
                      GLString.make("Der", [1,0,0,1]))
                .font(dejavu)
                .size(15)
                .halign(TextAlignCentre)
                .valign(TextAlignTop)
                .spacing(1/dejavu.info.extract().height)
                .position([50,160])
                .commit()
            );
            gui.render(text3);
            var text1j = cache.cache("text1j",
                new Text()
                .text(GLString.make("Hello!\n", [1,1,1,1]) +
                      GLString.make("Der", [1,0,0,1]))
                .font(dejavu)
                .size(15)
                .halign(TextAlignLeft)
                .valign(TextAlignTop)
                .justified(true)
                .spacing(1/dejavu.info.extract().height)
                .position([50,190])
                .commit()
            );
            gui.render(text1j);
            var text2j = cache.cache("text2j",
                new Text()
                .text(GLString.make("Hello!\n", [1,1,1,1]) +
                      GLString.make("Der", [1,0,0,1]))
                .font(dejavu)
                .size(15)
                .halign(TextAlignRight)
                .valign(TextAlignTop)
                .justified(true)
                .spacing(1/dejavu.info.extract().height)
                .position([50,210])
                .commit()
            );
            gui.render(text2j);
            var text3j = cache.cache("text3j",
                new Text()
                .text(GLString.make("Hello!\n", [1,1,1,1]) +
                      GLString.make("Der", [1,0,0,1]))
                .font(dejavu)
                .size(15)
                .halign(TextAlignCentre)
                .valign(TextAlignTop)
                .justified(true)
                .spacing(1/dejavu.info.extract().height)
                .position([50,240])
                .commit()
            );
            gui.render(text3j);
            drawRect([50,100,0.5,165],0xff0000);
            var text1v = cache.cache("text1v",
                new Text()
                .text(GLString.make("Goodbye", [1,1,1,1]))
                .font(dejavu)
                .halign(TextAlignLeft)
                .valign(TextAlignTop)
                .fit([100,100,50,55])
                .commit()
            );
            drawRect([100,100,50,55],0xff0000);
            gui.render(text1v);
            var text2v = cache.cache("text2v",
                new Text()
                .text(GLString.make("Goodbye", [1,1,1,1]))
                .font(dejavu)
                .halign(TextAlignLeft)
                .valign(TextAlignCentre)
                .fit([100,155,50,55])
                .commit()
            );
            drawRect([100,155,50,55],0xff0000);
            gui.render(text2v);
            var text3v = cache.cache("text3v",
                new Text()
                .text(GLString.make("Goodbye", [1,1,1,1]))
                .font(dejavu)
                .halign(TextAlignLeft)
                .valign(TextAlignBottom)
                .fit([100,210,50,55])
                .commit()
            );
            drawRect([100,210,50,55],0xff0000);
            gui.render(text3v);

            // Panel test
            var panel = cache.cache("panel",
                new Panel()
                .hex(0x40ffff00)
                .fit([0,265,200,135])
                .radius(50)
                .commit()
            );
            gui.render(panel);
            var panel2 = cache.cache("panel2",
                new Panel()
                .hex(0x80ff00ff)
                .fit([50,265,100,135])
                .radius(0)
                .commit()
            );
            gui.render(panel2);

            // Mouse test
            var playing = false;
            var mouse = cache.cache("mouse",
                new Mouse()
                .interior(function (x:Vec2) {
                    return x.x > 200 && x.x < 300 && x.y > 0 && x.y < 100;
                })
                .enter(function () {
                    playing = true;
                })
                .exit(function () {
                    playing = false;
                })
                .over(function (pos) {
                    var pos = pos.extract();
                    var pv = new nape.geom.Vec2(pos.x,pos.y);
                    debug.drawCircle(pv, 3, 0xffffff);
                })
                .press(function (pos, but) {
                    var pos = pos.extract();
                    var pv = new nape.geom.Vec2(pos.x,pos.y);
                    switch (but) {
                    case MouseLeft:
                        debug.drawCircle(pv, 21, 0xff0000);
                    case MouseMiddle:
                        debug.drawCircle(pv, 9, 0xff00);
                    case MouseRight:
                        debug.drawCircle(pv, 15, 0xff);
                    }
                })
                .release(function (pos, but, elt) {
                    if (pos == null) return;
                    var pos = pos.extract();
                    var pv = new nape.geom.Vec2(pos.x,pos.y);
                    switch (but) {
                    case MouseLeft:
                        debug.drawFilledCircle(pv, elt?21:10.5, 0xff0000);
                    case MouseMiddle:
                        debug.drawFilledCircle(pv, elt?9:4.5, 0xff00);
                    case MouseRight:
                        debug.drawFilledCircle(pv, elt?15:7.5, 0xff);
                    }
                })
                .scroll(function (cnt) {
                    debug.drawFilledCircle(new nape.geom.Vec2(250, 50), Math.abs(cnt)*10, cnt > 0 ? 0xff00ff : 0xffff00);
                })
                .character(function (chars) {
                    for (char in chars)
                        debug.drawFilledCircle(new nape.geom.Vec2(200, 50), char/4, 0xffffff);
                })
                .key(function (keys) {
                    for (key in keys)
                        debug.drawFilledCircle(new nape.geom.Vec2(300, 50), key.key/10, switch (key.state) {
                            case KSPress: 0xff0000;
                            case KSHold: 0xffff00;
                            case KSDelayedHold: 0xff00;
                            case KSRelease: 0xffff;
                        });
                })
                .commit()
            );
            gui.render(mouse);

            // TextInput
            var input = cache.cache("input",
                new TextInput()
                .font(dejavu)
                .size(15)
                .multiline(true)
                .allowed(~/[a-zA-z0-9]/)
                .maxChars(40)
                .fit([300,0,125,100])
                .text(GLString.make("input", [1,1,1,1]))
                .colour([1,0,0,1])
                .commit()
            );
            gui.render(input);
            var input2 = cache.cache("input2",
                new TextInput()
                .fileInput(true)
                .font(dejavu)
                .size(15)
                .multiline(false)
                .fit([425,0,125,100])
                .text(GLString.make("file-input", [0,1,1,1]))
                .colour([1,1,0,1])
                .commit()
            );
            gui.render(input2);

            // Buttons
            var but1 = cache.cache("but1",
                new PanelButton(true)
                .font(dejavu)
                .text(GLString.make(":D", [1,1,1,1]))
                .disabledText(GLString.make("):", [1,1,1,0.5]))
                .fit([200,100,50,50])
                .commit()
            );
            gui.render(but1);
            var but2 = cache.cache("but2",
                new PanelButton(false)
                .font(dejavu)
                .radius(15)
                .text(GLString.make("Press", [1,1,1,1]))
                .fit([250,100,50,50])
                .press(function (_) {
                    but1.toggled(!but1.getToggled());
                })
                .commit()
            );
            gui.render(but2);

            // Group
            var group = cache.cache("group",
                new Group()
                .element(but1)
                .element(but2)
                .position([0,50])
                .commit()
            );
            gui.render(group);

            // Scroll
            var scroll = cache.cache("scroll",
                new Scroll()
                .fit([225,200,50,50])
                .scroll([-25-200,-150])
                .element(group)
                .commit()
            );
            gui.render(scroll);

            var scroll2 = cache.cache("scroll2",
                new Scroll()
                .fit([200,250,350,150])
                .element(Image.fromPNG("background01.png").fit([0,0,1400,600]))
                .hscroll(true)
                .vscroll(true)
                .commit()
            );
            gui.render(scroll2);

            gui.flush();
            debug.flush();

            GLFW.swapBuffers(w);
        }

        GLFW.destroyWindow(w);
        GLFW.terminate();
    }
}
