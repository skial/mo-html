package uhx.mo.dom.nodes;

import bits.Bits;
import uhx.mo.dom.nodes.NodeType;
import uhx.mo.html.tree.NodePtr;
import be.ds.interfaces.IIdentity;
import be.ds.interfaces.IComparable;
import uhx.mo.html.internal.HtmlTag;
import uhx.mo.html.internal.Category;

/**
    @see https://dom.spec.whatwg.org/#trees
    @see https://dom.spec.whatwg.org/#node
    ---
    An object that participates in a tree has a parent, 
    which is either null or an object, and has children, 
    which is an ordered set of objects. An object A whose 
    parent is object B is a child of B.
**/
@:remove
@:using(uhx.mo.dom.nodes.Node.NodeUtil)
interface Node extends IComparable<Node> extends IIdentity {

    public var flags:Bits;

    public var parentPtr:NodePtr;
    public var firstChildPtr:NodePtr;
    public var lastChildPtr:NodePtr;
    public var previousSiblingPtr:NodePtr;
    public var nextSiblingPtr:NodePtr;
    // @see https://infra.spec.whatwg.org/#ordered-set
    public var childrenPtr:Array<NodePtr>;

    public var parent(get, set):Null<Node>;
    public var parentNode(get, null):Null<Node>;
    public var parentElement(get, null):Null<Element>;
    public var childNodes(get, null):NodeList;
    public var firstChild(get, null):Null<Node>;
    public var lastChild(get, null):Null<Node>;
    public var previousSibling(get, null):Null<Node>;
    public var nextSibling(get, null):Null<Node>;
    public var length(get, null):Int;
    public var nodeName(get, null):String;
    public var nodeType(get, null):NodeType;
    public var nodeValue(get, set):Null<String>;
    public var textContent(get, set):Null<String>;
    public var baseURI(get, null):String;
    public var isConnected(get, null):Bool;
    public var ownerDocument(get, set):Null<Document>;

    public function getRootNode(?options:{composed:Bool}):Node;
    public function hasChildNodes():Bool;
    public function normalize():Void;
    public function cloneNode(deep:Bool = false):Node;
    public function isEqualNode(?otherNode:Node):Bool;
    public function isSameNode(?otherNode:Node):Bool;

    public function compareDocumentPosition(other:Node):Int;
    public function contains(?other:Node):Bool;

    public function lookupPrefix(?namespace:String):Null<String>;
    public function lookupNamespaceURI(?prefix:String):Null<String>;
    public function isDefaultNamespace(?namespace:String):Bool;

    public function insertBefore(node:Node, ?child:Node):Node;
    public function appendChild(node:Node):Node;
    public function replaceChild(node:Node, child:Node):Node;
    public function removeChild(child:Node):Node;

}

class NodeUtil {

