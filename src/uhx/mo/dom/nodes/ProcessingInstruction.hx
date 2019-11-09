package uhx.mo.dom.nodes;

import be.ds.util.Counter;
import uhx.mo.html.tree.NodePtr;

// @:see https://dom.spec.whatwg.org/#processinginstruction
class ProcessingInstruction extends BaseNode {

    public function new() {
        this.nodeName = '';
        this.nodeType = NodeType.ProcessingInstruction;
        this.nodeValue = '';
        super(null);
    }

    // Node.hx

    private override function get_nodeName():String {
        return this.target;
    }

    private override function get_nodeType():NodeType {
        return NodeType.ProcessingInstruction;
    }

    private override function get_nodeValue():Null<String> {
        return this.data;
    }

    // @see https://dom.spec.whatwg.org/#concept-node-length
    private override function get_length() {
        return data.length;
    }

    public var data:String;
    public var target:String;

}