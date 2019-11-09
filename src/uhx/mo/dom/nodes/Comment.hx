package uhx.mo.dom.nodes;

import be.ds.util.Counter;
import uhx.mo.html.tree.NodePtr;

// @:see https://dom.spec.whatwg.org/#comment
class Comment extends BaseNode {

    public function new(data:String = '') {
        this.nodeValue = data;
        super(null);
    }

    // Node.hx

    private override function get_nodeName():String {
        return '#comment';
    }

    private override function get_nodeType():NodeType {
        return NodeType.Comment;
    }

    // @see https://dom.spec.whatwg.org/#concept-node-length
    private override function get_length() {
        return nodeValue.length;
    }

}