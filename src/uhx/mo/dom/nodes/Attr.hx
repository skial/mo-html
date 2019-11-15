package uhx.mo.dom.nodes;

import be.ds.util.Counter;
import uhx.mo.html.tree.NodePtr;

// @see https://dom.spec.whatwg.org/#attr
// @see https://developer.mozilla.org/en-US/docs/Web/API/Attr
class Attr extends BaseNode {

    public function new(name:String, ?namespace:String, ?prefix:String, ?value:String = '', ?element:Element) {
        this.name = name;
        this.namespaceURI = namespace;
        this.prefix = prefix;
        this.ownerElement = element;
        this.value = value;
        super(element.ownerDocument);
    }

    // Node.hx

    private override function get_nodeName():String {
        return this.name;
    }

    private override function get_nodeType():NodeType {
        return NodeType.Attribute;
    }

    private override function get_nodeValue():Null<String> {
        return this.value;
    }

    // Attr
    // @see https://dom.spec.whatwg.org/#attr

    public var namespaceURI(get, null):Null<String>;
    public var prefix(get, null):Null<String>;
    public var localName(get, null):String;
    public var name(get, null):String;
    public var value(get, null):String;
    public var ownerElement(get, null):Null<Element>;
    public var specified:Bool = true;

    private inline function get_namespaceURI():Null<String> {
        return this.namespaceURI;
    }

    private inline function get_prefix():Null<String> {
        return this.prefix;
    }

    private inline function get_localName():String {
        return this.localName;
    }

    private inline function get_name():String {
        return qualifiedName();
    }

    private inline function get_value():String {
        return this.value;
    }

    private inline function get_ownerElement():Null<Element> {
        return this.ownerElement;
    }

    // @see https://dom.spec.whatwg.org/#concept-element-qualified-name
    public function qualifiedName():String {
        return prefix == null ? localName : '$prefix:$localName';
    }

}