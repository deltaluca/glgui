package glgui;

import ogl.GLM;
import gl3font.Font;

enum GuiState {
    GSText;
}

class Gui {
    var proj:Mat3x2;
    var state:GuiState;
    var textRender:FontRenderer;

    public function new(width:Float, height:Float) {
        textRender = new FontRenderer();
        proj = Mat3x2.viewportMap(width, height);
        state = null;
    }

    public function destroy() {
        textRender.destroy();
    }
    public function flush() {
        if (state == null) return;
        switch (state) {
        case GSText: textRender.end();
        }
        state = null;
    }

    public function render<S,T:Element<S>>(x:T) {
        x.render(this, proj);
    }

    public function textRenderer() {
        if (state == null || !Type.enumEq(state, GSText)) {
            flush();
            state = GSText;
            textRender.begin();
        }
        return textRender;
    }
}
