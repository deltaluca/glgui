package glgui;

import glgui.Gui;
import ogl.GLArray;
import ogl.GLM;
import ogl.GL;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;

class Drawing {

    static inline var VERTEX_SIZE = 6; // x, y, r, g, b, a

    var lines:Bool; // true when drawing lines, false when drawing triangles
    var vertexData:GLfloatArray;
    var vertexArray:Int;
    var vertexBuffer:Int;
    var numVertices:Int = 0;

    var buffer:Array<Float>;

    var program:Int;
    var proj:Int;

    public function new() {
        vertexData = GL.allocBuffer(GL.FLOAT, VERTEX_SIZE*6); // 6 = lcf(line-vert-count,tri-vert-count)
        vertexArray = GL.genVertexArrays(1)[0];
        GL.bindVertexArray(vertexArray);
        buffer = [];

        vertexBuffer = GL.genBuffers(1)[0];
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        GL.bufferData(GL.ARRAY_BUFFER, vertexData, GL.STREAM_DRAW);

        var vertexShader = GL.createShader(GL.VERTEX_SHADER);
        var fragmentShader = GL.createShader(GL.FRAGMENT_SHADER);
        GL.shaderSource(vertexShader, "
            #version 130
            in vec2 vPos;
            in vec4 vColour;
            uniform mat3x2 proj;
            out vec4 colour;
            void main() {
                gl_Position = vec4(proj * vec3(vPos, 1), 0, 1);
                colour = vColour;
            }
        ");
        GL.shaderSource(fragmentShader, "
            #version 130
            in vec4 colour;
            out vec4 outColour;
            void main() {
                outColour = colour;
            }
        ");
        GL.compileShader(vertexShader);
        GL.compileShader(fragmentShader);

        program = GL.createProgram();
        GL.attachShader(program, vertexShader);
        GL.attachShader(program, fragmentShader);

        GL.bindAttribLocation(program, 0, "vPos");
        GL.bindAttribLocation(program, 1, "vColour");
        GL.linkProgram(program);

        GL.deleteShader(vertexShader);
        GL.deleteShader(fragmentShader);

        proj = GL.getUniformLocation(program, "proj");

        lines = true;
    }

    public function destroy() {
        GL.deleteProgram(program);
        GL.deleteVertexArrays([vertexArray]);
        GL.deleteBuffers([vertexBuffer]);
    }

    inline function vertex(vindex:Int, off:Int, p:Vec2, c:Vec4, dup=false) {
        vindex += off*VERTEX_SIZE;
        vertexData.subDataVec(p, vindex);
        vertexData.subDataVec(c, vindex+2);
        if (dup) {
            vertexData.subDataVec(p, vindex+VERTEX_SIZE);
            vertexData.subDataVec(c, vindex+VERTEX_SIZE+2);
        }
    }

    public inline function swapLines() {
        if (!lines) flush();
        lines = true;
    }
    public inline function swapFills() {
        if (lines) flush();
        lines = false;
    }

    public inline function pushVertex(p:Vec2, c:Vec4) {
        var vindex = reserve(1);
        vertex(vindex, 0, p, c);
    }

    public inline function data(xs:Array<Float>) {
        var vindex = reserve(Std.int(xs.length/VERTEX_SIZE));
        vertexData.subData(xs, vindex);
    }

    public function drawLine(p0:Vec2, p1:Vec2, c:Vec4) {
        swapLines();
        data([p0.x,p0.y,c.x,c.y,c.z,c.w,
              p1.x,p1.y,c.x,c.y,c.z,c.w]);
    }

    public function drawDashedLine(p0:Vec2, p1:Vec2, c:Vec4, solid:Float, gap:Float) {
        var dt = Vec2.distance(p0, p1);
        var del = Vec2.normalize(p1 - p0);
        var d = 0.0;
        var p = p0;
        while (d < dt) {
            var dp = d + solid;
            if (dp > dt) dp = dt;
            drawLine(p0 + del*d, p0 + del*dp, c);
            d = dp;
            if (d >= dt) break;
            var dp = d + gap;
            if (dp > dt) dp = dt;
            d = dp;
            if (d >= dt) break;
        }
    }

    public function drawRectangle(min:Vec2, max:Vec2, c:Vec4) {
        swapLines();
        var vindex = reserve(8);
        vertex(vindex,0, min,           c);
        vertex(vindex,1, [max.x,min.y], c, true);
        vertex(vindex,3, max,           c, true);
        vertex(vindex,5, [min.x,max.y], c, true);
        vertex(vindex,7, min,           c);
    }

    public function drawCircle(p:Vec2, radius:Float, c:Vec4) {
        swapLines();
        var cr = c.r;
        var cg = c.g;
        var cb = c.b;
        var ca = c.a;
        var px = p.x;
        var py = p.y;

        var maxError = 0.5; // px
        var vCount;
        if (radius < maxError / 2) vCount = 3;
        else {
            // Error for given turn theta
            // E = r(1-cos(t/2))
            // We require E < maxError <=> t > 2.acos(1 - maxError/r)
            // Requiring pi/acos(1 - maxError/r) vertices
            vCount = Math.ceil(Math.PI / Math.acos(1 - maxError/radius));
            if (vCount < 3) vCount = 3;
        }

        var data = [];

        // Generate vertices via radial vector (radius, 0)
        var dx = radius;
        var dy = 0.0;

        var angInc = Math.PI * 2 / vCount;
        var cos = Math.cos(angInc);
        var sin = Math.sin(angInc);

        data.push(px+radius);
        data.push(py);
        data.push(cr);
        data.push(cg);
        data.push(cb);
        data.push(ca);
        for (i in 1...vCount) {
            var nx = (dx * cos) - (dy * sin);
            dy = (dx * sin) + (dy * cos);
            dx = nx;
            data.push(px+dx);
            data.push(py+dy);
            data.push(cr);
            data.push(cg);
            data.push(cb);
            data.push(ca);
            data.push(px+dx);
            data.push(py+dy);
            data.push(cr);
            data.push(cg);
            data.push(cb);
            data.push(ca);
        }
        data.push(px+radius);
        data.push(py);
        data.push(cr);
        data.push(cg);
        data.push(cb);
        data.push(ca);
        this.data(data);
/*        var vindex = reserve(vCount * 2); //GL_LINES, must duplicate

        // Generate vertices via radial vector (radius, 0)
        var dx = radius;
        var dy = 0.0;

        var angInc = Math.PI * 2 / vCount;
        var cos = Math.cos(angInc);
        var sin = Math.sin(angInc);

        vertex(vindex,0, [p.x+radius,p.y], c);
        for (i in 1...vCount) {
            var nx = (dx * cos) - (dy * sin);
            dy = (dx * sin) + (dy * cos);
            dx = nx;
            vertex(vindex,i*2-1, [p.x+dx,p.y+dy], c, true);
        }
        vertex(vindex,vCount*2-1, [p.x+radius,p.y], c);*/
    }

    public function drawFilledCircle(p:Vec2, radius:Float, c:Vec4) {
        swapFills();
        var maxError = 0.5; // px
        var vCount;
        if (radius < maxError / 2) vCount = 3;
        else {
            // Error for given turn theta
            // E = r(1-cos(t/2))
            // We require E < maxError <=> t > 2.acos(1 - maxError/r)
            // Requiring pi/acos(1 - maxError/r) vertices
            vCount = Math.ceil(Math.PI / Math.acos(1 - maxError/radius));
            if (vCount < 3) vCount = 3;
        }

        var tCount = vCount - 2;
        var vindex = reserve(tCount * 3);

        // Generate vertices via radial vector (radius, 0)
        var dx = radius;
        var dy = 0.0;

        var angInc = Math.PI * 2 / vCount;
        var cos = Math.cos(angInc);
        var sin = Math.sin(angInc);

        var nx = (dx * cos) - (dy * sin);
        dy = (dx * sin) + (dy * cos);
        dx = nx;
        for (i in 0...tCount) {
            vertex(vindex, i*3,   [p.x+radius,p.y], c);
            vertex(vindex, i*3+1, [p.x+dx, p.y+dy], c);
            var nx = (dx * cos) - (dy * sin);
            dy = (dx * sin) + (dy * cos);
            dx = nx;
            vertex(vindex, i*3+2, [p.x+dx, p.y+dy], c);
        }
    }

    inline function reserve(numVerts:Int) {
        var current = numVertices * VERTEX_SIZE;
        var newsize = current + (numVerts * VERTEX_SIZE);
        if (newsize > vertexData.count) {
            var size = vertexData.count;
            do size *= 2 while (size < newsize);
            vertexData.resize(size);
            GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
            GL.bufferData(GL.ARRAY_BUFFER, vertexData, GL.STREAM_DRAW);
        }
        numVertices += numVerts;
        return current;
    }

    public function clear() {
        numVertices = 0;
        return this;
    }

    public function begin() {
        GL.useProgram(program);
        GL.enableVertexAttribArray(0);
        GL.enableVertexAttribArray(1);

        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        GL.vertexAttribPointer(0, 2, GL.FLOAT, false, VERTEX_SIZE*4, 0);
        GL.vertexAttribPointer(1, 4, GL.FLOAT, false, VERTEX_SIZE*4, 2*4);
        return this;
    }

    public function setTransform(mat:Mat3x2,noClear=false) {
        flush(noClear);
        GL.uniformMatrix3x2fv(proj, false, mat);
        return this;
    }

    public function flush(noClear=false) {
        if (numVertices == 0) return this;

        GL.bufferSubData(GL.ARRAY_BUFFER, 0, GLfloatArray.view(vertexData, 0, numVertices*VERTEX_SIZE));
        GL.drawArrays(lines ? GL.LINES : GL.TRIANGLES, 0, numVertices);

        if (!noClear)
            clear();
        return this;
    }

    public function end(noClear=false) {
        flush(noClear);
        GL.disableVertexAttribArray(0);
        GL.disableVertexAttribArray(1);
        return this;
    }
}
