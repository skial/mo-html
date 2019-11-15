package uhx.mo.html.parsing;

import uhx.mo.dom.nodes.*;
import uhx.mo.html.internal.Tag;
import uhx.mo.html.tree.Construction;

enum FormatType {
    Formatting(node:Element);
    Marker(node:Element);
}

private enum abstract ReconstructPhase(Int) to Int from Int {
    public var Rewind = 0;
    public var Advance;
    public var Create;
}

/**
    @see https://html.spec.whatwg.org/multipage/parsing.html#the-list-of-active-formatting-elements
**/
abstract FormattingElements(Array<FormatType>) from Array<FormatType> {
    
    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#list-of-active-formatting-elements
    **/
    public inline function new() this = [];

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#push-onto-the-list-of-active-formatting-elements
    **/
    public function push(v:FormatType) {
        if (this.length > 2) {
            // This is the Noah's Ark clause. But with three per family instead of two.

            var lastMarker = -1;
            var length = (this.length-1);
            for (index in 0...this.length) if (this[length-index].match(Marker(_))) {
                lastMarker = index;
                break;
            }

            var start = 0;
            var end = this.length-3;

            if (lastMarker > -1) {
                if (lastMarker + 3 <= this.length) {
                    start = lastMarker;
                    end = lastMarker + 3;

                }

            }

            for (index in start...end) {
                switch [this[index], v] {
                    case [Formatting(n1) | Marker(n1), Formatting(n2) | Marker(n2)]:
                        var check = 
                            n1.nodeName == n2.nodeName && 
                            n1.nodeType == n2.nodeType &&
                            n1.attributes.length == n2.attributes.length &&
                            n1.namespaceURI == n2.namespaceURI;


                        if (!check) continue;
                        
                        /**
                            For these purposes, the attributes must be compared as they were 
                            when the elements were created by the parser; two elements have 
                            the same attributes if all their parsed attributes can be paired 
                            such that the two attributes in each pair have identical names, 
                            namespaces, and values (the order of the attributes does not matter).
                        **/
                        var exists = false;
                        for (attrA in n1.attributes) {
                            exists = false;
                            for (attrB in n2.attributes) if (attrA.name == attrB.name && attrA.value == attrB.value) {
                                exists = true;
                                break;
                            }

                            if (!exists) break;
                        }

                        if (exists) {
                            this.splice(index, index+1);

                        }
                        
                        break;

                    case _:
                        break;

                }

            }

        }

        this.push(v);
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#reconstruct-the-active-formatting-elements
    **/
    public function reconstruct():Void {
        if (this.length == 0) return;
        
        var entry = this.length - 1;
        
        switch this[entry] {
            case Marker(_): return;
            case Formatting(e) if (Construction.current.openElements.indexOf(e.id) > -1): return;
            case _:
        }
        
        var state:ReconstructPhase = Rewind;
        while (entry > -1 && entry < this.length-1) {
            switch state {
                case Rewind:
                    if (entry == 0) {
                        state = Create;

                    } else {
                        entry = entry-1;
                        switch this[entry] {
                            case Marker(_):
                                state = Rewind;

                            case Formatting(e) if (Construction.current.openElements.indexOf(e.id) > -1):
                                state = Rewind;

                            case _:

                        }
                    }

                case Advance:
                    entry++;

                case Create:
                    switch this[entry] {
                        case Marker(e):
                            this[entry] = Marker( 
                                Construction.current.insertHtmlElement({
                                    name:e.nodeName, 
                                    attributes:[for (a in e.attributes.self()) { name:a.name, value:a.value }], 
                                    selfClosing:false
                                }) );

                        case Formatting(e):
                            this[entry] = Formatting( 
                                Construction.current.insertHtmlElement({
                                    name:e.nodeName, 
                                    attributes:[for (a in e.attributes.self()) { name:a.name, value:a.value }], 
                                    selfClosing:false
                                }) );
                    }

                    if (entry != this.length-1) state = Advance;

            }
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#clear-the-list-of-active-formatting-elements-up-to-the-last-marker
    **/
    public function clear():Void {
        while (true) {
            switch this.pop() {
                case Marker(_) | null: break;
                case _:
            }

        }
    }

}