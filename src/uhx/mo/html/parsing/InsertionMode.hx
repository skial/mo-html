package uhx.mo.html.parsing;

// @see https://html.spec.whatwg.org/multipage/parsing.html#the-insertion-mode
enum abstract InsertionMode(Int) to Int {
    public var Initial = 0;
    public var BeforeHtml;
    public var BeforeHead;
    public var InHead;
    public var InHeadNoScript;
    public var AfterHead;
    public var InBody;
    public var Text;
    public var InTable;
    public var InTableText;
    public var InCaption;
    public var InColumnGroup;
    public var InTableBody;
    public var InRow;
    public var InCell;
    public var InSelect;
    public var InSelectInTable;
    public var InTemplate;
    public var AfterBody;
    public var InFrameset;
    public var AfterFrameset;
    public var AfterAfterBody;
    public var AfterAfterFrameset;
}