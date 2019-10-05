package uhx.mo.html.internal;

/**
 Start and end tag tokens have a tag `name`, a `self-closing` flag, 
 and a list of `attribute`'s, each of which has a name and a value. 
 When a start or end tag token is created, its `self-closing` flag 
 must be unset (its other state is that it be set), and its 
 `attribute`'s list must be empty
**/

//
@:structInit
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