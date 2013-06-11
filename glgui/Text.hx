package glgui;

import ogl.GLM;
import gl3font.Font;
import gl3font.GLString;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;

enum TextAlign {
    TextAlignLeft;
    TextAlignTop;
    TextAlignRight;
    TextAlignBottom;
    TextAlignCentre;
}

typedef TextPosition = {line:Int, lineChar:Int, char:Int};

/**
 * Text rendering GUI element.
 */
class Text implements Element<Text> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    @:builder var occluder = false;

    // Text
    /** Text GL3 Font */
    @:builder @:lazyVar var font:Font;
    /** Text horizontal align */
    @:builder var halign = TextAlignCentre;
    /** Text vertical align */
    @:builder var valign = TextAlignCentre;
    /** Justified rendering for multiline text **/
    @:builder var justified = false;
    /** Font pixel size (<=0 -> fixed aspect scaling to fill 'fit') */
    @:builder var size = 0.0;
    /** Text... text */
    @:builder var text:GLString;

    @:builder var spacing:Maybe<Float> = null;

    var lastgui:Gui;
    var finalTransform:Mat3x2;

    public var transform:Mat3x2;
    var buffer:StringBuffer;

    @:allow(glgui)
    @:lazyVar var textLayout:TextLayout;
    /**
     * Optional: Instantiate text with some string.
     *           Result will be a 'static' text element whose
     *           text should not be changed anymore.
     */
    public function new(text:Maybe<GLString>=null) {
        if (text != null) {
            var text = text.extract();
            this.text(text);
            buffer = new StringBuffer(null, text.length, true);
        }
        else buffer = new StringBuffer(null, 0, false);
        transform = Mat3x2.identity();
    }

    // Element
    public function destroy() {
        buffer.destroy();
    }

    //Text
    // move position to beginning of line
    public function toLineStart(t:TextPosition) {
        return {
            line : t.line,
            char : t.char - t.lineChar,
            lineChar : 0
        };
    }

    //Text
    // clamp position to text (keep line if possible).
    public function clamp(t:TextPosition) {
        if (t.line < 0) return {char:0, line:0, lineChar:0};

        if (t.line >= textLayout.lines.length) {
            t.lineChar = 10000000;
            t.line = textLayout.lines.length-1;
        }

        if (t.lineChar < 0) t.lineChar = 0;
        if (textLayout.lines.length > 0) {
            var cline = textLayout.lines[t.line];
            if (t.lineChar > cline.chars.length) t.lineChar = cline.chars.length;
        }
        else t.lineChar = t.char = 0;

        // Compute actual char position based on lineChar and line
        t.char = t.lineChar;
        for (i in 0...t.line) t.char += textLayout.lines[i].chars.length+1;
        return t;
    }

    //Text
    // move to end of line
    public function toLineEnd(t:TextPosition) {
        var text = getText();
        var pos = t.char;
        while (pos < text.length && text.charCodeAt(pos) != '\n'.code) pos++;
        return {
            line : t.line,
            char : pos,
            lineChar : t.lineChar + pos - t.char
        };
    }

    //Text
    // get text positino from character
    public function toPosition(c:Int) {
        if (c < 0) return { line:0, lineChar:0, char:0 };
        if (c > getText().length) c = getText().length;

        var lines = textLayout.lines;
        var line = 0;
        var sub = 0;
        while (line < lines.length && c-sub > lines[line].chars.length) {
            sub += lines[line].chars.length+1;
            line++;
        }
        return {
            line: line,
            lineChar: c-sub,
            char: c
        };
    }

    //Text
    // convert position to a physical position.
    public function toPhysical(p:TextPosition) {
        var info = getFont().info.extract();
        var pos:Vec2 = [0, p.line*info.height];
        var lines = textLayout.lines;
        if (lines.length == 0) return transform * pos;
        else {
            var line = lines[p.line];
            if (line.chars.length == 0) return transform * pos;

            if (p.lineChar == 0) pos.x -= line.chars[0].y*0.05;
            else if (p.lineChar >= line.chars.length) {
                var last = line.chars[line.chars.length-1];
                pos.x = last.x + last.y*1.05;
            }
            else {
                var cpos = line.chars[p.lineChar];
                var cpre = line.chars[p.lineChar-1];
                pos.x = 0.5*(cpre.x + cpre.y + cpos.x);
            }
            return transform * pos;
        }
    }

    //Text
    // Return index into string with which this Text object was last commited
    // that given pointer would be associated with.
    // point given in screen coordinates, not local coords.
    public function pointIndex(x:Vec2):TextPosition {
        x = finalTransform.inverse() * x;
        // choose line.
        var bounds = textLayout.bounds;
        var lines = textLayout.lines;
        var info = getFont().info.extract();
        var line = Std.int((x.y - bounds.y) / info.height);
        if      (x.y <= bounds.y) line = 0;
        else if (x.y >= bounds.y + bounds.w) line = lines.length-1;
        else {
            if (line < 0) line = 0;
            if (line >= lines.length) line = lines.length-1;
        }

        var lineChar;
        if (lines.length != 0) {
            var lineLayout = lines[line];
            var chars = lineLayout.chars;
            var bounds = lineLayout.bounds;
            if      (x.x <= bounds.x) lineChar = 0;
            else if (x.x >= bounds.x + bounds.y) lineChar = chars.length;
            else {
                lineChar = chars.length;
                for (i in 0...chars.length) {
                    var l = chars[i];
                    if (x.x <= l.x + l.y*0.5) {
                        lineChar = i;
                        break;
                    }
                }
            };
        }
        else {
            lineChar = 0;
        }

        var char = lineChar;
        for (i in 0...line) char += lines[i].chars.length+1; // +1 for \n character in string.

        return {
            line: line,
            lineChar: lineChar,
            char: char
        };
    }

    // Element
    public function internal(x:Vec2):Bool {
        return false;
    }

    // Element
    public function bounds():Maybe<Vec4> {
        return transform * textLayout.bounds;
    }

    // Element
    public function commit() {
        // Compute text textLayout, set vertex buffers.
        buffer.font = getFont();
        textLayout = buffer.set(getText(),
            switch (getHalign()) {
                case TextAlignLeft:  getJustified() ? AlignLeftJustified   : AlignLeft;
                case TextAlignRight: getJustified() ? AlignRightJustified  : AlignRight;
                default:             getJustified() ? AlignCentreJustified : AlignCentre;
            }, getSpacing(), true).extract();
        var textBounds = textLayout.bounds;
        // Determine text scaling.
        var scale = if (getSize() > 0.0) getSize()
            else Math.min(getFit().z / textBounds.z, getFit().w / textBounds.w);

        // And final (local) transform.
        transform[0] = transform[3] = scale;
        transform[1] = transform[2] = 0.0;
        transform[4] = (getFit().x - scale*textBounds.x)
            +  (switch (getHalign()) {
                case TextAlignLeft:  0.0;
                case TextAlignRight: 1.0;
                default:             0.5;
            })*(getFit().z - scale*textBounds.z);
        transform[5] = (getFit().y - scale*textBounds.y)
            +  (switch (getValign()) {
                case TextAlignTop:    0.0;
                case TextAlignBottom: 1.0;
                default:              0.5;
            })*(getFit().w - scale*textBounds.w);
        return this;
    }

    // Element
    public function render(gui:Gui, mpos:Maybe<Vec2>, proj:Mat3x2, xform:Mat3x2) {
        lastgui = gui;
        gui.textRenderer()
            .setTransform(proj * (finalTransform = xform * transform))
            .render(buffer);
        if (mpos.runOr(internal, false) && getOccluder()) gui.occludes();
    }
}
