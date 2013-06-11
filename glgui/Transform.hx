package glgui;

import ogl.GLM;
import glgui.Element;

class Transform {
    public inline static function position<T>(x:Element<T>, pos:Vec2):T {
        var fit = x.getFit();
        return x.fit([pos.x,pos.y,fit.z,fit.w]);
    }

    public inline static function getPosition<T>(x:Element<T>):Vec2 {
        var fit = x.getFit();
        return [fit.x,fit.y];
    }

    @:allow(ogl)
    public inline static function posx<T>(x:Element<T>, f:Float):T {
        var fit = x.getFit();
        fit.x = f;
        return x.fit(fit);
    }

    @:allow(ogl)
    public inline static function posy<T>(x:Element<T>, f:Float):T {
        var fit = x.getFit();
        fit.y = f;
        return x.fit(fit);
    }
}
