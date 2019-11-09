package uhx.mo.dom.nodes;

import be.ds.util.Counter;
import uhx.mo.html.tree.NodePtr;

// @:see https://dom.spec.whatwg.org/#cdatasection
class CDATASection extends BaseNode {

    public var data:String;

    public function new() {
        super(null);
    }

    // Node.hx

    private override function get_nodeName():String {
        return '#cdata-section';
    }

    private override function get_nodeType():NodeType {
        return NodeType.CDataSection;
    }

    private override function get_nodeValue():Null<String> {
        return null
    }

    private override function set_nodeValue(v) {
        return null;
    }

}