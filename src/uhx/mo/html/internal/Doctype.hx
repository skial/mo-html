package uhx.mo.html.internal;

/**
@see https://html.spec.whatwg.org/multipage/parsing.html#force-quirks-flag
---
DOCTYPE tokens have a name, a public identifier, a system 
identifier, and a force-quirks flag. When a DOCTYPE token is created, its 
name, public identifier, and system identifier must be marked as missing 
(which is a distinct state from the empty string), and the force-quirks 
flag must be set to off (its other state is on)
**/

/**
Null<T> is used to indicate `missing`.
**/

//
@:structInit
class Doctype {
	public var name:Null<String>;
	public var publicId:Null<String>;
	public var systemId:Null<String>;
	public var forceQuirks:Bool;

	public inline function new(?name:Null<String>, ?publicId:Null<String>, ?systemId:Null<String>, forceQuirks:Bool = false) {
		this.name = name;
		this.publicId = publicId;
		this.systemId = systemId;
		this.forceQuirks = forceQuirks;
	}
}