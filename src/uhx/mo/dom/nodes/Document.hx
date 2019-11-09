package uhx.mo.dom.nodes;

import uhx.mo.dom.Tree;
import be.ds.util.Counter;
import uhx.mo.xml.Grammer;
import uhx.mo.infra.Namespaces;
import uhx.mo.html.tree.NodePtr;

/**
    @see https://html.spec.whatwg.org/multipage/dom.html#the-document-object
    @see https://dom.spec.whatwg.org/#interface-document
**/
@:using(uhx.mo.dom.nodes.Document.DocumentUtil)
class Document extends BaseNode {

    // @see https://dom.spec.whatwg.org/#node-trees
    @:noCompletion public var tree:Tree;

    public function new(?tree:Tree) {
        id = Counter.next();
        this.tree = tree == null ? new Tree() : tree;
        super(null);
    }

    // Node.hx

    private override function get_nodeName() {
        return '#document';
    }

    private override function get_nodeType() {
        return NodeType.Document;
    }

    private override function get_nodeValue() {
        return null;
    }

    // Non? idl fields.
    // @see https://dom.spec.whatwg.org/#concept-document-encoding

    public var encoding:String;
    public var type:String;
    public var mode:String = 'no-quirks';

    // Interface Document specific
    // @see https://dom.spec.whatwg.org/#interface-document

    public var url:String;
    public var documentURI:String;
    public var origin:String;
    public var compatMode:String;
    public var characterSet:String;
    public var charset:String; // historical alias of .characterSet
    public var inputEncoding:String; // historical alias of .characterSet
    public var contentType:String;

    public var doctype:Null<DocumentType>;
    /**
        @see https://dom.spec.whatwg.org/#document-element
        The document element of a document is the element whose parent is that document, 
        if it exists, and null otherwise.
    **/
    public var documentElement:Null<Element>;

    // @see https://dom.spec.whatwg.org/#dom-document-createelement
    public function createElement(localName:String, ?options:{is:String}):Element {
        // If localName does not match the Name production, then throw an "InvalidCharacterError" DOMException.
        if (!Grammer.Name.match(localName)) throw 'InvalidCharacterError: DOMException';
        // If the context object is an HTML document, then set localName to localName in ASCII lowercase.
        // NOTE: This is currently only intends to deal with html, so default true.
        localName = localName.toLowerCase();
        // Let is be null.
        var is = null;
        // If options is a dictionary and options’s is is present, then set is to it.
        if (options != null && options.is != null) is = options.is;
        // Let namespace be the HTML namespace, if the context object is an HTML document or context object’s content type is "application/xhtml+xml", and null otherwise.
        // NOTE: Only dealing with html.
        var namespace = Namespaces.HTML;
        return DocumentUtil.createAnElement(this, localName, namespace, null, is, false);
    }

    // @see https://dom.spec.whatwg.org/#dom-document-adoptnode
    public function adoptNode(node:Node):Node {
        if (node.nodeType == NodeType.Document) throw 'NotSupportedError';
        // TODO handle shadow root.
        DocumentUtil.adopt(node, this);
        return node;
    }

}

class DocumentUtil {

    // @see https://dom.spec.whatwg.org/#concept-create-element
    public static function createAnElement(document:Document, localName:String, namespace:String, ?prefix:Null<String>, ?is:Null<String>, ?syncCustomFlag:Bool = false):Element {
        var result = null;
        // Let definition be the result of looking up a custom element definition given document, namespace, localName, and is.
        // NOTE: custom elements currently not supported.
        var definition = null;
        // NOTE: Skip to 7. in spec.
        result = new Element(prefix, localName, 'uncustomized', null, is, document);
        return result;
    }

    // @see https://dom.spec.whatwg.org/#concept-element-attributes-get-by-name
    public static function getAnAttributeByName(qualifiedName:String, element:Element):Null<Attr> {
        // 1. If element is in the HTML namespace and its node document is an HTML document, then set qualifiedName to qualifiedName in ASCII lowercase.
        // NOTE: This step is skipped for now. Assumed html context.
        for (attribute in element.attributes) {
            // 2. Return the first attribute in element’s attribute list whose qualified name is qualifiedName, and null otherwise.
            if (attribute.name == qualifiedName) return attribute;
        }

        return null;
    }

    // @see https://dom.spec.whatwg.org/#concept-node-adopt
    public static function adopt(node:Node, document:Document) {
        var oldDocument = node.ownerDocument;
        if (node.parent != null) document.tree.removeEdge(node.parent, node);
        if (document.id != oldDocument.id) {
            node.ownerDocument = document;
            for (descendant in node.childNodes) {
                descendant.ownerDocument = document;
                if (descendant.nodeType == NodeType.Element) {
                    for (attr in (cast descendant:Element).attributes) {
                        attr.ownerDocument = document;

                    }

                }

            }

            // TODO handle custom elements
            // TODO handle shadow dom descendants

        }

    }

}