package uhx.mo.dom.ranges;

import uhx.mo.dom.nodes.Node;

class BaseRange implements AbstractRange {

    /**
        A range has two associated boundary points — a start and end.
    **/
    public var start:BoundaryPoint;
    public var end:BoundaryPoint;

    // AbstractRange.hx

    public var startContainer(get, null):Node;
    public var startOffset(get, null):Int;
    public var endContainer(get, null):Node;
    public var endOffset(get, null):Int;

    /**
      A range is collapsed if its start node is its 
      end node and its start offset is its end offset.
    **/
    public var collapsed(get, null):Bool;

    private function get_startContainer():Node {
        return start.node;
    }

    private function get_startOffset():Int {
        return start.offset;
    }

    private function get_endContainer():Int {
        return end.node;
    }

    private function get_endOffset():Int {
        return end.offset;
    }

    private function get_collapsed():Bool {
        return startContainer.id == endContainer.id && startOffset == endOffset;
    }

}