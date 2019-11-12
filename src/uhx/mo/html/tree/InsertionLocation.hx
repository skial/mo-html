package uhx.mo.html.tree;

/**
    Not part of the spec.
**/

@:notNull
@:forward
@:forwardStatics
abstract InsertionLocation(InsertionImpl) from InsertionImpl {

    public inline function insert(v:NodePtr):Void {
        this.node.get().childrenPtr.insert(this.pos, v);
    }

}

@:structInit
class InsertionImpl {

    public var pos:Int;
    public var node:NodePtr;

    public inline function new(node:NodePtr, pos:Int) {
        this.node = node;
        this.pos = pos;
    }

}