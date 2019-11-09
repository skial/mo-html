package uhx.mo.dom.nodes;

import be.ds.util.Counter;
import uhx.mo.html.tree.NodePtr;

// @:see https://dom.spec.whatwg.org/#documentfragment
class DocumentFragment extends BaseNode {

    public function new() {
        super(null);
    }

    // Node.hx

    private override function get_nodeName():String {
        return '#document-fragment';
    }

    private override function get_nodeType():NodeType {
        return NodeType.DocumentFragement;
    }

    private override function get_nodeValue():Null<String> {
        return null;
    }

}