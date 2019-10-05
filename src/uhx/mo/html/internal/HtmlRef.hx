package uhx.mo.html.internal;

import haxe.ds.StringMap;
import uhx.mo.html.internal.NodeType;

private typedef Tokens = Array<Token<Node>>;

class HtmlRef extends Ref<Tokens> {
	
	public var name:String;
	public var selfClosing:Bool = false;
	public var categories:Array<Category> = [];
	public var attributes:StringMap<String> = new StringMap();
	
	public function new(name:String, attributes:StringMap<String>, categories:Array<Category>, values:Tokens, ?parent:Node, ?complete:Bool = false, ?selfClosing:Bool = false) {
		super(values, parent);
		this.name = name;
		this.complete = complete;
		this.attributes = attributes;
		this.categories = categories;
		this.selfClosing = selfClosing;
	}
	
	// @see https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode
	// `parent` should be null as the element isnt attached to any document.
	override public function clone(deep:Bool) {
		return new HtmlRef(
			'$name', 
			[for (k in attributes.keys()) k => attributes.get(k)], 
			categories.copy(), 
			deep ? [/*for (t in tokens) (t:dtx.mo.DOMNode).cloneNode( deep )*/] : [for (t in value) t], 
			null, 
			complete,
			selfClosing
		);
	}

    override public function get_length() return value.length;
    override public function get_nodeType() return Element;
    override public function get_nodeName() return name.toUpperCase();
    override public function get_nodeValue() return null;
	
}