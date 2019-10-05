package uhx.mo.html.internal;

import uhx.mo.html.internal.NodeType;

class Ref<Child> implements Node {
	
    public var id(default, null):Int = be.ds.util.Counter.next();
    public var root:Node;
    public var value:Child;
	public var parent:Null<Node>;
	public var complete:Bool = true;
    public var length(get, null):Int;
    public var nodeType(get, null):NodeType;
    public var nodeName(get, null):String;
    public var nodeValue(get, null):Null<String>;
	
	public function new(value:Child, ?parent:Node) {
        this.value = value;
		this.parent = parent;
	}
	
	// @see https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode
	// `parent` should be null as the element isnt attached to any document.
	public function clone(deep:Bool) {
		return new Ref<Child>(value, null);
	}

    public function get_length() return 0;
    public function get_nodeType() return Unknown;
    public function get_nodeName() return '#unknown';
    public function get_nodeValue() return Std.string(value);

    public function compare(other:Node):Bool {
        return id == other.id;
    }
	
}