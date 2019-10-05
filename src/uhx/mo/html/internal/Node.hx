package uhx.mo.html.internal;

interface Node extends be.ds.IComparable<Node> extends be.ds.IIdentity {

    public var root:Node;
    public var parent:Null<Node>;
    public var length(get, null):Int;
    public var nodeName(get, null):String;
    public var nodeType(get, null):NodeType;
    public var nodeValue(get, null):Null<String>;
    public function clone(deep:Bool):Node;

}