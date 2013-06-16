package glgui;

import glgui.Gui;
import ogl.GLM;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;
import glgui.Scroll;
import glgui.Text;
import gl3font.Font;
import gl3font.GLString;
import #if cpp cpp #else neko #end.vm.Tls;

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
    @:builder var colour:Vec4 = [1,1,1,1]; // colour for inserted text!
    @:builder @:lazyVar var font:Font;
    @:builder var size = 0.0;
    @:builder var text:GLString = "";

    @:builder var fileInput = false;

    var pointer:Int = 0;

    var textarea:Text;
    var scroll:Scroll<Text>;
    var mouse:Mouse;
    var hasFocus:Bool;

    var inv:Bool = true;

    @:builder var matches:Maybe<Array<String>->Void> = null;

    function tabComplete(inp:GLString) {
        inv = true;
        var x = inp;
        if (x.charCodeAt(0) == '~'.code) {
            if (x.length == 1) {
                x = Sys.getEnv("HOME");
                x = x.normalise(inp.colourAt(0));
            }
            else
                x = Sys.getEnv("HOME") + x.substr(1);
        }
        if (x.length == 0 || (x.charCodeAt(0) != '/'.code && x.charCodeAt(0) != '.'.code)) {
            if (x.length == 0) x = GLString.make("./", getColour());
            else x = "./" + x;
        }
        var pre = x.substr(0,x.lastIndexOf('/'));
        if (sys.FileSystem.isDirectory(pre.toString())) {
            var dir = sys.FileSystem.readDirectory(pre.toString());
            var matches = dir.filter(function (y) {
                return (pre + "/" + y).substr(0,x.length) == x;
            });
            if (matches.length == 1) {
                x = pre + "/" + matches[0];
                if (sys.FileSystem.isDirectory(x.toString())) x += "/";
                getMatches().call1([x.toString()]);
            }else {
                var cnt = 0;
                for (i in 0...100000) {
                    var z = matches[0].charCodeAt(i);
                    for (j in 1...matches.length) {
                        if (matches[j].charCodeAt(i) != z) {
                            z = null;
                            break;
                        }
                    }
                    if (z == null) break;
                    cnt++;
                }
                x = pre + "/" + matches[0].substr(0,cnt);
                getMatches().call1(matches);
            }
        }else {
            if (sys.FileSystem.exists(inp.toString()))
                getMatches().call1([inp.toString()])
            else
                getMatches().call1([]);
        }
        if (x.length < inp.length) return inp;
        pointer = x.length;
        return x;
    }

    @:lazyVar static var linefont:Tls<Font> = new Tls<Font>();
    @:lazyVar static var buffer:Tls<StringBuffer> = new Tls<StringBuffer>();
    public function new() {
        if (linefont.value == null) {
            linefont.value = new Font(null, "line.distance.png");
            buffer.value = new StringBuffer(linefont.value);
            buffer.value.reserve(6);
        }

        textarea = new Text()
            .halign(TextAlignLeft)
            .valign(TextAlignTop)
            .justified(false);
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
                var x = lastTransform * x.extract();
                pointer = textarea.pointIndex(x).char;
                inv = true;
            })
            .character(function (chars) {
                var t = getText();
                for (c in chars) {
                    if (c == '\t'.code && getFileInput()) {
                        inv = true;
                        text(t = tabComplete(t));
                    }
                    else if (c == '\t'.code) {
                            inv = true;
                            text(t = t.substr(0,pointer)
                                   + GLString.make("    ",getColour())
                                   + t.substr(pointer));
                            pointer+=4;
                    }else {
                        if (t.length == getMaxChars()) break;
                        if (getAllowed().runOr(function (a) return a.match(String.fromCharCode(c)), true)) {
                            inv = true;
                            text(t = t.substr(0,pointer)
                                   + GLString.make(String.fromCharCode(c),getColour())
                                   + t.substr(pointer));
                            pointer++;
                        }
                    }
                }
            })
            .focus(function () {
                hasFocus = true;
            })
            .key(function (keys) {
                var t = getText();
                for (k in keys) {
                    switch (k.state) {
                    case KSPress | KSDelayedHold:
                        if (k.key == KeyCode.LEFT) {
                            var np = pointer-1; if (np < 0) np = 0;
                            if (textarea.toPosition(np).line ==
                                textarea.toPosition(pointer).line) {
                                pointer = np;
                                inv = true;
                            }
                        }
                        else if (k.key == KeyCode.RIGHT) {
                            var np = pointer+1;
                            if (np > t.length)
                                np = t.length;
                            if (textarea.toPosition(np).line ==
                                textarea.toPosition(pointer).line) {
                                pointer = np;
                                inv = true;
                            }
                        }
                        else if (k.key == KeyCode.UP) {
                            var p = textarea.toPosition(pointer);
                            if (p.line > 0) {
                                p.line--;
                                pointer = textarea.clamp(p).char;
                                inv = true;
                            }
                        }
                        else if (k.key == KeyCode.DOWN) {
                            var p = textarea.toPosition(pointer);
                            if (p.line < textarea.textLayout.lines.length-1) {
                                p.line++;
                                pointer = textarea.clamp(p).char;
                                inv = true;
                            }
                        }

                        else if (k.key == KeyCode.HOME) {
                            pointer = textarea.toLineStart(textarea.toPosition(pointer)).char;
                            inv = true;
                        }
                        else if (k.key == KeyCode.END)  {
                            pointer = textarea.toLineEnd(textarea.toPosition(pointer)).char;
                            inv = true;
                        }
                        else if (k.key == KeyCode.PAGE_UP) {
                            var p = textarea.toPosition(pointer);
                            p.line -= 20;
                            pointer = textarea.clamp(p).char;
                            inv = true;
                        }
                        else if (k.key == KeyCode.PAGE_DOWN) {
                            var p = textarea.toPosition(pointer);
                            p.line += 20;
                            pointer = textarea.clamp(p).char;
                            inv = true;
                        }

                        else if (k.key == KeyCode.ENTER) {
                            if (getMultiline()) {
                                if (t.length != getMaxChars()) {
                                    text(t = t.substr(0,pointer) + "\n" + t.substr(pointer));
                                    pointer++;
                                    inv = true;
                                }
                            }
                        }

                        else if (k.key == KeyCode.DELETE) {
                            text(t = t.substr(0,pointer) + t.substr(pointer+1));
                            inv = true;
                        }
                        else if (k.key == KeyCode.BACKSPACE) {
                            if (pointer != 0) {
                                text(t = t.substr(0,pointer-1)+t.substr(pointer));
                                pointer--;
                                inv = true;
                            }
                        }
                    default:
                    }
                }
            });
    }

    public function gotoEnd() {
        pointer = getText().length;
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
        textarea.font(getFont())
                .size(getSize())
                .text(getText())
                .commit();
        mouse.fit(getFit()).commit();
        scroll
            .fit(getFit())
            .scroll([3+scrollX, 3+scrollY])
            .commit();
        inv = false;
        return this;
    }

    // Element
    var lastTransform:Mat3x2;
    public function render(gui:Gui, mousePos:Maybe<Vec2>, proj:Mat3x2, xform:Mat3x2) {
        if (inv) {
            inv = false;
            commit();
        }
        scroll.render(gui, null, proj, xform);
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
                var buffer = buffer.value;
                buffer.clear();
                var d = StringBuffer.VERTEX_SIZE;
                var index = buffer.reserve(6)-d;

                var col:Vec4 = getColour();
                buffer.vertex(index+=d, c1.x-3-scrollX,c1.y, 0,0, col);
                buffer.vertex(index+=d, c2.x-3-scrollX,c2.y, 0,0, col);
                buffer.vertex(index+=d, c2.x+3-scrollX,c2.y, 1,0, col);

                buffer.vertex(index+=d, c1.x-3-scrollX,c1.y, 0,0, col);
                buffer.vertex(index+=d, c2.x+3-scrollX,c2.y, 1,0, col);
                buffer.vertex(index+=d, c1.x+3-scrollX,c1.y, 1,0, col);

                gui.textRenderer()
                    .setTransform(proj * xform)
                    .render(buffer);
            }

            if (pos.x+scrollX < -2) scrollX = -2-pos.x;
            if (scrollX > 0) scrollX = 0;
            if (pos.x+scrollX+2 > getFit().z-4) scrollX = getFit().z-6-pos.x;

            if (c1.y+scrollY < -2) scrollY = -2-c1.y;
            if (scrollY > 0) scrollY = 0;
            if (c2.y+scrollY+2 > getFit().w-4) scrollY = getFit().w-6-c2.y;
        });
        lastTransform = xform;
        mouse.render(gui, mousePos, proj, xform);
        hasFocus = false;
        if (mousePos.runOr(internal, false) && getOccluder()) gui.occludes();
    }
}
