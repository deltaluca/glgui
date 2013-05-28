package glgui;

import glgui.Gui;
import glgui.Element;
import ogl.GL;
import ogl.GLM;
import ogl.GLArray;
import glgui.Image;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;

using glgui.Transform;
using glgui.Colour;

class Image implements Element<Image> {

    // Element
    @:builder var active = true;
    @:builder var fit:Vec4 = [0.0,0.0,0.0,0.0];
    @:builder var occluder = true;

    // Image
    var managedTexture = false;
    @:builder(react=function (newTexture) {
        if (managedTexture) {
            GL.deleteTextures([getTexture()]);
            managedTexture = false;
        }
    }) var texture:GLuint;

    public function new() {
    }

    public static function fromPNG(file:String) {
        var ret = new Image();

        var file = sys.io.File.read(file, true);
        var pngData = (new format.png.Reader(file)).read();
        var textureData:GLubyteArray = format.png.Tools.extract32(pngData).getData();
        var pngHeader = format.png.Tools.getHeader(pngData);

        var tex = GL.genTextures(1)[0];
        GL.bindTexture(GL.TEXTURE_2D, tex);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, pngHeader.width, pngHeader.height, 0, GL.RGBA, textureData);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);
        GL.generateMipmap(GL.TEXTURE_2D);

        ret._texture = tex;
        ret.managedTexture = true;
        return ret;
    }

    // Element
    public function destroy() {
    }

    // Element
    public function bounds():Maybe<Vec4> return getFit();
    // Element
    public function internal(x:Vec2) {
        var fit = getFit();
        var dx = x.x - fit.x;
        var dy = x.y - fit.y;
        return dx >= 0 && dx <= fit.z &&
               dy >= 0 && dy <= fit.w;
    }

    // Element
    public function commit() {
        return this;
    }

    // Element
    public function render(gui:Gui, _, proj:Mat3x2, xform:Mat3x2) {
        var fit = getFit();
        var transform:Mat3x2 = [
            fit.z,   0,
              0,   fit.w,
            fit.x, fit.y
        ];
        gui.imageRenderer()
            .setTransform(proj * xform * transform)
            .render(this);
    }
}

class ImageRenderer {

    var program:GLuint;
    var proj:GLuint;

    var vertexArray:Int;
    var vertexBuffer:Int;

    public function new() {
        var vertexData:GLfloatArray = GL.allocBuffer(GL.FLOAT, 12);
        vertexArray = GL.genVertexArrays(1)[0];
        GL.bindVertexArray(vertexArray);

        vertexData[0] = 0; vertexData[1] = 0;
        vertexData[2] = 1; vertexData[3] = 0;
        vertexData[4] = 1; vertexData[5] = 1;

        vertexData[6]  = 0; vertexData[7]  = 0;
        vertexData[8]  = 1; vertexData[9]  = 1;
        vertexData[10] = 0; vertexData[11] = 1;

        vertexBuffer = GL.genBuffers(1)[0];
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        GL.bufferData(GL.ARRAY_BUFFER, vertexData, GL.STATIC_DRAW);

        var vShader = GL.createShader(GL.VERTEX_SHADER);
        var fShader = GL.createShader(GL.FRAGMENT_SHADER);
        GL.shaderSource(vShader, "
            #version 130
            in vec2 vPos;
            uniform mat4 proj;
            out vec2 fUV;
            void main() {
                gl_Position = proj*vec4(vPos,0,1);
                fUV = vPos;
            }
        ");
        GL.shaderSource(fShader, "
            #version 130
            in vec2 fUV;
            out vec4 colour;
            uniform sampler2D tex;
            void main() {
                colour = texture(tex, fUV);
            }
        ");
        GL.compileShader(vShader);
        GL.compileShader(fShader);

        program = GL.createProgram();
        GL.attachShader(program, vShader);
        GL.attachShader(program, fShader);

        GL.bindAttribLocation(program, 0, "vPos");
        GL.linkProgram(program);

        GL.deleteShader(vShader);
        GL.deleteShader(fShader);

        proj = GL.getUniformLocation(program, "proj");
    }

    public function destroy() {
        GL.deleteVertexArrays([vertexArray]);
        GL.deleteBuffers([vertexBuffer]);
        GL.deleteProgram(program);
    }

    public function begin() {
        GL.useProgram(program);
        GL.enableVertexAttribArray(0);
        return this;
    }

    public function setTransform(mat:Mat4) {
        GL.uniformMatrix4fv(proj, false, mat);
        return this;
    }

    public function render(im:Image) {
        GL.bindTexture(GL.TEXTURE_2D, im.getTexture());
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        GL.vertexAttribPointer(0, 2, GL.FLOAT, false);
        GL.drawArrays(GL.TRIANGLES, 0, 6);
        return this;
    }

    public function end() {
        GL.disableVertexAttribArray(0);
        return this;
    }
}


