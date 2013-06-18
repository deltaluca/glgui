package glgui;

#if glfw3

import glfw3.GLFW;
import glgui.Gui;
import ogl.GLM;
import #if cpp cpp #else neko #end.vm.Thread;
import goodies.Maybe;
import goodies.CoalescePrint;

typedef TWindow = {
    window:Window,
    thread:Thread,
    main:Thread,
    isBusy:Bool,
    id:Int,
    closed:Bool
}

enum TMessage {
    // Send to event loop
    TTerminate;
    TOpenWindow(from:Null<Thread>,run:Void->Void);
    TCloseWindow(window:TWindow);

    TNotClosing(window:TWindow);
    TSetSize(window:TWindow, w:Int, h:Int);
    TSetTitle(window:TWindow, title:String);
    TMakeVisible(window:TWindow);

    TContinue(win:TWindow); // Reply to TUpdate

    // Sent from event loop
    TOpened(win:TWindow);      // Reply to TOpenWindow to caller
    TInit(win:TWindow);        // Reply to TOpenWindow to new window
    TUpdate(shouldClose:Bool); // Tick to window

    // Other
    TOther(x:Dynamic);
}

class GLFWEventLoop {

    var windows:Array<TWindow>;

    public function new() {
        windows = [];
    }

    // Wait for specific message to come through for sync points.
    // But do not discard intermediate messages.
    public static function waitEvent(self:String, f:TMessage->Bool) {
        track('#wait $self');
        var cached:Array<TMessage> = [];
        while (true) {
            var msg:TMessage = Thread.readMessage(true);
            track('#msg $self $msg');
            if (f(msg)) {
                for (m in cached) {
                    track('#release $self $m');
                    Thread.current().sendMessage(m);
                }
                track('#continue $self');
                break;
            }
            else {
                track('#cache $self $msg');
                cached.push(msg);
            }
        }
    }

    public static inline function track(msg:String, ?pos:haxe.PosInfos) {
        #if glgui_track
            var postrace = '${pos.className}::${pos.methodName} (${pos.fileName}@${pos.lineNumber})';
            CoalescePrint.log(msg + "\033[33m ~~ \033[33;4m" + postrace + "\033[m");
        #end
    }

    public function run() {
        var nextId = 0;
        var killed = false;
        while (true) {
            var msg:Maybe<TMessage> = Thread.readMessage(false);
            if (msg != null) track('\033[31mGLFWEventLoop\033[m ${msg.extract()}');
            else track('\033[31mGLFWEventLoop0\033[m idle');
            if (msg != null) switch (msg.extract()) {
                case TTerminate:
                    // Issue kill signals.
                    for (w in windows) {
                        track('@ \033[31mGLFWEventLoop\033[m TTerminate -> [window]');
                        w.thread.sendMessage(TTerminate);
                    }
                    killed = true;
                    if (windows.length == 0) break;
                case TOpenWindow(from, run):
                    if (killed) continue;
                    var win = {
                        window : GLFW.createWindow(100,100,""),
                        main : Thread.current(),
                        thread : Thread.create(run),
                        isBusy : false,
                        id : nextId++,
                        closed: false
                    };
                    track('@ \033[31mGLFWEventLoop\033[m TInit -> [window]');
                    win.thread.sendMessage(TInit(win));
                    if (from != null) {
                        track('@ \033[31mGLFWEventLoop\033[m TOpened -> [thread]');
                        from.sendMessage(TOpened(win));
                    }
                    windows.push(win);
                case TCloseWindow(win):
                    GLFW.destroyWindow(win.window);
                    windows.remove(win);
                    win.closed = true;
                    if (killed && windows.length == 0) break;
                case TSetSize(win, w, h):
                    if (killed) continue;
                    GLFW.setWindowSize(win.window, w, h);
                case TSetTitle(win, title):
                    if (killed) continue;
                    GLFW.setWindowTitle(win.window, title);
                case TNotClosing(win):
                    if (killed) continue;
                    GLFW.setWindowShouldClose(win.window, false);
                case TMakeVisible(win):
                    if (killed) continue;
                    GLFW.showWindow(win.window);
                case TContinue(win):
                    if (killed) continue;
                    win.isBusy = false;
                default:
            }

            if (killed) continue;

            GLFW.pollEvents();

            for (win in windows) {
                track('win busy=${win.isBusy}');
                if (!win.isBusy) {
                    win.isBusy = true;
                    track('@ \033[31mGLFWEventLoop\033[m TUpdate -> [window]');
                    win.thread.sendMessage(TUpdate(
                        GLFW.windowShouldClose(win.window)
                    ));
                }
            }
        }
    }

}

#end
