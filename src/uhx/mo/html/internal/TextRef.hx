package uhx.mo.html.internal;

import uhx.mo.html.internal.NodeType;

class TextRef extends Ref<String> {
	
    public function new(value:String, ?parent:Node) {
		super(value, parent);
	}
	
	// @see https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode
	// `parent` should be null as the element isnt attached to any document.
	override public function clone(deep:Bool) {
		return new TextRef(value, null);
	}

    override public function get_length() return value.length;
    override public function get_nodeType() return Text;
    override public function get_nodeName() return '#text';
    override public function get_nodeValue() return value;
	
}