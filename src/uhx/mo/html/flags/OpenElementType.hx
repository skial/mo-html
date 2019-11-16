package uhx.mo.html.flags;

enum abstract OpenElementType(Int) from Int to Int {
    public var Special = FormatType.Marker + 1;
    public var Formatting;
    public var Ordinary;
}