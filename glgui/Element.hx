package glgui;

import glgui.Gui;
import ogl.GLM;
import goodies.Builder;
import goodies.Maybe;
import goodies.Lazy;

/**
 * GL-GUI Element.
 */
interface Element<T> extends Builder extends MaybeEnv extends LazyEnv {
    /**
     * Inactive elements are not rendered, and undergo
     * no change in state or event activity.
     */
    @:builder(ret=T) var active:Bool;

    /**
     * Rectangular region of coordinate system to fit
     * element into.
     *
     * Any scaling/relative positioning is element dependent
     *
     * Setting element position sets its fit to (x,y,0,0)
     * and is valid only for those elements which do not
     * undergo scaling!
     */
    @:builder(ret=T) var fit:Vec4;

    /**
     * An occluder will act as a spatial barrier to the reach
     * of a mouse pointer to elements underneath the area of
     * this element.
     *
     * Default value is element dependent.
     */
    @:builder var occluder:Bool;

    /**
     * Returns true if, in the local coordinates of an element
     * the position 'x' is contained in the element.
     */
    public function internal(x:Vec2):Bool;

    /**
     * Destroy element, cleaning up any vertex buffers etc
     * which may be associated with it.
     */
    public function destroy():Void;

    /**
     * Commit any changes to the elements state for processing,
     * eg. changes in how element will be rendered
     */
    public function commit():T;

    /**
     * Returns the local coordinate bounds of the element
     * Returns null if element has no bounds (eg Mouse)
     */
    public function bounds():Maybe<Vec4>;

    /**
     * @:noCompletion
     *
     * Render element to gui, mouse argument used only for Mouse
     * special element to handle events
     *
     * transform is parent transformation for rendering.
     */
    public function render(gui:Gui, mouse:Vec2, transform:Mat3x2):Void;
}
