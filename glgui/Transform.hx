package glgui;

import ogl.GLM;
import glgui.Element;

class Transform {
    public inline static function position<T>(x:Element<T>, pos:Vec2):T {
        var fit = x.getFit();
        return x.fit([pos.x,pos.y,fit.z,fit.w]);
    }
}
