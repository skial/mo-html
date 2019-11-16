package uhx.mo.html.parsing;

import uhx.mo.dom.nodes.Node;
import uhx.mo.html.tree.NodePtr;

/**
    @see https://html.spec.whatwg.org/multipage/parsing.html#stack-of-open-elements
**/
@:forward
@:using(uhx.mo.html.parsing.OpenElements.OpenElementsUtil)
abstract OpenElements(Array<NodePtr>) {

    public inline function new() {
        this = [];
    }

    @:op([]) public inline function get(index:Int):Null<NodePtr> {
        return this[index];
    };

}

class OpenElementsUtil {

    /**
        Common operation
        ---
        Check if there is an element on the stack of open elements with `nodeName`.
    **/
    public static function exists(openElements:OpenElements, nodeName:String):Bool {
        for (ptr in openElements) {
            if (ptr.get().nodeName == nodeName) return true;

        }

        return false;
    }

    /**
        Common operation.
        ---
        Pop elements from the stack of open elements until an HTML element 
        with the same `nodeName` has been popped from the stack.
    **/
    public static function popUntilNamed(openElements:OpenElements, nodeName:String):Void {
        while (openElements.length > 0) {
            var node = openElements.pop().get();
            if (node.nodeName == nodeName) break;
        }
    }

    /**
        Common operation.
        ---
        Pop elements from the stack of open elements until an HTML element 
        with the same `pointer/id` has been popped from the stack.
    **/
    public static function popUntilKnown(openElements:OpenElements, pointer:NodePtr):Void {
        while (openElements.length > 0) {
            var node = openElements.pop().get();
            if (node.id == pointer) break;
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-the-specific-scope
    **/
    public static function hasElementInSpecificScope(openElements:OpenElements, target:String, list:Array<String>):Bool {
        var index = openElements.length - 1;
        var node = openElements[index].get();

        while (true) {
            if (node.nodeName == target) return true;

            if (list.indexOf(node.nodeName) > -1) return false;

            index--;
            node = openElements[index].get();
        }

        return false;
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-scope
    **/
    public static inline function hasElementInScope(openElements:OpenElements, target:String):Bool {
        return hasElementInSpecificScope(
            openElements,
            target, 
            ['applet', 'caption', 'html', 'table', 'td', 'th', 
            'marquee', 'object', 'template', /**mathml**/'mi',
            'mo', 'mn', 'ms', 'mtext', 'annotation-xml', /**svg**/
            'foreignObject', 'desc', 'title']
        );
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-list-item-scope
    **/
    public static inline function hasElementInListItemScope(openElements:OpenElements, target:String):Bool {
        return hasElementInSpecificScope(
            openElements,
            target, 
            ['applet', 'caption', 'html', 'table', 'td', 'th', 
            'marquee', 'object', 'template', /**mathml**/'mi',
            'mo', 'mn', 'ms', 'mtext', 'annotation-xml', /**svg**/
            'foreignObject', 'desc', 'title', /**extra**/'ol', 'ul']
        );
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-button-scope
    **/
    public static inline function hasElementInButtonScope(openElements:OpenElements, target:String):Bool {
        return hasElementInSpecificScope(
            openElements,
            target, 
            ['applet', 'caption', 'html', 'table', 'td', 'th', 
            'marquee', 'object', 'template', /**mathml**/'mi',
            'mo', 'mn', 'ms', 'mtext', 'annotation-xml', /**svg**/
            'foreignObject', 'desc', 'title', /**extra**/'button']
        );
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-table-scope
    **/
    public static inline function hasElementInTableScope(openElements:OpenElements, target:String):Bool {
        return hasElementInSpecificScope(
            openElements,
            target, 
            ['html', 'table', 'template']
        );
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-select-scope
    **/
    public static function hasElementInSelectScope(openElements:OpenElements, target:String):Bool {
        return hasElementInSpecificScope(
            openElements,
            target, 
            /**
                TODO: I have no idea if this is a complete list.
            **/
            ['a', 'abbr', 'address', 'area', 'article', 'aside', 
            'audio', 'b', 'base', 'bdi', 'bdo', 'blockquote', 'body', 
            'br', 'button', 'canvas', 'caption', 'cite', 'code', 
            'col', 'colgroup', 'data', 'datalist', 'dd', 'del', 
            'details', 'dfn', 'dialog', 'div', 'dl', 'dt', 'em', 
            'embed', 'fieldset', 'figcaption', 'figure', 'footer', 
            'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'head', 
            'header', 'hgroup', 'hr', 'html', 'i', 'iframe', 'img', 
            'input', 'ins', 'kbd', 'label', 'legend', 'li', 'link', 
            'main', 'map', 'mark', 'math', 'menu', 'menuitem', 'meta', 
            'meter', 'nav', 'noscript', 'object', 'ol', /*'optgroup', 'option',*/ 
            'output', 'p', 'param', 'picture', 'pre', 'progress', 
            'q', 'rb', 'rp', 'rt', 'rtc', 'ruby', 's', 'samp', 
            'script', 'section', 'select', 'slot', 'small', 
            'source', 'span', 'strong', 'style', 'sub', 'summary', 
            'sup', 'svg', 'table', 'tbody', 'td', 'template', 
            'textarea', 'tfoot', 'th', 'thead', 'time', 'title', 
            'tr', 'track', 'u', 'ul', 'var', 'video', 'wb']
        );
    }

}