    /**
        @see https://dom.spec.whatwg.org/#concept-tree-order
        In tree order is preorder, depth-first traversal of a tree.
    **/
    public static function treeOrder(node:Node):Int {
        return node.id; // TODO be spec complient
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-tree-root
        The root of an object is itself, if its parent is null, or else 
        it is the root of its parent. The root of a tree is any object 
        participating in that tree whose parent is null.
    **/
    public static function root(node:Node):Node {
        return node.parent == null ? node : root(node.parent);
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-tree-preceding
        An object A is preceding an object B if A and B are in the same 
        tree and A comes before B in tree order.
    **/
    public static function isPreceding(nodeA:Node, nodeB:Node):Bool {
        return nodeA.ownerDocument.id == nodeB.ownerDocument.id &&
        treeOrder(nodeA) < treeOrder(nodeB);
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-tree-following
        An object A is following an object B if A and B are in the same 
        tree and A comes after B in tree order.
    **/
    public static function isFollowing(nodeA:Node, nodeB:Node):Bool {
        return nodeA.ownerDocument.id == nodeB.ownerDocument.id &&
        treeOrder(nodeA) > treeOrder(nodeB);
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-tree-child
        An object A whose parent is object B is a child of B.
    **/
    public static inline function isChildOf(nodeA:Node, nodeB:Node):Bool {
        return nodeA.parent != null 
            // Check `id`'s directly if `parent` exists.
            ? nodeA.parent.id == nodeB.id
            // Fallback
            : nodeB.childrenPtr.indexOf( nodeA.id ) > -1;
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-tree-descendant
        An object A is called a descendant of an object B, if 
        either A is a child of B or A is a child of an object C that 
        is a descendant of B.
    **/
    public static function isDescendantOf(nodeA:Node, nodeB:Node):Bool {
        if (nodeA.isChildOf(nodeB)) return true;

        for (nodeC in nodeB.childNodes) if (nodeA.isDescendantOf(nodeC)) {
            return true;
        }

        return false;
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-tree-ancestor
        An object A is called an ancestor of an object B if and only if B 
        is a descendant of A
    **/
    public static inline function isAncestorOf(nodeA:Node, nodeB:Node):Bool {
        return nodeB.isDescendantOf(nodeA);
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-tree-inclusive-descendant
        An inclusive descendant is an object or one of its descendants.
    **/
    public static inline function isInclusiveDescendantOf(node:Node, parent:Node):Bool {
        return node.id == parent.id || isDescendantOf(node, parent);
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-tree-inclusive-ancestor
        An inclusive ancestor is an object or one of its ancestors.
    **/
    public static inline function isInclusiveAncestorOf(node:Node, ancestor:Node):Bool {
        return node.id == ancestor.id || isAncestorOf(node, ancestor);
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-tree-index
        The index of an object is its number of preceding siblings, or 0 if it 
        has none.
    **/
    public static inline function index(node:Node):Int {
        return node.parent != null && node.parent.childrenPtr.length > 1 
            ? node.parent.childrenPtr.indexOf(node.id) 
            : 0;
    }

    // @see https://dom.spec.whatwg.org/#concept-tree-host-including-inclusive-ancestor
    public static function hostIncludingInclusiveAncestor(a:Node, b:Node):Bool {
        var root:Node = null;
        return isInclusiveAncestorOf(b, a) || 
        ((root = b.root()) != null && a.hostIncludingInclusiveAncestor(root));
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-node-ensure-pre-insertion-validity
    **/
    public static function ensurePreInsertionValidity(node:Node, parent:Node, child:Node) {
        if (parent.nodeType != NodeType.Document || parent.nodeType != NodeType.DocumentFragment || parent.nodeType != NodeType.Element) {
            throw 'HierarchyRequestError';
        }

        if (hostIncludingInclusiveAncestor(node, parent)) {
            throw 'HierarchRequestError';
        }

        if (child != null && child.parent.id != parent.id) {
            throw 'NotFoundError';
        }

        if ([NodeType.DocumentFragment, NodeType.DocumentType, NodeType.Element, NodeType.Text, NodeType.ProcessingInstruction, NodeType.Comment].indexOf(node.nodeType) == -1) {
            throw 'HierarchyRequestError';
        }

        if ((node.nodeType == NodeType.Text && parent.nodeType == NodeType.Document) || (node.nodeType == NodeType.DocumentType && parent.nodeType != NodeType.Document)) {
            throw 'HierarchyRequestError';
        }

        if (parent.nodeType == NodeType.Document) {
            if (node.nodeType == NodeType.DocumentFragment) {
                var hasElements = 0;
                var hasText = false;

                for (child in node.childNodes) {
                    if (child.nodeType == NodeType.Element) hasElements++;
                    hasText = child.nodeType == NodeType.Text;
                    if (hasText || hasElements > 1) break;
                }

                if (hasText || hasElements > 1) throw 'HierarchyRequestError';
                if (hasElements == 1 && (
                    [for (n in parent.childNodes) if (n.nodeType == NodeType.Element) n].length > 0 ||
                    child.nodeType == NodeType.DocumentType ||
                    child != null && child.nextSibling != null && child.nextSibling.nodeType == NodeType.DocumentType
                )) throw 'HierarchyRequestError';

            } else if (node.nodeType == NodeType.Element) {
                if (
                    [for (n in parent.childNodes) if (n.nodeType == NodeType.Element) n].length > 0 ||
                    child.nodeType == NodeType.DocumentType ||
                    child != null && child.nextSibling != null && child.nextSibling.nodeType == NodeType.DocumentType
                ) throw 'HierarchyRequestError';

            } else if (node.nodeType == NodeType.DocumentType) {
                if (
                    [for (n in parent.childNodes) if (n.nodeType == NodeType.DocumentType) n].length > 0 ||
                    (child != null && child.previousSibling != null && child.previousSibling.nodeType == NodeType.Element) ||
                    (child == null && [for (n in parent.childNodes) if (n.nodeType == NodeType.Element) n].length > 0)
                ) throw 'HierarchyRequestError';

            }
        }
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-node-pre-insert
    **/
    public static function preInsertNode(node:Node, parent:Node, ?child:Node):Node {
        ensurePreInsertionValidity(node, parent, child);
        var referenceChild = child;

        if (referenceChild != null && referenceChild.id == node.id) {
            node.nextSiblingPtr = referenceChild.id;

        }

        parent.ownerDocument.adoptNode(node);

        return node;
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-node-insert
    **/
    public static function insert(node:Node, parent:Node, child:Node, suppressObservers:Bool = false) {
        // 1. Let count be the number of children of node if it is a DocumentFragment node, and one otherwise.
        var count = node.nodeType == NodeType.DocumentFragment ? node.length : 1;

        // 2. If child is non-null, then:
        if (child != null) {
            // TODO handle this case.

        }

        // 3. Let nodes be node’s children, if node is a DocumentFragment node; otherwise « node ».
        var nodes = node.nodeType == NodeType.DocumentFragment ? node.childNodes.iterator() : [node].iterator();

        // 4. If node is a DocumentFragment node, remove its children with the suppress observers flag set.
        if (node.nodeType == NodeType.DocumentFragment) {
            for (n in nodes) {}
            // TODO mutuation events
        }

        // 5. If node is a DocumentFragment node, then queue a tree mutation record for node with « », nodes, null, and null.

        // 6. Let previousSibling be child’s previous sibling or parent’s last child if child is null.
        var previousSibling = child != null ? child.previousSibling : parent.lastChild;

        // 7. For each node in nodes, in tree order:
        for (n in nodes) {
            // TODO handle this case.
        }

        // 8. If suppress observers flag is unset, then queue a tree mutation record for parent with nodes, « », previousSibling, and child.
    }

    // @see https://dom.spec.whatwg.org/#node-trees
    public static function allowedChild(node:Node, child:Node):Bool {
        if (node.nodeType == NodeType.Document && [NodeType.ProcessingInstruction, NodeType.Comment, NodeType.DocumentType, NodeType.Element].indexOf(child.nodeType) > -1) {
            var doctype = 0;
            var elements = 0;

            for (child in node.childNodes) {
                if (child.nodeType == Element) elements++;
                if (child.nodeType == DocumentType) doctype++;
            }

            return doctype <= 1 && elements <= 1;
        }

        if ((node.nodeType == NodeType.DocumentFragment || node.nodeType == NodeType.Element) && [NodeType.ProcessingInstruction, NodeType.Comment, NodeType.Text, NodeType.Element].indexOf(child.nodeType) > -1) {
            return true;
        }

        return false;
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-node-empty
        A node is considered empty if its length is zero.
    **/
    public static inline function isEmpty(node:Node):Bool {
        return node.length == 0;
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-node-equals
    **/
    public static function equals(nodeA:Node, nodeB:Node):Bool {
        if (nodeA.nodeType != nodeB.nodeType) return false;

        var check = switch nodeA.nodeType {
            case NodeType.DocumentType:
                var docA = (cast nodeA:DocumentType);
                var docB = (cast nodeB:DocumentType);
                docA.name == docB.name &&
                docA.publicId == docB.publicId &&
                docA.systemId == docB.systemId;

            case NodeType.Element:
                var eleA = (cast nodeA:Element);
                var eleB = (cast nodeB:Element);
                eleA.namespaceURI == eleB.namespaceURI &&
                eleA.prefix == eleB.prefix &&
                eleA.localName == eleB.localName &&
                eleA.attributes.length == eleB.attributes.length;

            case NodeType.Attribute:
                var attrA = (cast nodeA:Attr);
                var attrB = (cast nodeB:Attr);
                attrA.namespaceURI == attrB.namespaceURI &&
                attrA.localName == attrB.localName &&
                attrA.value == attrB.value;

            case NodeType.ProcessingInstruction:
                var proA = (cast nodeA:ProcessingInstruction);
                var proB = (cast nodeB:ProcessingInstruction);
                proA.nodeName == proB.nodeName && proA.nodeValue == proB.nodeValue;

            case NodeType.Text, NodeType.Comment:
                nodeA.nodeValue == nodeB.nodeValue;

            case _:
                false;
        }

        if (!check) return false;

        if (nodeA.nodeType == NodeType.Element) {
            var eleA = (cast nodeA:Element).attributes.self();
            var eleB = (cast nodeB:Element).attributes.self();

            for (attrA in eleA) {
                var exists = false;

                for (attrB in eleB) if (attrA.equals(attrB)) {
                    exists = true;
                    break;
                }

                if (!exists) return false;
                
            }

        }

        if (nodeA.childrenPtr.length != nodeB.childrenPtr.length) return false;

        for (index in 0...nodeA.childrenPtr.length) {
            var childA = nodeA.childrenPtr[index].get();
            var childB = nodeB.childrenPtr[index].get();
            if (!childA.equals(childB)) return false;

        }

        return true;

    }

    /**
        Non spec helper
        @see https://html.spec.whatwg.org/multipage/parsing.html#special
    **/
    public static function categoryType(node:Node):Int {
        return switch node.nodeName {
            case 'address' | 'applet' | 'area' | 'article' | 'aside' | 'base' | 'basefont' | 'bgsound'
                | 'blockquote' | 'body' | 'br' | 'button' | 'caption' | 'center' | 'col' | 'colgroup'
                | 'dd' | 'details' | 'dir' | 'div' | 'dl' | 'dt' | 'embed' | 'fieldset'
                | 'figcaption' | 'figure' | 'footer' | 'form' | 'frame' | 'frameset' 
                | 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' | 'head' | 'header' | 'hgroup'
                | 'iframe' | 'img' | 'input' | 'keygen' | 'li' | 'link' | 'listing' | 'main'
                | 'marquee' | 'menu' | 'meta' | 'nav' | 'noembed' | 'noframes' | 'noscript'
                | 'object' | 'ol' | 'p' | 'param' | 'plaintext' | 'pre' | 'script' | 'section'
                | 'select' | 'source' | 'style' | 'summary' | 'table' | 'tbody' | 'td'
                | 'tempalte' | 'textarea' | 'tfoot' | 'th' | 'thead' | 'title' | 'tr' | 'track'
                | 'ul' | 'wbr' | 'xmp' | /**mathml**/ 'mi' | 'mo' | 'mn' | 'ms' | 'mtext' 
                | 'annotation-xml' | /**svg**/ 'foreignObject' | 'desc' /*| 'title'*/:
                0;  /**special**/
            case 'a' | 'b' | 'big' | 'code' | 'em' | 'font' | 'i' | 'nobr' | 's' | 'small' | 'strike' | 'strong' | 'tt' | 'u':
                1;  /**formatting**/
            case _:
                2;  /**ordinary**/
        }
        
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-node-pre-remove
    **/
    public static function preRemove(child:Node, parent:Node):Node {
        if (child.parentPtr != null && child.parentPtr != parent.id) {
            throw 'NotFoundError';

        }
        remove(child, parent);
        return child;
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-node-remove
    **/
    public static function remove(node:Node, parent:Node) {
        //var index = node.index();
        // TODO: steps 2-5
        // TODO: step 6
        var oldPreviousSibling = node.previousSiblingPtr;
        var oldNextSibling = node.nextSiblingPtr;
        parent.childrenPtr.remove(node.id);
        // TODO: step 10
        // TODO: step 11
        // TODO: step 12
        // TODO: step 13 // I don't know what removing steps is...
        // TODO: step 14-18
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-node-append
    **/
    public static inline function append(node:Node, parent:Node):Node {
        return preInsertNode(node, parent, null);
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-cd-replace
    **/
    public static function replaceData<T:{data:String}&Node>(node:T, offset:Int, count:Int, value:String):Void {
        var length = node.length-1;
        if (offset > length) throw 'IndexSizeError';
        if (offset + count > length) count = length - offset;
        // TODO: step 4
        var nodeData = node.data;
        if (offset <= length) {
            nodeData += value;

        } else {
            nodeData = nodeData.substring(0, offset+1) + value;

        }
        // Skip? Step 6 & 7 // Do we need to do this if the above is enough?
        // TODO: step 8-11
        // TODO: step 13
        node.data = nodeData;
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-node-replace
    **/
    public static function replace(child:Node, node:Node, parent:Node) {
        if (parent.nodeType != NodeType.Document || parent.nodeType != NodeType.DocumentFragment || parent.nodeType != NodeType.Element) {
            throw 'HierarchyRequestError';
        }

        if (node.hostIncludingInclusiveAncestor(parent)) {
            throw 'HierarchyRequestError';

        }

        if (child.parentPtr != parent.id) {
            throw 'NotFoundError';

        }

        if ([NodeType.DocumentFragment, NodeType.DocumentType, NodeType.Element, NodeType.Text, NodeType.ProcessingInstruction, NodeType.Comment].indexOf(node.nodeType) == -1) {
            throw 'HierarchyRequestError';

        }

        if (node.nodeType == NodeType.Text || parent.nodeType == NodeType.Document || (node.nodeType == NodeType.DocumentType && parent.nodeType != NodeType.Document)) {
            throw 'HierarchyRequestError';
        }

        if (parent.nodeType == NodeType.Document) {
            switch node.nodeType {
                case NodeType.DocumentFragment:
                    var childTexts = 0;
                    var childElements = 0;
                    for (childPtr in node.childrenPtr) {
                        var child = childPtr.get();
                        if (child.nodeType == NodeType.Element) {
                            childElements++;
                            if (childElements > 1) break;
                            continue;
                        }
                        if (child.nodeType == NodeType.Text) {
                            childTexts++;
                            break;
                        }

                    }

                    if (childElements > 1 || childTexts != 0) {
                        throw 'HierarchyRequestError';
                    }

                    var doctypeSibling = false;
                    var parentElements = 0;
                    for (index in 0...parent.childrenPtr.length) {
                        if (parent.childrenPtr[index] != child.id) {
                            parentElements++;
                            break;
                        } else if (index+1 <= parent.childrenPtr.length-1) {
                            doctypeSibling = parent.childrenPtr[index+1].get().nodeType == NodeType.DocumentType;
                            break;

                        }

                    }
                    
                    if (childElements == 1 && (parentElements != 0 || !doctypeSibling)) {
                        throw 'HierarchyRequestError';

                    }

                case NodeType.Element:
                    var doctypeSibling = false;
                    var parentElements = 0;
                    for (index in 0...parent.childrenPtr.length) {
                        if (parent.childrenPtr[index] != child.id) {
                            parentElements++;
                            break;
                        } else if (index+1 <= parent.childrenPtr.length-1) {
                            doctypeSibling = parent.childrenPtr[index+1].get().nodeType == NodeType.DocumentType;
                            break;

                        }

                    }

                    if (parentElements != 0 || !doctypeSibling) {
                        throw 'HierarchyRequestError';

                    }

                case NodeType.DocumentType:
                    var elementSibling = false;
                    var doctypeElements = 0;
                    for (index in 0...parent.childrenPtr.length) {
                        if (parent.childrenPtr[index] != child.id) {
                            doctypeElements++;
                            break;
                        } else if (index-1 > 0) {
                            elementSibling = parent.childrenPtr[index-1].get().nodeType == NodeType.Element;
                            break;

                        }

                    }

                    if (doctypeElements != 0 || !elementSibling) {
                        throw 'HierarchyRequestError';

                    }

                case _:

            }

        }

        var referenceChild = child.nextSibling;
        if (referenceChild.id == node.id) referenceChild = node.nextSibling;
        var previousChild = child.previousSibling;
        
        node.adopt(parent.ownerDocument);
        var removedNodes = [];
        if (child.parentPtr != null) {
            removedNodes.push(child);
            parent.childrenPtr.remove(child.id); // TODO: set suppress observers flag.
        }
        var nodes = node.nodeType == NodeType.DocumentFragment ? node.childrenPtr : [node.id];
        node.insert(parent, referenceChild, true);
        // TODO: step 15
        return child;
    }

    /**
        @see https://dom.spec.whatwg.org/#concept-node-adopt
    **/
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