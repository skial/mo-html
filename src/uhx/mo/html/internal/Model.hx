package uhx.mo.html.internal;

// TODO also include https://github.com/skial/html.element-kinds
enum abstract Model(Int) from Int to Int {
	public var Empty = 1;
	public var Text = 2;
	public var Element = 3;
}