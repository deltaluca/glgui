package;

import sys.io.Process;

class Assets {
    static var ttfcompile = "ttfcompile";
    static function main() {
        trace("Generating distance map for quarter_circle.png");
        var p = new Process(ttfcompile, ["-transform", "quarter_circle.png", "60", "16", "-o=quarter_circle.distance"]);
        try {
            var code = p.exitCode();
            if (code != 0) {
                trace("Exited with code="+code);
                trace(p.stderr.readAll());
            }
        }
        catch (e:Dynamic) {
            trace("Exited with exception");
            trace(p.stderr.readAll());
        }

        trace("Generating distance map for line.png");
        var p = new Process(ttfcompile, ["-transform", "line.png", "60", "16", "-o=line.distance"]);
        try {
            var code = p.exitCode();
            if (code != 0) {
                trace("Exited with code="+code);
                trace(p.stderr.readAll());
            }
        }
        catch (e:Dynamic) {
            trace("Exited with exception");
            trace(p.stderr.readAll());
        }
    }
}
