package uhx.mo.dom.nodes;

import be.ds.util.Counter;
import uhx.mo.html.tree.NodePtr;

// @:see https://dom.spec.whatwg.org/#text
class Text extends BaseNode {

    public function new(data:String = '') {
        this.nodeName = '#text';
        this.nodeType = NodeType.Text;
        this.nodeValue = data;
        super(null);
    }

    // Node.hx

    private override function get_nodeName():String {
        return '#text';
    }

    private override function get_nodeType():NodeType {
        return NodeType.Text;
    }

    // @see https://dom.spec.whatwg.org/#concept-node-length
    private override function get_length() {
        return nodeValue.length;
    }

}