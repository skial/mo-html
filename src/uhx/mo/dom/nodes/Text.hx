package uhx.mo.dom.nodes;

import be.ds.util.Counter;
import uhx.mo.html.tree.NodePtr;

// @:see https://dom.spec.whatwg.org/#text
class Text extends BaseNode {

    public var data:String;

    public function new(data:String = '', ?document:Document) {
        this.nodeName = '#text';
        this.nodeType = NodeType.Text;
        this.data = data;
        super(document);
    }

    // Node.hx

    private override function get_nodeName():String {
        return '#text';
    }

    private override function get_nodeType():NodeType {
        return NodeType.Text;
    }

    private override function get_nodeValue():Null<String> {
        return this.data;
    }

    /**
        TODO:
        `+=` operator, obviously sends in `data` and `v`. The
        `replaceData` algo only deals with new values.
    **/
    private override function set_nodeValue(v:Null<String>) {
        if (v == null) v = '';
        this.replaceData(0, length, v);
        return this.data;
    }

    // @see https://dom.spec.whatwg.org/#concept-node-length
    private override function get_length() {
        return data.length;
    }

}