package uhx.mo.html.internal;

import uhx.mo.html.tree.Construction;

/**
 Start and end tag tokens have a tag `name`, a `self-closing` flag, 
 and a list of `attribute`'s, each of which has a name and a value. 
 When a start or end tag token is created, its `self-closing` flag 
 must be unset (its other state is that it be set), and its 
 `attribute`'s list must be empty
**/

//
@:structInit
@:using(uhx.mo.html.internal.Tag.TagUtil)
class Tag {
	
	public var name:String;
	public var selfClosing:Bool;
	public var attributes:Array<Attribute>;

	public inline function new(name:String, selfClosing:Bool, attributes:Array<Attribute>) {
		this.name = name;
		this.selfClosing = selfClosing;
		this.attributes = attributes;
	}
    
}

class TagUtil {

	/**
		@see https://html.spec.whatwg.org/multipage/parsing.html#acknowledge-self-closing-flag
	**/
	public static function acknowledgeSelfClosingFlag(tag:Tag, maker:Construction):Void {
		// TODO: Check against void elements etc.
		// @see https://html.spec.whatwg.org/multipage/parsing.html#parse-error-non-void-html-element-start-tag-with-trailing-solidus
	}

	/**
		@see https://html.spec.whatwg.org/multipage/parsing.html#formatting
	**/
	public inline static function isFormattingElement(tag:Tag):Bool {
		return ['a', 'b', 'big', 'code', 'em', 'font', 'i', 'nobr', 's', 'small', 'strike', 'strong', 'tt', 'u'].indexOf(tag.name) > -1;
	}

}