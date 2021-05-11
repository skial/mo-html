package uhx.mo.html.internal;

// TODO use https://github.com/skial/html.content-categories instead.
// @see http://www.w3.org/html/wg/drafts/html/master/dom.html#content-models
enum abstract Category(Int) from Int to Int {
	public var Unknown = -1;
	public var Metadata = 0;
	public var Flow = 1;
	public var Sectioning = 2;
	public var Heading = 3;
	public var Phrasing = 4;
	public var Embedded = 5;
	public var Interactive = 6;
	public var Palpable = 7;
	public var Scripted = 8;
	public var Root = 9;
}