package glgui;

#if glfw3

import glfw3.GLFW;
import glgui.Gui;
import ogl.GLM;
import cpp.vm.Thread;
import goodies.Maybe;
import goodies.CoalescePrint;

typedef TWindow = {
    window:Window,
    thread:Thread,
    main:Thread,
    isBusy:Bool,
    id:Int
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

    public static inline function track(msg:String, ?pos:haxe.PosInfos) {
        #if glgui_track
            var postrace = '${pos.className}::${pos.methodName} (${pos.fileName}@${pos.lineNumber})';
            CoalescePrint.log(msg + "\033[33m ~~ \033[33;4m" + postrace + "\033[m");
        #end
    }

    public function run() {
        var nextId = 0;
        while (true) {
            var msg:Maybe<TMessage> = Thread.readMessage(false);
            if (msg != null) track('\033[31mGLFWEventLoop\033[m ${msg.extract()}');
            else track('\033[31mGLFWEventLoop0\033[m idle');
            if (msg != null) switch (msg.extract()) {
                case TTerminate: break;
                case TOpenWindow(from, run):
                    var win = {
                        window : GLFW.createWindow(100,100,""),
                        main : Thread.current(),
                        thread : Thread.create(run),
                        isBusy : false,
                        id : nextId++
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
                case TSetSize(win, w, h):
                    GLFW.setWindowSize(win.window, w, h);
                case TSetTitle(win, title):
                    GLFW.setWindowTitle(win.window, title);
                case TNotClosing(win):
                    GLFW.setWindowShouldClose(win.window, false);
                case TMakeVisible(win):
                    GLFW.showWindow(win.window);
                case TContinue(win):
                    win.isBusy = false;
                default:
            }

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

        while (windows.length > 0) {
            var win = windows.pop();
            GLFW.destroyWindow(win.window);
        }
    }

}

#end
