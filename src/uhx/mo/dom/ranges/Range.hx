package uhx.mo.dom.ranges;

import uhx.mo.dom.nodes.Node;
import uhx.mo.dom.nodes.DocumentFragment;

/**
    @see https://dom.spec.whatwg.org/#range
    Objects implementing the Range interface are known as 
    live ranges.
**/
class Range extends BaseRange {

    public var commonAncestorContainer(get, null):Node;

    /**
        The Range() constructor, when invoked, must return a new live range with 
        (current global object’s associated Document, 0) as its start and end.
        ---
        Note: There is currently **no** way to fetch the global `Document`.
    **/
    public function new() {

    }

    public function setStart(node:Node, offset:Int):Void {

    }

    public function setEnd(node:Node, offset:Int):Void {

    }

    public function setStartBefore(node:Node):Void {

    }

    public function setStartAfter(node:Node):Void {
        
    }

    public function setEndBefore(node:Node):Void {

    }

    public function setEndAfter(node:Node):Void {
        
    }

    public function collapse(toStart:Bool = false):Void {

    }

    public function selectNode(node:Node):Void {

    }

    public function selectNodeContents(node:Node):Void {

    }

    public function compareBoundaryPoints(how:Int, sourceRange:Range):Int {
        return 0;
    }

    public function deleteContents():Void {

    }

    public function extractContents():DocumentFragment {
        return null;
    }

    public function cloneContents():DocumentFragment {
        return null;
    }

    public function insertNode(node:Node):Void {

    }

    public function surroundContents(newParent:Node):Void {

    }

    public function cloneRange():Range {
        return this;
    }

    public function detach():Void {

    }

    public function isPointInRange(node:Node, offset:Int):Bool {
        return false;
    }

    public function comparePoint(node:Node, offset:Int):Int {
        return 0;
    }

    public function intersectsNode(node:Node):Bool {
        return false;
    }

    // stringifier

}

