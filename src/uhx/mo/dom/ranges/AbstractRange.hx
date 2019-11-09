package uhx.mo.dom.ranges;

import uhx.mo.dom.nodes.Node;

/**
    @see https://dom.spec.whatwg.org/#abstractrange
    Objects implementing the AbstractRange interface 
    are known as ranges.
**/
@:remove
interface AbstractRange {
    public var startContainer(get, null):Node;
    public var startOffset(get, null):Int;
    public var endContainer(get, null):Node;
    public var endOffset(get, null):Int;
    public var collapsed(get, null):Bool;
}