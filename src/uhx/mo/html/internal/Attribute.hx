package uhx.mo.html.internal;

/**
	@:see https://html.spec.whatwg.org/multipage/parsing.html#attribute-name-state
	---
	> When the user agent leaves the attribute name state 
	> (and before emitting the tag token, if appropriate), the 
	> complete attribute's name must be compared to the other 
	> attributes on the same token; if there is already an 
	> attribute on the token with the exact same name, then 
	> this is a duplicate-attribute parse error and the new 
	> attribute must be removed from the token.
	--- NOTE ---
	> If an attribute is so removed from a token, it, and 
	> the value that gets associated with it, if any, 
	> are never subsequently used by the parser, and are 
	> therefore effectively discarded. Removing the 
	> attribute in this way does not change its 
	> status as the "current attribute" for 
	> the purposes of the tokenizer, however.
**/
@:structInit
class Attribute {
    
	public var name:String;
	public var value:String;

	public inline function new(name:String, value:String) {
		this.name = name;
		this.value = value;
	}

}