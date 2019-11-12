package uhx.mo.dom.nodes;

import uhx.mo.html.tree.NodePtr;

/**
    @see https://dom.spec.whatwg.org/#nodelist
**/
@:forward(length)
abstract NodeList(Array<NodePtr>) from Array<NodePtr> {
    @:op([]) public inline function item(index:Int):Null<Node> {
        return this[index];
    }

    public inline function iterator():Iterator<Node> {
        var itr = this.iterator();
        return {
            hasNext: itr.hasNext,
            next: () -> itr.next().get()
        }
    }
}