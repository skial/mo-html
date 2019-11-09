package uhx.mo.dom.nodes;

enum abstract NodeType(Int) from Int to Int {
	public var Unknown = 0;
	public var Element = 1;
	public var Attribute = 2;
	public var Text = 3;
	public var CDataSection = 4;
	// Historical
	public var EntityReference = 5;
	// Historical
	public var Entity = 6;
	public var ProcessingInstruction = 7;
	public var Comment = 8;
	public var Document = 9;
	public var DocumentType = 11;
	public var DocumentFragment = 11;
	// Historical
	public var Notation = 12;
}