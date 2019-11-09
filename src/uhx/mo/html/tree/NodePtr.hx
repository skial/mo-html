package uhx.mo.html.tree;

import uhx.mo.dom.nodes.Node;

@:forward
@:forwardStatics
abstract NodePtr(Int) from Int to Int {

    @:from public static inline function fromNodeInterface(node:Node):NodePtr {
        return node.id;
    }

}