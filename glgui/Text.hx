package glgui;

import ogl.GLM;
import gl3font.Font;
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
    /** Text colour */
    @:builder var colour:Vec4 = [1.0,1.0,1.0,1.0];
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
    @:builder var text:String;

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
    public function new(text:String="") {
        this.text(text);
        buffer = new StringBuffer(null, text.length, text.length != 0);
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

            if (p.lineChar == 0) pos.x -= line.chars[0].z*0.05;
            else if (p.lineChar >= line.chars.length) {
                var last = line.chars[line.chars.length-1];
                pos.x = last.x + last.z*1.05;
            }
            else {
                var cpos = line.chars[p.lineChar];
                var cpre = line.chars[p.lineChar-1];
                pos.x = 0.5*(cpre.x + cpre.z + cpos.x);
            }
            return transform * pos;
        }
    }

    //Text
    // Return index into string with which this Text object was last commited
    // that given pointer would be associated with.
    public function pointIndex(x:Vec2):TextPosition {
        x = (finalTransform.inverse() * lastgui.getProjection()) * x;
        // choose line.
        var bounds = textLayout.bounds;
        var lines = textLayout.lines;
        var line;
        if      (x.y <= bounds.y) line = 0;
        else if (x.y >= bounds.y + bounds.w) line = lines.length-1;
        else {
            line = lines.length-1;
            for (i in 0...lines.length-1) {
                var l0 = lines[i];
                var l1 = lines[i+1];
                var dy = 0.5*(l0.bounds.y + l0.bounds.w + l1.bounds.y);
                if (x.y <= dy) {
                    line = i;
                    break;
                }
            }
        };
        if (line < 0) line = 0;
        var lineChar;
        if (lines.length != 0) {
            var lineLayout = lines[line];
            var chars = lineLayout.chars;
            bounds = lineLayout.bounds;
            if      (x.x <= bounds.x) lineChar = 0;
            else if (x.x >= bounds.x + bounds.z) lineChar = chars.length;
            else {
                lineChar = chars.length;
                for (i in 0...chars.length) {
                    var l = chars[i];
                    if (x.x <= l.x + l.z*0.5) {
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
        var y = transform.inverse() * x;
        for (l in textLayout.lines) {
            for (c in l.chars) {
                y.x -= c.x;
                y.y -= c.y;
                if (y.x >= 0 && y.x <= c.z && y.y >= 0 && y.y <= c.w) return true;
            }
        }
        return false;
    }

    // Element
    public function bounds():Maybe<Vec4> return textLayout.bounds;

    // Element
    public function commit() {
        // Compute text textLayout, set vertex buffers.
        buffer.font = getFont();
        textLayout = buffer.set(getText(),
            switch (getHalign()) {
                case TextAlignLeft:  getJustified() ? AlignLeftJustified   : AlignLeft;
                case TextAlignRight: getJustified() ? AlignRightJustified  : AlignRight;
                default:             getJustified() ? AlignCentreJustified : AlignCentre;
            }, true).extract();
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
    public function render(gui:Gui, _, xform:Mat3x2) {
        lastgui = gui;
        gui.textRenderer()
            .setColour(getColour())
            .setTransform(finalTransform = xform * transform)
            .render(buffer);
    }
}
