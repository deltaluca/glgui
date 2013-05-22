package glgui;

import ogl.GLM;
import glgui.Element;

class Transform {
    public inline static function position<T>(x:Element<T>, pos:Vec2):T {
        return x.fit([pos.x,pos.y,0,0]);
    }
}
