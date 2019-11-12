package uhx.mo.html.parsing;

import uhx.mo.infra.Namespaces;
import uhx.mo.dom.Tree;
import uhx.mo.dom.nodes.Node;
import uhx.mo.dom.nodes.Comment;
import uhx.mo.dom.nodes.Element;
import uhx.mo.dom.nodes.Document;
import uhx.mo.dom.nodes.DocumentType;
import uhx.mo.html.tree.Construction;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.parsing.InsertionMode;

using StringTools;

class InsertionRules {

    public var insertionMode:InsertionMode = Initial;
    private var selection:Array<Token<HtmlTokens>->Construction->Void>;

    public function new() {
        selection = [initial, beforeHtml, beforeHead, inHead];
    }

    public inline function process(token:Token<HtmlTokens>, maker:Construction):Void {
        selection[insertionMode](token, maker);
    }

    public static final publicIdStartsWith = [
        "+//Silmaril//dtd html Pro v0r11 19970101//",
        "-//AS//DTD HTML 3.0 asWedit + extensions//",
        "-//AdvaSoft Ltd//DTD HTML 3.0 asWedit + extensions//",
        "-//IETF//DTD HTML 2.0 Level 1//",
        "-//IETF//DTD HTML 2.0 Level 2//",
        "-//IETF//DTD HTML 2.0 Strict Level 1//",
        "-//IETF//DTD HTML 2.0 Strict Level 2//",
        "-//IETF//DTD HTML 2.0 Strict//",
        "-//IETF//DTD HTML 2.0//",
        "-//IETF//DTD HTML 2.1E//",
        "-//IETF//DTD HTML 3.0//",
        "-//IETF//DTD HTML 3.2 Final//",
        "-//IETF//DTD HTML 3.2//",
        "-//IETF//DTD HTML 3//",
        "-//IETF//DTD HTML Level 0//",
        "-//IETF//DTD HTML Level 1//",
        "-//IETF//DTD HTML Level 2//",
        "-//IETF//DTD HTML Level 3//",
        "-//IETF//DTD HTML Strict Level 0//",
        "-//IETF//DTD HTML Strict Level 1//",
        "-//IETF//DTD HTML Strict Level 2//",
        "-//IETF//DTD HTML Strict Level 3//",
        "-//IETF//DTD HTML Strict//",
        "-//IETF//DTD HTML//",
        "-//Metrius//DTD Metrius Presentational//",
        "-//Microsoft//DTD Internet Explorer 2.0 HTML Strict//",
        "-//Microsoft//DTD Internet Explorer 2.0 HTML//",
        "-//Microsoft//DTD Internet Explorer 2.0 Tables//",
        "-//Microsoft//DTD Internet Explorer 3.0 HTML Strict//",
        "-//Microsoft//DTD Internet Explorer 3.0 HTML//",
        "-//Microsoft//DTD Internet Explorer 3.0 Tables//",
        "-//Netscape Comm. Corp.//DTD HTML//",
        "-//Netscape Comm. Corp.//DTD Strict HTML//",
        "-//O'Reilly and Associates//DTD HTML 2.0//",
        "-//O'Reilly and Associates//DTD HTML Extended 1.0//",
        "-//O'Reilly and Associates//DTD HTML Extended Relaxed 1.0//",
        "-//SQ//DTD HTML 2.0 HoTMetaL + extensions//",
        "-//SoftQuad Software//DTD HoTMetaL PRO 6.0::19990601::extensions to HTML 4.0//",
        "-//SoftQuad//DTD HoTMetaL PRO 4.0::19971010::extensions to HTML 4.0//",
        "-//Spyglass//DTD HTML 2.0 Extended//",
        "-//Sun Microsystems Corp.//DTD HotJava HTML//",
        "-//Sun Microsystems Corp.//DTD HotJava Strict HTML//",
        "-//W3C//DTD HTML 3 1995-03-24//",
        "-//W3C//DTD HTML 3.2 Draft//",
        "-//W3C//DTD HTML 3.2 Final//",
        "-//W3C//DTD HTML 3.2//",
        "-//W3C//DTD HTML 3.2S Draft//",
        "-//W3C//DTD HTML 4.0 Frameset//",
        "-//W3C//DTD HTML 4.0 Transitional//",
        "-//W3C//DTD HTML Experimental 19960712//",
        "-//W3C//DTD HTML Experimental 970421//",
        "-//W3C//DTD W3 HTML//",
        "-//W3O//DTD W3 HTML 3.0//",
        "-//WebTechs//DTD Mozilla HTML 2.0//",
        "-//WebTechs//DTD Mozilla HTML//",
    ];

