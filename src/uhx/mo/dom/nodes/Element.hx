package uhx.mo.dom.nodes;

import be.ds.util.Counter;
import uhx.mo.html.tree.NodePtr;

// @see https://dom.spec.whatwg.org/#element
@:using(uhx.mo.dom.nodes.Element.ElementUtil)
class Element extends BaseNode {

    public function new(?prefix:String, ?localName:String, customElementState:String = 'uncustomized', ?customElementDefinition:{}, ?is:String, document:Document) {
        this.prefix = prefix;
        this.localName = localName;
        this.tagName = '';
        this.attributes = new NamedNodeMap([]);
        super(document);
    }

    // Node.hx

    private override function get_nodeName():String {
        return this.tagName;
    }

    private override function get_nodeType():NodeType {
        return NodeType.Element;
    }

    // Element
    // @see https://dom.spec.whatwg.org/#element

    public var namespaceURI(get, null):Null<String>;
    public var prefix(get, null):Null<String>;
    public var localName(default, null):String = '';
    public var tagName(get, null):String;
    public var attributes(default, null):NamedNodeMap;

    private inline function get_namespaceURI():Null<String> {
        return this.namespaceURI;
    }

    private inline function get_prefix():Null<String> {
        return this.prefix;
    }

    private inline function get_tagName():String {
        return HTMLUppercasedQualifiedName();
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-element-qualified-name
        An element’s qualified name is its local name if its namespace prefix is null, 
        and its namespace prefix, followed by ":", followed by its local name, otherwise.
    */
    public inline function qualifiedName():String {
        return prefix == null ? localName : '$prefix:$localName';
    }

    /**
        @see https://dom.spec.whatwg.org/#element-html-uppercased-qualified-name
    **/
    public function HTMLUppercasedQualifiedName():String {
        return qualifiedName().toUpperCase();
    }

}

class ElementUtil {

    /**
        @see https://dom.spec.whatwg.org/#in-a-document-tree
        An element is in a document tree if its root is a document.
    **/
    public static inline function isInADocumentTree(element:Element):Bool {
        return element.root().nodeType == NodeType.Document;
    }

}