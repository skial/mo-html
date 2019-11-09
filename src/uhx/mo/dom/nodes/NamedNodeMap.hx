package uhx.mo.dom.nodes;

import uhx.mo.dom.nodes.Attr;

// @:see https://dom.spec.whatwg.org/#namednodemap
@:forward(length, iterator, iterable)
abstract NamedNodeMap(Array<Attr>) {

    // Bypass `NamedNodeMap` to access raw array.
    @:noCompletion public inline function self():Array<Attr> {
        return this;
    }

    public inline function new(v) this = v;

    // @:see https://dom.spec.whatwg.org/#dom-namednodemap-item
    @:arrayAccess public inline function item(index:Int):Null<Attr> {
        return index >= this.length ? null : this[index];
    }

}