package glgui;

#if macro
    import haxe.macro.Expr;
    import haxe.macro.Context;
#end

@:autoBuild(glgui.MacrosBuild.run())
interface Builder {}

class MacrosBuild {
#if macro
    public static function run() {
        var self = Utils.self();
        var iface = Utils.isInterface();

        var fields = Context.getBuildFields();
        var gields = [];
        var inits = [];
        var access = if (iface) [APublic] else [APublic, AInline];
        for (f in fields) {
            var meta = Utils.hasMeta(f, ":builder");
            if (meta == null) continue;
            if (meta.length != 0) self = Context.toComplexType(Context.getType(switch (meta[0].expr) { case EConst(CIdent(s)): s; default: ""; }));
            switch (f.kind) {
            case FVar(t,e):
                // Prefix field with _
                var fname = f.name;
                f.name = '_$fname';

                // Move initialisation to constructor
                if (e != null) {
                    if (t == null) t = Context.toComplexType(Context.typeof(e));
                    inits.push(macro $i{f.name} = $e);
                    f.kind = FVar(t, null);
                }

                // Remove on interfaces.
                if (iface) f.kind = null;

                // Add builder getter/setter
                gields.push(Utils.field(macro function (x:$t):$self {
                    $i{f.name} = x;
                    return this;
                }, access, fname, iface));
                var fname2 = "get"+fname.charAt(0).toUpperCase()+fname.substr(1);
                gields.push(Utils.field(macro function ():$t {
                    return $i{f.name};
                }, access, fname2, iface));
            default:
            }
        }
        for (f in fields) {
            if (f.name == "new") {
                switch (f.kind) {
                case FFun(f):
                    inits.push(f.expr);
                    f.expr = macro $b{inits};
                default:
                }
            }
        }
        fields = fields.filter(function (f) return f.kind != null);
        fields = fields.concat(gields);
//        trace("\n"+fields.map((new haxe.macro.Printer()).printField).join("\n"));
        return fields;
    }
#end
}

#if macro
class Utils {
    public static function field(e:Expr, access:Array<Access>, name:String, iface=false):Field {
        return {
            pos: if (e == null) Context.currentPos() else e.pos,
            name: name,
            meta: null,
            doc: null,
            access: access,
            kind: switch (e.expr) {
                case EVars([{type:t, expr:e}]): FVar(t, e);
                case EFunction(_,f): {
                    if (iface) f.expr = null;
                    FFun(f);
                }
                default: null;
            }
        };
    }

    public static function self() {
        var local = Context.getLocalClass();
        return Context.toComplexType(TInst(local, [for (p in local.get().params) p.t]));
    }

    public static function isInterface() {
        var local = Context.getLocalClass();
        return local.get().isInterface;
    }

    public static function hasMeta(f:Field, name:String):Array<Expr> {
        for (m in f.meta) if (m.name == name) return m.params;
        return null;
    }
}
#end
