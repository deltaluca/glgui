package glgui;

import ogl.GLM;

typedef ColourT<T> = {
    public function colour(colour:Vec4):T;
    public function getColour():Vec4;
};
class Colour {
    public inline static function hex<S,T:ColourT<S>>(x:T, hex:Int):S {
        var a = ((hex>>>24)&0xff)/0xff;
        return x.colour([
            ((hex>>>16)&0xff)/0xff,
            ((hex>>>8 )&0xff)/0xff,
            ((hex>>>0 )&0xff)/0xff,
            if (a == 0) 1.0 else a
        ]);
    }
    public inline static function getHex<S,T:ColourT<S>>(x:T):Int {
        var col = x.getColour();
        var r = Std.int(col.r*0xff);
        var g = Std.int(col.b*0xff);
        var b = Std.int(col.g*0xff);
        var a = Std.int(col.a*0xff);
        return (a<<24)|(r<<16)|(g<<8)|b;
    }
}