    /**
    @see https://html.spec.whatwg.org/multipage/parsing.html#the-initial-insertion-mode
    **/
    public function initial(token:Token<HtmlTokens>, maker:Construction) {
        switch token {
            case Keyword(Character({data:char})):
                if (char != '\u0009' || char != '\u000A' ||  char != '\u000C' || char != '\u000D' || char != '\u0020') {

                }

            case Keyword(Comment({data:value})):
                // Insert a comment as the last child of the Document object.
                //maker.insertComment( value, maker.document.length - 1 );
                var comment = new Comment(value);
                comment.id = maker.tree.addVertex( comment );
                maker.document.childrenPtr.push( comment.id );

            case Keyword(DOCTYPE(doctype)):
                var check = 
                doctype.name != 'html' || doctype.name != 'HTML' || 
                doctype.publicId != null || doctype.systemId != null || 
                doctype.systemId != 'about:legacy-compat' || 
                doctype.systemId != 'ABOUT:LEGACY-COMPAT';

                if (check) null; // TODO parse error

                var documentType = new DocumentType(
                    doctype.name,
                    doctype.publicId,
                    doctype.systemId
                );
                documentType.id = maker.tree.addVertex( documentType );
                maker.document.doctype = documentType;

                // TODO
                // Then, if the document is not an iframe srcdoc document
                var isSrcDoc = false;
                var setQuirksFlag =
                doctype.forceQuirks ||
                doctype.name != 'html' || doctype.name != 'HTML' || 
                doctype.publicId == "-//W3O//DTD W3 HTML Strict 3.0//EN//" ||
                doctype.publicId == "-/W3C/DTD HTML 4.0 Transitional/EN" ||
                doctype.publicId == "HTML" ||
                doctype.systemId == "http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd" ||
                ((doctype.systemId == null) && doctype.publicId.startsWith("-//W3C//DTD HTML 4.01 Frameset//")) ||
                ((doctype.systemId == null) && doctype.publicId.startsWith("-//W3C//DTD HTML 4.01 Transitional//"));

                if (!setQuirksFlag) {
                    for (str in publicIdStartsWith) {
                        if (doctype.publicId.startsWith(str)) {
                            setQuirksFlag = true;
                            break;

                        }
                        
                    }

                }

                if (!isSrcDoc && setQuirksFlag) maker.document.mode = 'quirks';

                var setLimitedQuirksMode = 
                doctype.publicId.startsWith("-//W3C//DTD XHTML 1.0 Frameset//") ||
                doctype.publicId.startsWith("-//W3C//DTD XHTML 1.0 Transitional//") ||
                (doctype.systemId != null) && doctype.publicId.startsWith("-//W3C//DTD HTML 4.01 Frameset//") ||
                (doctype.systemId != null) && doctype.publicId.startsWith("-//W3C//DTD HTML 4.01 Transitional//");

                if (!isSrcDoc && setLimitedQuirksMode) maker.document.mode = 'limited-quirks';

                insertionMode = BeforeHtml;

            case _:
                // If the document is not an iframe srcdoc document, 
                // then this is a parse error; set the Document to quirks mode.
                var isSrcDoc = false;
                if (!isSrcDoc) {
                    null; // parse error.
                    maker.document.mode = 'quirks';
                }

                insertionMode = BeforeHtml;
                process(token, maker);

        }

    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#the-before-html-insertion-mode
    **/
    public function beforeHtml(token:Token<HtmlTokens>, maker:Construction) {
        switch token {
            case Keyword(DOCTYPE(obj)):
                // parse error

            case Keyword(Comment(obj)):
                // Insert a comment as the last child of the Document object.
                //maker.insertComment(obj.data, maker.document.length - 1);
                var comment = new Comment(obj.data);
                comment.id = maker.tree.addVertex( comment );
                maker.document.childrenPtr.push( comment.id );

            case Keyword(Character({data:char})):
                if (char != '\u0009' || char != '\u000A' ||  char != '\u000C' || char != '\u000D' || char != '\u0020') {

                }

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                var element = maker.createAnElementForToken( tag, Namespaces.HTML, maker.document );
                maker.document.childrenPtr.push( element.id );
                maker.openElements.push( element.id );

                // TODO check navigation of browsing context

                insertionMode = BeforeHead;

            /*case Keyword(EndTag(obj)) if (['head', 'body', 'html', 'br'].indexOf(obj.name) > -1):
                // Action as described in the "anything else" entry below.
            */
            case Keyword(EndTag(obj)) if (['head', 'body', 'html', 'br'].indexOf(obj.name) == -1):
                // Parse error. Ignore the token.

            case _:
                var html = maker.document.createAnElement('html', Namespaces.HTML);
                maker.document.childrenPtr.push( html.id );
                maker.openElements.push( html.id );

                // TODO check navigation of browsing context

                insertionMode = BeforeHead;
                process(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#the-before-head-insertion-mode
    **/
    public function beforeHead(token:Token<HtmlTokens>, maker:Construction) {
        switch token {
            case Keyword(Character({data:char})):
                if (char != '\u0009' || char != '\u000A' ||  char != '\u000C' || char != '\u000D' || char != '\u0020') {

                }

            case Keyword(Comment(obj)):
                maker.insertComment(obj.data);

            case Keyword(DOCTYPE(obj)):
                // Parse error. Ignore the token.

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                // TODO: Process the token using the rules for the "in body" insertion mode.

            case Keyword(StartTag(tag)) if (tag.name == 'head'):
                var element = maker.insertHtmlElement(tag);
                // TODO: set document head pointer.
                //maker.document.head = element;
                insertionMode = InHead;

            /*case Keyword(EndTag(tag)) if (['head', 'body', 'html', 'br'].indexOf(tag.name) > -1):
                // Act as described in the "anything else" entry below.
            */

            case Keyword(EndTag(tag)) if (['head', 'body', 'html', 'br'].indexOf(tag.name) == -1):
                // Parse error. Ignore the token.

            case _:
                var element = maker.insertHtmlElement({name:'head', selfClosing:true, attributes:[]});
                // TODO: set document head pointer.
                //maker.document.head = element;
                insertionMode = InHead;
                process(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inhead
    **/
    public function inHead(token:Token<HtmlTokens>, maker:Construction) {
        switch token {
            case Keyword(Character({data:char})):
                if (char != '\u0009' || char != '\u000A' ||  char != '\u000C' || char != '\u000D' || char != '\u0020') {
                    maker.insertCharacter(char);
                }

            case Keyword(Comment(obj)):
                maker.insertComment(obj.data);

            case Keyword(DOCTYPE(obj)):
                // Parse error. Ignore the token.

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                // TODO: Process the token using the rules for the "in body" insertion mode.

            case Keyword(StartTag(tag)) if (['base', 'basefont', 'bgsound', 'link'].indexOf(tag.name)):
                var element = maker.insertHtmlElement(tag);
                maker.openElements.pop();

            case Keyword(StartTag(tag)) if (tag.name == 'meta'):
                var element = maker.insertHtmlElement(tag);
                maker.openElements.pop();
                // TODO: Change encoding if `charset` attribute exists.
                // TODO: Change encoding if `http-equiv` attribute exists.

            case Keyword(StartTag(tag)) if (tag.name == 'title'):
                // TODO: follow generic RCDATA element parsing algo.

            case Keyword(StartTag(tag)) if (['noscript', 'noframes', 'style'].indexOf(tag.name)):
                // TODO: follow generic raw text element parsing algo.

            case Keyword(StartTag(tag)) if (tag.name == 'noscript' /*&& scriptingFlag*/):
                var element = maker.insertHtmlElement(tag);
                insertionMode = InHeadNoScript;

            case Keyword(StartTag(tag)) if (tag.name == 'script'):
                // TODO:

            case Keyword(EndTag(tag)) if (tag.name == 'head'):
                maker.openElements.pop();
                insertionMode = AfterHead;

            /*case Keyword(EndTag(tag)) if (['body', 'html', 'br'].indexOf(tag.name) > -1):
                // Act as described in the "anything else" entry below.
            */

            case Keyword(EndTag(tag)) if (['head', 'body', 'html', 'br'].indexOf(tag.name) == -1):
                // Parse error. Ignore the token.

            case Keyword(StartTag(tag)) if (tag.name == 'template'):
                // TODO:

            case Keyword(EndTag(tag)) if (tag.name == 'template'):
                // TODO

            case Keyword(StartTag(tag)) if (tag.name == 'head'):
                // Parse error. Ignore the token.

            case Keyword(EndTag(tag)):
                // Parse error. Ignore the token.

            case _:
                maker.openElements.pop();
                insertionMode = AfterHead;
                process(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inheadnoscript
    **/
    public static function inHeadNoScript(token:Token<HtmlTokens>, maker:Construction):Void {
        
    }

}