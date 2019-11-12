package uhx.mo.html.tree;

import uhx.mo.dom.nodes.Node;
import uhx.mo.html.tree.Construction;

/**
    Not part of the spec.
**/

@:notNull
abstract NodePtr(Int) from Int to Int {

    @:to public inline function get():Node {
        return Construction.current.tree.vertices[this];
    }

    @:from public static inline function fromNode(node:Node):NodePtr {
        return node.id;
    }

}