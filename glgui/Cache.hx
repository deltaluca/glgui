package glgui;

class Cache {
    var store:Map<String,Dynamic>;
    public function new() {
        store = new Map<String,Dynamic>();
    }

    @:extern public inline function cache<S,T:Element<S>>(n:String, o:T):T {
        if (store.exists(n)) return store[n];
        else {
            var ret = o;
            store.set(n, ret);
            return ret;
        }
    }
}
