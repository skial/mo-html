package uhx.mo.dom.nodes;

import bits.Bits;
import uhx.mo.dom.nodes.NodeType;
import uhx.mo.html.tree.NodePtr;

class BaseNode implements Node {

    public var flags:Bits = new Bits();

    public var parentPtr:NodePtr;
    public var firstChildPtr:NodePtr;
    public var lastChildPtr:NodePtr;
    public var previousSiblingPtr:NodePtr;
    public var nextSiblingPtr:NodePtr;
    // @see https://infra.spec.whatwg.org/#ordered-set
    public var childrenPtr:Array<NodePtr> = [];

    // Node.hx

    public var id:Int;
    // TODO look into parent being a pointer into the graph.
    public var parent(get, set):Null<Node>;
    public var parentNode(get, null):Null<Node>;
    public var parentElement(get, null):Null<Element>;
    // TODO look into childNodes being an array of pointers into the graph.
    public var childNodes(get, null):NodeList;
    public var firstChild(get, null):Null<Node>;
    public var lastChild(get, null):Null<Node>;
    public var previousSibling(get, null):Null<Node>;
    public var nextSibling(get, null):Null<Node>;
    public var length(get, null):Int;
    public var nodeName(get, null):String;
    public var nodeType(get, null):NodeType;
    @:isVar public var nodeValue(get, set):Null<String>;
    public var textContent(get, set):Null<String>;
    public var baseURI(get, null):String;
    public var isConnected(get, null):Bool;
    @:isVar public var ownerDocument(get, set):Null<Document>;

    private inline function get_parent():Null<Node> {
        return parentPtr != null ? parentPtr.get() : null;
    }

    private inline function set_parent(v:Null<Node>):Null<Node> {
        if (v != null) parentPtr = v;
        return v;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-parentnode
    private inline function get_parentNode() {
        return parent;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-parentelement
    private inline function get_parentElement() {
        return parent.nodeType == NodeType.Element ? cast parent : null;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-childnodes
    private inline function get_childNodes():NodeList {
        return childrenPtr;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-firstchild
    private inline function get_firstChild() {
        return childrenPtr.length > 0 ? childrenPtr[0].get() : null;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-lastchild
    private inline function get_lastChild() {
        return childrenPtr.length > 0 ? childrenPtr[childrenPtr.length-1].get() : null;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-previoussibling
    private inline function get_previousSibling() {
        return if (parentPtr != null) {
            var parent = parentPtr.get();
            var index = parent.childrenPtr.indexOf(id);
            index-1 > 0 
                ? parent.childrenPtr[index-1].get()
                : null;

        } else {
            null;

        }
    }

    // @see https://dom.spec.whatwg.org/#dom-node-nextsibling
    private inline function get_nextSibling() {
        return if (parentPtr != null) {
            var parent = parentPtr.get();
            var index = parent.childrenPtr.indexOf(id);
            index != -1 && index+1 < parent.childrenPtr.length 
                ? parent.childrenPtr[index+1].get()
                : null;

        } else {
            null;

        }
    }

    // @see https://dom.spec.whatwg.org/#concept-node-length
    private function get_length() {
        return childrenPtr.length;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-nodename
    private function get_nodeName() {
        return throw 'Not Implemented';
    }

    // @see https://dom.spec.whatwg.org/#dom-node-nodetype
    private function get_nodeType() {
        return throw 'Not Implemented';
    }

    // @see https://dom.spec.whatwg.org/#dom-node-nodevalue
    private function get_nodeValue() {
        return null;
    }

    private function set_nodeValue(v) {
        if (v == null) v = '';
        // TODO
        return nodeValue;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-textcontent
    public inline function get_textContent() {
        return '';
    }

    public inline function set_textContent(v) {
        return v;
    }

    // @See https://dom.spec.whatwg.org/#dom-node-baseuri
    private inline function get_baseURI() {
        return ownerDocument.baseURI;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-ownerdocument
    private inline function get_ownerDocument() {
        return ownerDocument;
    }

    private inline function set_ownerDocument(v:Document):Null<Document> {
        return ownerDocument = v;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-isconnected
    private inline function get_isConnected() {
        // TODO
        return false;
    }

    // @see https://dom.spec.whatwg.org/#concept-node-document
    public function new(nodeDocument:Document) {
        this.ownerDocument = nodeDocument;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-getrootnode
    public function getRootNode(?options:{composed:Bool}):Node {
        // TODO
        return this;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-haschildnodes
    public function hasChildNodes():Bool {
        return childrenPtr.length > 0;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-normalize
    public function normalize():Void {

    }

    // @see https://dom.spec.whatwg.org/#dom-node-clonenode
    public function cloneNode(deep:Bool = false):Node {
        return this;
    }

    /**
        @see https://dom.spec.whatwg.org/#dom-node-isequalnode
        The isEqualNode(otherNode) method, when invoked, must return true 
        if otherNode is non-null and context object equals otherNode, and 
        false otherwise.
    **/
    public inline function isEqualNode(?otherNode:Node):Bool {
        return otherNode != null && this.equals(otherNode);
    }

    /**
        @see https://dom.spec.whatwg.org/#dom-node-issamenode
        The isSameNode(otherNode) method, when invoked, must return true if 
        otherNode is context object, and false otherwise.
    **/
    public inline function isSameNode(?otherNode:Node):Bool {
        return this.id == otherNode.id;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-comparedocumentposition
    public function compareDocumentPosition(other:Node):Int {
        return -1;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-contains
    public function contains(?other:Node):Bool {
        if (other == null) return false;
        return false;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-lookupprefix
    public function lookupPrefix(?namespace:String):Null<String> {
        return null;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-lookupnamespaceuri
    public function lookupNamespaceURI(?prefix:String):Null<String> {
        return null;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-isdefaultnamespace
    public function isDefaultNamespace(?namespace:String):Bool {
        return false;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-insertbefore
    public function insertBefore(node:Node, ?child:Node):Node {
        return this;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-appendchild
    public function appendChild(node:Node):Node {
        return node.append(this);
    }

    // @see https://dom.spec.whatwg.org/#dom-node-replacechild
    public function replaceChild(node:Node, child:Node):Node {
        return this;
    }

    // @see https://dom.spec.whatwg.org/#dom-node-removechild
    public inline function removeChild(child:Node):Node {
        return child.preRemove(this);
    }

    public function compare(other:Node):Bool {
        return other.id == id;
    }

}