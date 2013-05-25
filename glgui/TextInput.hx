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
    public function new() {
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
                commit();
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
        scroll.fit(getFit()).commit();
        return this;
    }

    // Element
    public function render(gui:Gui, mousePos:Maybe<Vec2>, xform:Mat3x2) {
        scroll.render(gui, null, xform);
        mouse.render(gui, mousePos, xform);
    }
}
