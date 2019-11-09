package uhx.mo.dom.nodes;

import be.ds.util.Counter;
import uhx.mo.html.tree.NodePtr;

// @:see https://dom.spec.whatwg.org/#documenttype
class DocumentType extends BaseNode {

    public function new(name:String = '', publicId:String = '', systemId:String = '') {
        this.name = name;
        this.publicId = publicId;
        this.systemId = systemId;
        super(null);
    }

    // Node.hx

    private override function get_nodeName():String {
        return this.name;
    }

    private override function get_nodeType():NodeType {
        return NodeType.DocumentType;
    }

    private override function get_nodeValue():Null<String> {
        return null;
    }

    // @see https://dom.spec.whatwg.org/#concept-node-length
    private override function get_length() {
        return 0;
    }

    // DocumentType
    // @:see https://dom.spec.whatwg.org/#documenttype

    public var name(default, null):String;
    public var publicId(default, null):String;
    public var systemId(default, null):String;

}