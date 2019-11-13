package uhx.mo.html.parsing;

import uhx.mo.infra.Namespaces;
import uhx.mo.dom.Tree;
import uhx.mo.dom.nodes.Node;
import uhx.mo.html.internal.Tag;
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

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#original-insertion-mode
    **/
    public var originalInsertionMode:InsertionMode = Initial;

    private var selection:Array<Token<HtmlTokens>->Construction->Void>;

    public function new() {
        selection = [
            initial, beforeHtml, beforeHead, inHead, inHeadNoScript, afterHead,
            inBody, text, inTable, inTableText, inCaption, inColumnGroup, inTableBody,
            inRow, inCell, inSelect, inSelectInTable, inTemplate, afterBody, inFrameset,
            afterFrameset, afterAfterBody, afterAfterFrameset
        ];
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
        @see https://html.spec.whatwg.org/multipage/parsing.html#generic-rcdata-element-parsing-algorithm
    **/
    private function genericRawTextElementParsing(tag:Tag, maker:Construction) {
        maker.insertHtmlElement(tag);
        maker.tokenizer.backpressure.push( uhx.mo.html.rules.Rules.rawtext_state );
        originalInsertionMode = insertionMode;
        insertionMode = Text;
    }

    private function genericRCDATAElementParsing(tag:Tag, maker:Construction) {
        maker.insertHtmlElement(tag);
        maker.tokenizer.backpressure.push( uhx.mo.html.rules.Rules.rcdata_state );
        originalInsertionMode = insertionMode;
        insertionMode = Text;
    }

    /**
    @see https://html.spec.whatwg.org/multipage/parsing.html#the-initial-insertion-mode
    **/
    public function initial(token:Token<HtmlTokens>, maker:Construction) {
        switch token {
            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                // Ignore the token.

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

                if (check) {
                    maker.handleParseError('If the DOCTYPE token\'s name is not a case-sensitive match for the string "html", or the token\'s public identifier is not missing, or the token\'s system identifier is neither missing nor a case-sensitive match for the string "about:legacy-compat", then there is a parse error.');
                }

                var documentType = new DocumentType(
                    doctype.name,
                    doctype.publicId,
                    doctype.systemId
                );
                documentType.id = maker.tree.addVertex( documentType );
                maker.document.doctype = documentType;

                // TODO: Then, if the document is not an iframe srcdoc document
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
                    maker.handleParseError('If the document is not an iframe srcdoc document, then this is a parse error');
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
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(Comment(obj)):
                // Insert a comment as the last child of the Document object.
                //maker.insertComment(obj.data, maker.document.length - 1);
                var comment = new Comment(obj.data);
                comment.id = maker.tree.addVertex( comment );
                maker.document.childrenPtr.push( comment.id );

            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                // Ignore the token.

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                var element = maker.createAnElementForToken( tag, Namespaces.HTML, maker.document );
                maker.document.childrenPtr.push( element.id );
                maker.openElements.push( element.id );

                // TODO: check navigation of browsing context
                // This is service worker/manifest file specific.

                insertionMode = BeforeHead;

            /*case Keyword(EndTag(obj)) if (['head', 'body', 'html', 'br'].indexOf(obj.name) > -1):
                // Action as described in the "anything else" entry below.
            */
            case Keyword(EndTag(obj)) if (['head', 'body', 'html', 'br'].indexOf(obj.name) == -1):
                maker.handleParseError('Parse error. Ignore the token.');

            case _:
                var html = maker.document.createAnElement('html', Namespaces.HTML);
                maker.document.childrenPtr.push( html.id );
                maker.openElements.push( html.id );

                // TODO: check navigation of browsing context
                // application cache specific.

                insertionMode = BeforeHead;
                process(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#the-before-head-insertion-mode
    **/
    public function beforeHead(token:Token<HtmlTokens>, maker:Construction) {
        switch token {
            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                // Ignore the token.

            case Keyword(Comment(obj)):
                maker.insertComment(obj.data);

            case Keyword(DOCTYPE(obj)):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                inBody(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'head'):
                var element = maker.insertHtmlElement(tag);
                maker.document.headPtr = element.id;
                insertionMode = InHead;

            /*case Keyword(EndTag(tag)) if (['head', 'body', 'html', 'br'].indexOf(tag.name) > -1):
                // Act as described in the "anything else" entry below.
            */

            case Keyword(EndTag(tag)) if (['head', 'body', 'html', 'br'].indexOf(tag.name) == -1):
                maker.handleParseError('Parse error. Ignore the token.');

            case _:
                var element = maker.insertHtmlElement({name:'head', selfClosing:false, attributes:[]});
                maker.document.headPtr = element.id;
                insertionMode = InHead;
                process(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inhead
    **/
    public function inHead(token:Token<HtmlTokens>, maker:Construction) {
        switch token {
            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                maker.insertCharacter(char);

            case Keyword(Comment(obj)):
                maker.insertComment(obj.data);

            case Keyword(DOCTYPE(obj)):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                inBody(token, maker);

            case Keyword(StartTag(tag)) if (['base', 'basefont', 'bgsound', 'link'].indexOf(tag.name)):
                var element = maker.insertHtmlElement(tag);
                maker.openElements.pop();
                tag.acknowledgeSelfClosingFlag(maker);

            case Keyword(StartTag(tag)) if (tag.name == 'meta'):
                var element = maker.insertHtmlElement(tag);
                maker.openElements.pop();
                // TODO: Change encoding if `charset` attribute exists.
                // TODO: Change encoding if `http-equiv` attribute exists.

            case Keyword(StartTag(tag)) if (tag.name == 'title'):
                genericRCDATAElementParsing(tag, maker);

            case Keyword(StartTag(tag)) if (['noscript', 'noframes', 'style'].indexOf(tag.name)):
                // TODO: check scriptingFlag for `noscript`
                genericRawTextElementParsing(tag, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'noscript' /*&& !scriptingFlag*/):
                var element = maker.insertHtmlElement(tag);
                insertionMode = InHeadNoScript;

            case Keyword(StartTag(tag)) if (tag.name == 'script'):
                var adjustedInsertionLocation = maker.appropriateInsertionPoint();
                var element = maker.createAnElementForToken( tag, Namespaces.HTML, adjustedInsertionLocation.node );
                // 3. Mark the element as being "parser-inserted" and unset the element's "non-blocking" flag.
                // 4. If the parser was created as part of the HTML fragment parsing algorithm, then mark the script element as "already started". (fragment case)
                // 5. If the parser was invoked via the document.write() or document.writeln() methods, then optionally mark the script element as "already started". (For example, the user agent might use this clause to prevent execution of cross-origin scripts inserted via document.write() under slow network conditions, or when the page has already taken a long time to load.)
                /*6*/ adjustedInsertionLocation.insert(element);
                maker.openElements.push( element.id );
                maker.tokenizer.backpressure.push( uhx.mo.html.rules.Rules.script_data_state );
                insertionMode = Text;

            case Keyword(EndTag(tag)) if (tag.name == 'head'):
                maker.openElements.pop();
                insertionMode = AfterHead;

            /*case Keyword(EndTag(tag)) if (['body', 'html', 'br'].indexOf(tag.name) > -1):
                // Act as described in the "anything else" entry below.
            */

            case Keyword(EndTag(tag)) if (['head', 'body', 'html', 'br'].indexOf(tag.name) == -1):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)) if (tag.name == 'template'):
                maker.insertHtmlElement(tag);

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
    public function inHeadNoScript(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(DOCTYPE(_)):
                // Parse error. Ignore the token.

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                // Process the token using rules for `inBody`.

            case Keyword(EndTag(tag)) if (tag.name == 'noscript'):
                maker.openElements.pop();
                insertionMode = InHead;

            case Keyword(Character({data:char})) if (char == '\u0009' || char == '\u000A' ||  char == '\u000C' || char == '\u000D' || char == '\u0020'):
                inHead(token, maker);

            case Keyword(Comment(_)):
                inHead(token, maker);

            case Keyword(StartTag(tag)) if (['basefont', 'bgsound', 'link', 'meta', 'noframes', 'style'].indexOf(tag.name) > -1):
                inHead(token, maker);

            /*case Keyword(EndTag(tag)) if (tag.name == 'br'):
                // Act as "anything else"
            */

            case Keyword(StartTag(tag)) if (tag.name == 'head' || tag.name == 'noscript'):
                // Parse error. Ignore the token.

            case Keyword(EndTag(_)):
                // Parse error. Ignore the token.

            case _:
                // Parse error.
                maker.openElements.pop();
                insertionMode = InHead;
                process(token, maker);
        } 
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#the-after-head-insertion-mode
    **/
    public function afterHead(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:char})) if (char == '\u0009' || char == '\u000A' ||  char == '\u000C' || char == '\u000D' || char == '\u0020'):
                maker.insertCharacter(char);

            case Keyword(Comment({data:value})):
                maker.insertComment(value);

            case Keyword(DOCTYPE(_)):
                // Parse error. Ignore the token.

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                inBody(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'body'):
                maker.insertHtmlElement(tag);
                // TODO: set frameset-ok flag.
                insertionMode = InBody;

            case Keyword(StartTag(tag)) if (tag.name == 'frameset'):
                maker.insertHtmlElement(tag);
                insertionMode = InFrameset;

            case Keyword(StartTag(tag)) if (['base', 'basefont', 'bgsound', 'link', 'meta', 'noframes', 'script', 'style', 'template', 'title'].indexOf(tag.name) > -1):
                // Parse error.
                // TODO
                //maker.openElements.push( maker.document.headPtr );
                inHead(token, maker);
                //maker.openElements.remove( maker.document.headPtr );

            case Keyword(EndTag(tag)) if (tag.name == 'template'):
                inHead(token, maker);

            /*case Keyword(EndTag(tag)) if (['body', 'html', 'br'].indexOf(tag.name) > -1):
                // Act as "anything else"/
            */

            case Keyword(StartTag(tag)) if (tag.name == 'head'):
                // Parse error. Ignore the token.
            
            case Keyword(EndTag(_)):
                // Parse error. Ignore the token.

            case _:
                maker.insertHtmlElement({name:'body', attributes:[], selfClosing:false});
                insertionMode = InBody;
                process(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inbody
    **/
    public function inBody(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:'\u0000'})):
                // Parse error. Ignore the token.

            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                // TODO reconstruct active formatting elements, if any.
                maker.insertCharacter(char);

            case Keyword(Character({data:char})):
                // TODO reconstruct active formatting elements, if any.
                maker.insertCharacter(char);
                // TODO set frameset-ok flag to not ok.

            case Keyword(Comment({data:value})):
                maker.insertComment(value);

            case Keyword(DOCTYPE(_)):
                // Parse error. Ignore the token.

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                // Parse error.
                // TODO case

            case Keyword(StartTag(tag)) if (['base', 'basefont', 'bgsound', 'link', 'meta', 'noframes', 'script', 'style', 'template', 'title'].indexOf(tag.name) > -1):
                inHead(token, maker);

            case Keyword(EndTag(tag)) if (tag.name == 'template'):
                inHead(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'body'):
                // Parse error.
                // TODO case
            
            case Keyword(StartTag(tag)) if (tag.name == 'frameset'):
                // Parse error.
                // TODO case

            case EOF:
                if (maker.openElements.length > 0) {
                    inTemplate(token, maker);

                } else {
                    // TODO case

                }

            case Keyword(EndTag(tag)) if (tag.name == 'body'):
                var hasBodyInScrope = false;
                for (ptr in maker.openElements) {
                    var node = ptr.get();
                    if (node.nodeName == 'body') {
                        hasBodyInScrope = true;
                        break;
                    }
                }

                if (!hasBodyInScrope) {
                    // Parse error. Ignore the token.

                } else {
                    // TODO case

                }

                insertionMode = AfterBody;

            case Keyword(EndTag(tag)) if (tag.name == 'html'):
                var hasBodyInScrope = false;
                for (ptr in maker.openElements) {
                    var node = ptr.get();
                    if (node.nodeName == 'body') {
                        hasBodyInScrope = true;
                        break;
                    }
                }

                if (!hasBodyInScrope) {
                    // Parse error. Ignore the token.

                } else {
                    // TODO case

                }

                insertionMode = AfterBody;
                process(token, maker);

            case Keyword(StartTag(tag)) if (["address", "article", "aside", "blockquote", "center", "details", "dialog", "dir", "div", "dl", "fieldset", "figcaption", "figure", "footer", "header", "hgroup", "main", "menu", "nav", "ol", "p", "section", "summary", "ul"].indexOf(tag.name) > -1):
                // TODO case

            case Keyword(StartTag(tag)) if (["h1", "h2", "h3", "h4", "h5", "h6"].indexOf(tag.name) > -1):
                // TODO case

            case Keyword(StartTag(tag)) if (tag.name == 'pre' || tag.name == 'listing'):
                // TODO case

            case Keyword(StartTag(tag)) if (tag.name == 'form'):
        
            case Keyword(StartTag(tag)) if (tag.name == 'li'):

            case Keyword(StartTag(tag)) if (tag.name == 'dd' || tag.name == 'dt'):

            case Keyword(StartTag(tag)) if (tag.name == 'plaintext'):

            case Keyword(StartTag(tag)) if (tag.name == 'button'):

            case Keyword(EndTag(tag)) if (["address", "article", "aside", "blockquote", "center", "details", "dialog", "dir", "div", "dl", "fieldset", "figcaption", "figure", "footer", "header", "hgroup", "main", "menu", "nav", "ol", "p", "section", "summary", "ul"].indexOf(tag.name) > -1):
                // TODO case

            case Keyword(EndTag(tag)) if (tag.name == 'form'):

            case Keyword(EndTag(tag)) if (tag.name == 'p'):

            case Keyword(EndTag(tag)) if (tag.name == 'li'):

            case Keyword(EndTag(tag)) if (tag.name == 'dd' || tag.name == 'dt'):

            case Keyword(EndTag(tag)) if (["h1", "h2", "h3", "h4", "h5", "h6"].indexOf(tag.name) > -1):
                // TODO case

            case Keyword(EndTag(tag)) if (tag.name == 'sarcasm'):

            case Keyword(StartTag(tag)) if (tag.name == 'a'):

            case Keyword(StartTag(tag)) if (["b", "big", "code", "em", "font", "i", "s", "small", "strike", "strong", "tt", "u"].indexOf(tag.name) > -1):

            case Keyword(StartTag(tag)) if (tag.name == 'nobr'):

            case Keyword(EndTag(tag)) if (["a", "b", "big", "code", "em", "font", "i", "nobr", "s", "small", "strike", "strong", "tt", "u"].indexOf(tag.name) > -1):

            case Keyword(StartTag(tag)) if (["applet", "marquee", "object"].indexOf(tag.name) > -1):

            case Keyword(EndTag(tag)) if (["applet", "marquee", "object"].indexOf(tag.name) > -1):

            case Keyword(StartTag(tag)) if (tag.name == 'table'):

            case Keyword(EndTag(tag)) if (tag.name == 'br'):

            case Keyword(StartTag(tag)) if (["area", "br", "embed", "img", "keygen", "wbr"].indexOf(tag.name) > -1):

            case Keyword(StartTag(tag)) if (tag.name == 'input'):

            case Keyword(StartTag(tag)) if (["param", "source", "track"].indexOf(tag.name) > -1):

            case Keyword(StartTag(tag)) if (tag.name == 'hr'):

            case Keyword(StartTag(tag)) if (tag.name == 'image'):

            case Keyword(StartTag(tag)) if (tag.name == 'textarea'):

            case Keyword(StartTag(tag)) if (tag.name == 'xmp'):

            case Keyword(StartTag(tag)) if (tag.name == 'iframe'):

            case Keyword(StartTag(tag)) if (tag.name == 'noembed' || tag.name == 'noscript' /*&& scriptingFlag*/):

            case Keyword(StartTag(tag)) if (tag.name == 'select'):

            case Keyword(StartTag(tag)) if (tag.name == 'optfroup' || tag.name == 'option'):

            case Keyword(StartTag(tag)) if (tag.name == 'rb' || tag.name == 'rtc'):

            case Keyword(StartTag(tag)) if (tag.name == 'rp' || tag.name == 'rt'):

            case Keyword(StartTag(tag)) if (tag.name == 'math'):

            case Keyword(StartTag(tag)) if (tag.name == 'svg'):

            case Keyword(StartTag(tag)) if (["caption", "col", "colgroup", "frame", "head", "tbody", "td", "tfoot", "th", "thead", "tr"].indexOf(tag.name) > -1):

            case Keyword(StartTag(tag)):
                // TODO reconstruct active formatting elements, if any.
                maker.insertHtmlElement(tag);

            case Keyword(EndTag(tag)):
                // TODO case

            case _:
                // TODO check this
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incdata
    **/
    public function text(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:char})):
                maker.insertCharacter(char);

            case EOF:
                // Parse error.
                if (maker.currentNode.nodeName == 'script') {
                    // TODO case
                }

                maker.openElements.pop();

                // TODO //insertionMode = original

            case Keyword(EndTag(tag)) if (tag.name == 'script'):
                // TODO

            case Keyword(EndTag(tag)):
                maker.openElements.pop();
                // TODO //insertionMode = original

            case _:
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intable
    **/
    public function inTable(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:char})) if (['table', 'tbody', 'tfoot', 'thead', 'tr'].indexOf(maker.currentNode.nodeName) > -1):
                // TODO set original insertion mode to current.
                insertionMode = InTableText;
            
            case Keyword(Comment({data:value})):
                maker.insertComment(value);

            case Keyword(DOCTYPE(_)):
                // Parse error. Ignore the token.

            case Keyword(StartTag(tag)) if (tag.name == 'caption'):

            case Keyword(StartTag(tag)) if (tag.name == 'colgroup'):

            case Keyword(StartTag(tag)) if (tag.name == 'col'):

            case Keyword(StartTag(tag)) if (['tbody', 'tfoot', 'thead'].indexOf(tag.name) > -1):

            case Keyword(StartTag(tag)) if (['tbody', 'th', 'tr'].indexOf(tag.name) > -1):

            case Keyword(StartTag(tag)) if (tag.name == 'table'):

            case Keyword(EndTag(tag)) if (tag.name == 'table'):

            case Keyword(EndTag(tag)) if (["body", "caption", "col", "colgroup", "html", "tbody", "td", "tfoot", "th", "thead", "tr"].indexOf(tag.name) > -1):

            case Keyword(StartTag(tag)) if (["style", "script", "template"].indexOf(tag.name) > -1):

            case Keyword(EndTag(tag)) if (tag.name == 'template'):

            case Keyword(StartTag(tag)) if (tag.name == 'input'):

            case Keyword(StartTag(tag)) if (tag.name == 'form'):

            case EOF:
                inBody(token, maker);

            case _:
                // Parse error.
                // TODO case
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intabletext
    **/
    public function inTableText(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:'\u0000'})):
                // Parse error. Ignore the token.

            case Keyword(Character({data:char})):
                // TODO

            case _:
                // TODO
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incaption
    **/
    public function inCaption(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(EndTag(tag)) if (tag.name == 'caption'):

            case Keyword(StartTag(tag)) if (["caption", "col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"].indexOf(tag.name) > -1):

            case Keyword(EndTag(tag)) if (tag.name == 'table'):

            case Keyword(EndTag(tag)) if (["body", "col", "colgroup", "html", "tbody", "td", "tfoot", "th", "thead", "tr"].indexOf(tag.name) > -1):

            case _:
                inBody(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incolgroup
    **/
    public function inColumnGroup(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                maker.insertCharacter(char);

            case Keyword(Comment({data:value})):
                maker.insertComment(value);

            case Keyword(DOCTYPE(_)):
                // Parse error. Ignore the token.

            case Keyword(StartTag(tag)) if (tag.name == 'html'): 
                inBody(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'col'):
                maker.insertHtmlElement(tag);
                maker.openElements.pop();
                // TODO acknowledge the self closing flag, is set

            case Keyword(EndTag(tag)) if (tag.name == 'colgroup'):
                
            case Keyword(EndTag(tag)) if (tag.name == 'col'):
                // Parse error. Ignore the token.

            case Keyword(StartTag(tag)), Keyword(EndTag(tag)) if (tag.name == 'template'):
                inHead(token, maker);

            case EOF:
                inBody(token, maker);

            case _:
                if (maker.currentNode.nodeName != 'colgroup') {
                    // Parse error. Ignore the token.

                } else {
                    maker.openElements.pop();
                    insertionMode = InTable;
                    process(token, maker);

                }

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intbody
    **/
    public function inTableBody(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(StartTag(tag)) if (tag.name == 'tr'):

            case Keyword(StartTag(tag)) if (['th', 'td'].indexOf(tag.name) > -1):

            case Keyword(EndTag(tag)) if (['tbody', 'tfoot', 'thead'].indexOf(tag.name) > -1):

            case Keyword(StartTag(tag)) if (["caption", "col", "colgroup", "tbody", "tfoot", "thead"].indexOf(tag.name) > -1):

            case Keyword(EndTag(tag)) if (tag.name == 'table'):

            case Keyword(EndTag(tag)) if (["body", "caption", "col", "colgroup", "html", "td", "th", "tr"].indexOf(tag.name) > -1):

            case _:
                inTable(token, maker);
                
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intr
    **/
    public function inRow(token:Token<HtmlTokens>, maker:Construction):Void {

    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intd
    **/
    public function inCell(token:Token<HtmlTokens>, maker:Construction):Void {

    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inselect
    **/
    public function inSelect(token:Token<HtmlTokens>, maker:Construction):Void {

    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inselectintable
    **/
    public function inSelectInTable(token:Token<HtmlTokens>, maker:Construction):Void {

    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intemplate
    **/
    public function inTemplate(token:Token<HtmlTokens>, maker:Construction):Void {

    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-afterbody
    **/
    public function afterBody(token:Token<HtmlTokens>, maker:Construction):Void {

    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inframeset
    **/
    public function inFrameset(token:Token<HtmlTokens>, maker:Construction):Void {

    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-afterframeset
    **/
    public function afterFrameset(token:Token<HtmlTokens>, maker:Construction):Void {

    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#the-after-after-body-insertion-mode
    **/
    public function afterAfterBody(token:Token<HtmlTokens>, maker:Construction):Void {

    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#the-after-after-frameset-insertion-mode
    **/
    public function afterAfterFrameset(token:Token<HtmlTokens>, maker:Construction):Void {

    }

}