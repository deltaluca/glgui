package glgui;

import glgui.Gui;
import ogl.GLM;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;
import glgui.Scroll;
import glgui.Text;
import gl3font.Font;

class TextInput implements Element<TextInput> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    @:builder var occluder = false;

    // TextInput
    @:builder var maxChars = -1;
    @:builder var allowed:Maybe<EReg> = null;
    @:builder var multiline = false;

    // Text
    @:builder var colour:Vec4 = [1.0,1.0,1.0,1.0];
    @:builder @:lazyVar var font:Font;
    @:builder var halign = TextAlignLeft;
    @:builder var valign = TextAlignTop;
    @:builder var justified = false;
    @:builder var size = 0.0;
    @:builder var text:String = "";

    var pointer:Int = 0;

    var textarea:Text;
    var scroll:Scroll<Text>;
    var mouse:Mouse;
    var hasFocus:Bool;

    static var linefont:Font;
    static var buffer:StringBuffer;
    public function new() {
        if (linefont == null) {
            linefont = new Font(null, "line.distance.png");
            buffer = new StringBuffer(linefont);
            buffer.reserve(6);
        }

        textarea = new Text();
        scroll = new Scroll();
        scroll.element(textarea);
        mouse = new Mouse()
            .interior(function (x:Vec2) {
                var fit = getFit();
                var ret = x.x >= fit.x && x.y >= fit.y && x.x <= fit.x + fit.z && x.y <= fit.y + fit.w;
                return ret;
            })
            .press(function (x:Maybe<Vec2>, but) {
                if (x == null) return;
                var x = x.extract();
                pointer = textarea.pointIndex(x).char;
            })
            .character(function (chars) {
                for (c in chars) {
                    if (getText().length == getMaxChars()) break;
                    if (getAllowed().runOr(function (a) return a.match(String.fromCharCode(c)), true)) {
                        text(getText().substr(0, pointer) + String.fromCharCode(c) + getText().substr(pointer));
                        pointer++;
                    }
                }
            })
            .focus(function () {
                hasFocus = true;
            })
            .key(function (keys) {
                for (k in keys) {
                    switch (k.state) {
                    case KSPress | KSDelayedHold:
                        if (k.key == KeyCode.LEFT) {
                            var np = pointer-1; if (np < 0) np = 0;
                            if (textarea.toPosition(np).line ==
                                textarea.toPosition(pointer).line)
                                pointer = np;
                        }
                        else if (k.key == KeyCode.RIGHT) {
                            var np = pointer+1;
                            if (np > getText().length)
                                np = getText().length;
                            if (textarea.toPosition(np).line ==
                                textarea.toPosition(pointer).line)
                                pointer = np;
                        }
                        else if (k.key == KeyCode.UP) {
                            var p = textarea.toPosition(pointer);
                            if (p.line > 0) {
                                p.line--;
                                pointer = textarea.clamp(p).char;
                            }
                        }
                        else if (k.key == KeyCode.DOWN) {
                            var p = textarea.toPosition(pointer);
                            if (p.line < textarea.textLayout.lines.length-1) {
                                p.line++;
                                pointer = textarea.clamp(p).char;
                            }
                        }

                        else if (k.key == KeyCode.HOME) {
                            pointer = textarea.toLineStart(textarea.toPosition(pointer)).char;
                        }
                        else if (k.key == KeyCode.END)  {
                            pointer = textarea.toLineEnd(textarea.toPosition(pointer)).char;
                        }
                        else if (k.key == KeyCode.PAGE_UP) {
                            var p = textarea.toPosition(pointer);
                            p.line -= 20;
                            pointer = textarea.clamp(p).char;
                        }
                        else if (k.key == KeyCode.PAGE_DOWN) {
                            var p = textarea.toPosition(pointer);
                            p.line += 20;
                            pointer = textarea.clamp(p).char;
                        }

                        else if (k.key == KeyCode.ENTER) {
                            if (getMultiline()) {
                                if (getText().length != getMaxChars()) {
                                    text(getText().substr(0,pointer) + "\n" + getText().substr(pointer));
                                    pointer++;
                                }
                            }
                        }

                        else if (k.key == KeyCode.DELETE) {
                            text(getText().substr(0, pointer) + getText().substr(pointer+1));
                        }
                        else if (k.key == KeyCode.BACKSPACE) {
                            if (pointer != 0) {
                                text(getText().substr(0, pointer-1) + getText().substr(pointer));
                                pointer--;
                            }
                        }
                    default:
                    }
                }
            });
    }

    // Element
    public function destroy() {
        textarea.destroy();
        scroll.destroy();
        mouse.destroy();
    }

    // Element
    public function bounds():Maybe<Vec4> {
        return scroll.bounds();
    }

    // Element
    public function internal(x:Vec2) {
        return scroll.internal(x);
    }

    // Element
    public var scrollX:Float = 0;
    public var scrollY:Float = 0;
    public function commit() {
        textarea.colour(getColour())
                .font(getFont())
                .halign(getHalign())
                .valign(getValign())
                .justified(getJustified())
                .size(getSize())
                .text(getText())
                .commit();
        mouse.fit(getFit()).commit();
        scroll
            .fit(getFit())
            .scroll(Mat3x2.translate(2+scrollX,2+scrollY))
            .commit();
        return this;
    }

    // Element
    public function render(gui:Gui, mousePos:Maybe<Vec2>, xform:Mat3x2) {
        commit();
        scroll.render(gui, null, xform);
        scroll.suplRender(gui, xform, function (xform) {
            var pos = textarea.toPhysical(textarea.toPosition(pointer));

            var transform:Mat4 = textarea.transform;
            var height1:Vec4 = [0, -textarea.getFont().info.extract().ascender, 0,0];
            var height2:Vec4 = [0, -textarea.getFont().info.extract().descender, 0,0];
            height1 = transform * height1;
            height2 = transform * height2;
            var c1:Vec2 = [height1.x, height1.y];
            var c2:Vec2 = [height2.x, height2.y];
            c1 += pos;
            c2 += pos;
            c1.x += scrollX;
            c2.x += scrollX;

            if (Math.cos(gui.getTime()*5)<0.5 && hasFocus) {
                buffer.clear();
                var d = StringBuffer.VERTEX_SIZE;
                var index = buffer.reserve(6)-d;

                buffer.vertex(index+=d, c1.x-3-scrollX,c1.y, 0,0);
                buffer.vertex(index+=d, c2.x-3-scrollX,c2.y, 0,0);
                buffer.vertex(index+=d, c2.x+3-scrollX,c2.y, 1,0);

                buffer.vertex(index+=d, c1.x-3-scrollX,c1.y, 0,0);
                buffer.vertex(index+=d, c2.x+3-scrollX,c2.y, 1,0);
                buffer.vertex(index+=d, c1.x+3-scrollX,c1.y, 1,0);

                gui.textRenderer()
                    .setColour([0,0,0,1])
                    .setTransform(xform)
                    .render(buffer);
            }

            if (pos.x+scrollX < -2) scrollX = -2-pos.x;
            if (scrollX > 0) scrollX = 0;
            if (pos.x+scrollX+2 > getFit().z-4) scrollX = getFit().z-6-pos.x;

            if (c1.y+scrollY < -2) scrollY = -2-c1.y;
            if (scrollY > 0) scrollY = 0;
            if (c2.y+scrollY+2 > getFit().w-4) scrollY = getFit().w-6-c2.y;
        });
        mouse.render(gui, mousePos, xform);
        hasFocus = false;
    }
}
