package uhx.mo.dom.nodes;

import uhx.mo.html.tree.NodePtr;
import be.ds.interfaces.IIdentity;
import be.ds.interfaces.IComparable;

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

}