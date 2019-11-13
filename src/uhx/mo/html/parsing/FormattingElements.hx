package uhx.mo.html.parsing;

import uhx.mo.dom.nodes.Node;
import uhx.mo.html.internal.Tag;

enum FormatType {
    Formatting(tag:Tag, node:Node);
    Marker(tag:Tag, node:Node);
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
        var lastMarker = 0;

        for (index in 0...this.length) if (this[index].match(Marker(_))) {
            lastMarker = index;
            break;
        }

        if (lastMarker + 3 <= this.length) {
            for (index in lastMarker...(lastMarker + 3)) {
                switch (this[index], v) {
                    case [Formatting(t1, n1), Formatting(t2, n2)]:

                    case [Marker(t1, n1), Marker(t2, n2)]:

                    case _:
                        return;

                }

            }

        }

        this.push(v);
    }

}