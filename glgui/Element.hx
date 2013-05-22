package glgui;

import glgui.Macros;
import glgui.Gui;
import ogl.GLM;

interface Element<T> extends Builder {
    @:builder(T) var visible:Bool;
    @:builder(T) var fit:Vec4;

    // readonly.
    public var transform:Mat3x2;

    public function destroy():Void;
    public function commit():T;
    public function render(gui:Gui, transform:Mat3x2):Void;
}
