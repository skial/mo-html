package uhx.mo.dom.ranges;

import uhx.mo.dom.nodes.*;

enum abstract Position(Null<Bool>) to Null<Bool> {
    public var Before = null;
    public var Equal = false;
    public var After = true;
}

/**
    @see https://dom.spec.whatwg.org/#boundary-points
**/
@:structInit
@:using(uhx.mo.dom.ranges.BoundaryPoint.BoundaryPointUtil)
class BoundaryPoint {

    public var node:Node;
    public var offset:Int;

    public inline function new(node:Node, offset:Int) {
        this.node = node;
        this.offset = offset;
    }

}

class BoundaryPointUtil {

    /**
        @see https://dom.spec.whatwg.org/#concept-range-bp-position
        The position of a boundary point (nodeA, offsetA) relative to a 
        boundary point (nodeB, offsetB) is before, equal, or after.
    **/
    public static function position(a:BoundaryPoint, b:BoundaryPoint):Position {
        var rootA = a.node.root();
        var rootB = b.node.root();

        if (rootA.id == rootB.id) {
            if (a.node.id == b.node.id) {
                if (a.offset == b.offset) return Equal;
                if (a.offset < b.offset) return Before;
                if (a.offset > b.offset) return After;

            }

            if (a.node.isFollowing(b.node)) {
                switch position(b, a) {
                    case Before: return After;
                    case After: return Before;
                    case _:
                }

            }

            if (a.node.isAncestorOf(b.node)) {
                var child = b.node;
                while (!child.isChildOf(a.node)) {
                    child.parent;
                }

                if (child.index() < a.offset) return After;

            }

        }

        return Before;
    }

}