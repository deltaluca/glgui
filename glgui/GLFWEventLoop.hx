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

    public static inline function track(msg:String) {
        #if glgui_track
            CoalescePrint.log(msg);
        #end
    }

    public function run() {
        var nextId = 0;
        while (true) {
            var msg:Maybe<TMessage> = Thread.readMessage(false);
            if (msg != null) track('\033[31mGLFWEventLoop\033[m ${msg.extract()}');
            if (msg != null) switch (msg.extract()) {
                case TTerminate: break;
                case TOpenWindow(from, run):
                    var win = {
                        window : GLFW.createWindow(10,10,""),
                        main : Thread.current(),
                        thread : Thread.create(run),
                        isBusy : false,
                        id : nextId++
                    };
                    win.thread.sendMessage(TInit(win));
                    if (from != null)
                        from.sendMessage(TOpened(win));
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
                if (!win.isBusy) {
                    win.isBusy = true;
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
