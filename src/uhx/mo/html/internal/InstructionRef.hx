package uhx.mo.html.internal;

class InstructionRef extends Ref<Array<String>> {
	
	public var isComment(default, null):Bool;
	
	public function new(value:Array<String>, ?isComment:Bool = true, ?parent:Node) {
		super(value, parent);
		this.isComment = isComment;
	}
	
	// @see https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode
	// `parent` should be null as the element isnt attached to any document.
	override public function clone(deep:Bool) {
		return new InstructionRef(deep ? value.copy() : value, isComment, null);
	}

    override public function get_length() return value.length;
    override public function get_nodeType() return NodeType.Comment;
    override public function get_nodeName() return '#' + (isComment ? 'comment' : 'instruction');
    override public function get_nodeValue() return value.join('');
	
}