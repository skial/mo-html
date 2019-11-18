package uhx.mo.html.parsing;

import uhx.mo.dom.Tree;
import uhx.mo.dom.nodes.Node;
import uhx.mo.dom.nodes.Attr;
import uhx.mo.html.rules.Rules;
import uhx.mo.infra.Namespaces;
import uhx.mo.html.internal.Tag;
import uhx.mo.dom.nodes.Comment;
import uhx.mo.dom.nodes.Element;
import uhx.mo.dom.nodes.Document;
import uhx.mo.dom.nodes.NodeType;
import uhx.mo.html.flags.FormatType;
import uhx.mo.dom.nodes.DocumentType;
import uhx.mo.html.tree.Construction;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.parsing.InsertionMode;

using StringTools;

@:build(uhx.mo.html.macros.InsertionRulesTools.build())
class InsertionRules {

    public var insertionMode:InsertionMode = Initial;

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#original-insertion-mode
    **/
    public var originalInsertionMode:InsertionMode = Initial;

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#stack-of-template-insertion-modes
    **/
    public var stackOfTemplateInsertionModes:Array<InsertionMode> = [];

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#reset-the-insertion-mode-appropriately
    **/
    public function resetInsertionMode(maker:Construction) {
        var last = false;
        var index = maker.openElements.length -1;
        var node = maker.openElements[index].get();

        while (true) {
            if (node.id == maker.openElements[0]) {
                last = true;
                // TODO: HTML fragment parsing
            }

            switch node.nodeName {
                case 'select':
                    var state = true;
                    var idx = index;
                    var ancestor = node;
                    while (true) {
                        if (last) state = false;
                        switch state {
                            case true: /**loop**/
                                if (ancestor.id == maker.openElements[0]) {
                                    state = false;

                                } else {
                                    idx--;
                                    ancestor = maker.openElements[idx].get();
                                    if (ancestor.nodeName == 'template') {
                                        state = false;

                                    } else if (ancestor.nodeName == 'table') {
                                        insertionMode = InSelectInTable;
                                        return;
                                    }

                                }
                            case false: /**done**/
                                insertionMode = InSelect;
                                return;
                        }

                    }

                case 'td' | 'th' if (!last):
                    insertionMode = InCell;
                    return;

                case 'tr':
                    insertionMode = InRow;
                    return;

                case 'tbody' | 'thead' | 'tfoot':
                    insertionMode = InTableBody;
                    return;

                case 'caption':
                    insertionMode = InCaption;
                    return;

                case 'colgroup':
                    insertionMode = InColumnGroup;
                    return;

                case 'table':
                    insertionMode = InTable;
                    return;

                case 'template':
                    insertionMode = stackOfTemplateInsertionModes[stackOfTemplateInsertionModes.length -1];
                    return;

                case 'head' if (!last):
                    insertionMode = InHead;
                    return;

                case 'body':
                    insertionMode = InBody;
                    return;

                case 'frameset':
                    insertionMode = InFrameset;
                    return;

                case 'html':
                    if (maker.document.headPtr == null) {
                        insertionMode = BeforeHead;
                    } else {
                        insertionMode = AfterHead;
                    }
                    return;

                case _:
                    if (last) {
                        insertionMode = InBody;
                        return;

                    } else {
                        index--;
                        node = maker.openElements[index];

                    }
            }
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#adoption-agency-algorithm
    **/
    private function adoptionAgencyAlgorithm(tag:Tag, maker:Construction):Void {
        /**1**/
        var subject = tag.name;
        var currentNode = maker.currentNode;

        /**2**/
        if (currentNode.nodeType == NodeType.Element && currentNode.nodeName == subject && !maker.activeFormattingElements.has(currentNode.id)) {
            maker.openElements.pop();
            return;

        }

        /**3**/
        var outerLoop = 0;

        /**4**/
        while (outerLoop <= 8) {
            //break;
            /**5**/
            outerLoop++;
            /**6**/
            var formattingElement = maker.activeFormattingElements.get(subject);
            if (formattingElement == null) return; // TODO:

            /**7**/
            var index = maker.openElements.lastIndexOf(formattingElement.id);
            if (index == -1) {
                maker.handleParseError('Parse error.');
                maker.activeFormattingElements.remove(formattingElement.id);
                return;

            } /**8**/ else {
                if (!maker.openElements.hasElementInScope(formattingElement.nodeName)) {
                    maker.handleParseError('Parse error.');
                    return;

                }

            }

            /**9**/
            if (formattingElement.id != maker.currentNode.id) {
                maker.handleParseError('Parse error.');

            }

            /**10**/
            var furthestBlock:Null<Node> = null;
            //for (ptr in maker.openElements) {
            for (idx in index...maker.openElements.length) {
                if ((furthestBlock = maker.openElements[idx].get()).categoryType() == 0) {
                    break;
                }
            }

            /**11**/
            if (furthestBlock == null) {
                maker.openElements.popUntilKnown(formattingElement.id);
                maker.activeFormattingElements.remove(formattingElement.id);
                return;

            }

            /**12**/
            var commonAncestor = maker.openElements[index-1];
            /**13**/ // TODO: this might not work out correctly depending on spec.
            var bookmark = maker.activeFormattingElements.indexOf(formattingElement.id);
            /**14**/
            var nodeIdx = index;
            var node = furthestBlock;
            var lastNode = furthestBlock;
            var innerLoop = 0;
            while (true) {
                //break;
                /**2**/
                innerLoop++;
                /**3**/
                var idx = maker.openElements.indexOf(node.id);
                if (idx > 0) {
                    node = maker.openElements[nodeIdx = idx - 1];

                } else {
                    node = maker.openElements[nodeIdx = nodeIdx - 1];

                }
                /**
                    4. If node is formatting element, then go to the next step 
                    in the overall algorithm.
                    ---
                    I'm assuming this means break out of this inner loop.
                **/
                if (node.id == formattingElement.id) {
                    break;
                }

                /**5**/
                if (innerLoop > 3 && maker.activeFormattingElements.has(node.id)) {
                    maker.activeFormattingElements.remove(node.id);

                } /**6**/ else if (!maker.activeFormattingElements.has(node.id)) {
                    maker.openElements.remove(node.id);
                    continue;

                }

                /**7**/
                var newNode = maker.createAnElementForToken( {
                    selfClosing:false,
                    name:node.nodeName, 
                    attributes:[for (a in (cast node:Element).attributes) {name:a.name, value:a.value}], 
                }, Namespaces.HTML, commonAncestor);

                maker.activeFormattingElements[index] = newNode;
                maker.openElements[maker.openElements.indexOf(node.id)] = newNode.id;
                node = newNode;

                /**8**/
                if (lastNode.id == furthestBlock.id) {
                    bookmark = index + 1;
                }

                /**9**/
                node.appendChild(lastNode);
                
                /**10**/
                lastNode = node;
            }

            /**15**/
            maker.appropriateInsertionPoint(commonAncestor).insert(lastNode);

            /**16**/
            var newNode = maker.createAnElementForToken({
                selfClosing:false,
                name:formattingElement.nodeName, 
                attributes:[for (a in formattingElement.attributes) {name:a.name, value:a.value}], 
            }, Namespaces.HTML, furthestBlock);

            /**17**/
            newNode.childrenPtr = furthestBlock.childrenPtr.copy();

            /**18**/
            furthestBlock.childrenPtr = [newNode.id];

            /**19**/
            maker.activeFormattingElements.remove(formattingElement.id);
            maker.activeFormattingElements[bookmark] = newNode.id;

            /**20**/
            maker.openElements.remove(formattingElement.id);
            maker.openElements.insert(maker.openElements.indexOf(furthestBlock.id) + 1, newNode);

            /**21**/
            // Back to top.
        }

    }

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
        trace( insertionMode );
        trace( selection[insertionMode] );
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
                var ele = maker.insertHtmlElement(tag);
                ele.flags.set(FormatType.Marker);
                maker.activeFormattingElements.push( ele );
                // TODO: set frameset-ok to `not ok`
                insertionMode = InTemplate;
                stackOfTemplateInsertionModes.push(InTemplate);

            case Keyword(EndTag(tag)) if (tag.name == 'template'):
                var hasTemplate = false;
                for (id in maker.openElements) if (id.get().nodeName == 'template') {
                    hasTemplate = true;
                    break;
                }

                if (!hasTemplate) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    // TODO

                }

            case Keyword(StartTag(tag)) if (tag.name == 'head'):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(EndTag(tag)):
                maker.handleParseError('Parse error. Ignore the token.');

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
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                inBody(token, maker);

            case Keyword(EndTag(tag)) if (tag.name == 'noscript'):
                maker.openElements.pop();
                insertionMode = InHead;

            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                inHead(token, maker);

            case Keyword(Comment(_)):
                inHead(token, maker);

            case Keyword(StartTag(tag)) if (['basefont', 'bgsound', 'link', 'meta', 'noframes', 'style'].indexOf(tag.name) > -1):
                inHead(token, maker);

            /*case Keyword(EndTag(tag)) if (tag.name == 'br'):
                // Act as "anything else"
            */

            case Keyword(StartTag(tag)) if (tag.name == 'head' || tag.name == 'noscript'):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(EndTag(_)):
                maker.handleParseError('Parse error. Ignore the token.');

            case _:
                maker.handleParseError('Parse error.');
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
            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                maker.insertCharacter(char);

            case Keyword(Comment({data:value})):
                maker.insertComment(value);

            case Keyword(DOCTYPE(_)):
                maker.handleParseError('Parse error. Ignore the token.');

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
                maker.handleParseError('Parse error.');
                
                maker.openElements.push( maker.document.headPtr );
                inHead(token, maker);
                maker.openElements.remove( maker.document.headPtr );

            case Keyword(EndTag(tag)) if (tag.name == 'template'):
                inHead(token, maker);

            /*case Keyword(EndTag(tag)) if (['body', 'html', 'br'].indexOf(tag.name) > -1):
                // Act as "anything else"/
            */

            case Keyword(StartTag(tag)) if (tag.name == 'head'):
                maker.handleParseError('Parse error. Ignore the token.');
            
            case Keyword(EndTag(_)):
                maker.handleParseError('Parse error. Ignore the token.');

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
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                maker.activeFormattingElements.reconstruct();
                maker.insertCharacter(char);

            case Keyword(Character({data:char})):
                maker.activeFormattingElements.reconstruct();
                maker.insertCharacter(char);
                // TODO: set frameset-ok flag to `not ok`.

            case Keyword(Comment({data:value})):
                maker.insertComment(value);

            case Keyword(DOCTYPE(_)):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                maker.handleParseError('Parse error.');
                
                if (maker.openElements.exists('template')) {
                    var top:Element = cast maker.openElements[0];
                    for (attribute in tag.attributes) {
                        var exists = false;
                        for (attr in top.attributes) if (attr.name == attribute.name && attr.value == attribute.value) {
                            exists = true;
                            break;
                        }

                        if (exists) continue;

                        top.attributes.self().push( new Attr(attribute.name, null, null, attribute.value, top) );

                    }

                }

            case Keyword(StartTag(tag)) if (['base', 'basefont', 'bgsound', 'link', 'meta', 'noframes', 'script', 'style', 'template', 'title'].indexOf(tag.name) > -1):
                inHead(token, maker);

            case Keyword(EndTag(tag)) if (tag.name == 'template'):
                inHead(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'body'):
                maker.handleParseError('Parse error.');
                if (maker.openElements[1].get().nodeName != 'body' || maker.openElements.length == 1) {
                    // Ignore the token.
                }
                
                if (!maker.openElements.exists('template')) {
                    // TODO: set frameset-ok flag `not ok`.
                    var body:Element = cast maker.openElements[1].get();
                    for (attribute in tag.attributes) {
                        for (attr in body.attributes.self()) {
                            var exists = false;
                            for (attr in body.attributes) if (attr.name == attribute.name && attr.value == attribute.value) {
                                exists = true;
                                break;
                            }

                            if (exists) continue;

                            body.attributes.self().push( new Attr(attribute.name, null, null, attribute.value, body) );
                        }

                    }

                }
            
            case Keyword(StartTag(tag)) if (tag.name == 'frameset'):
                maker.handleParseError('Parse error.');
                if (maker.openElements.length == 1 || maker.openElements[1].get().nodeName != 'body') {
                    return; // Ignore the token.
                }

                // TODO: check against frameset-ok flag

                var second = maker.openElements[1].get();
                if (second.parent != null) {
                    second.parent.childrenPtr.remove(second.id);

                    var rootIndex = -1;
                    for (idx in 0...maker.openElements.length) if (maker.openElements[idx].get().nodeName == 'html') {
                        rootIndex = idx;
                        break;
                    }

                    if (rootIndex == -1) {
                        maker.openElements = new OpenElements();

                    } else {
                        maker.openElements.splice(rootIndex+1, maker.openElements.length);

                    }

                    maker.insertHtmlElement(tag);
                    insertionMode = InFrameset;

                }

            case EOF:
                if (maker.openElements.length > 0) {
                    inTemplate(token, maker);

                } else {
                    for (id in maker.openElements) switch (id.get().nodeName) {
                        case 'dd' | 'dt' | 'li' | 'optgroup' | 'option' | 'p' | 'rb' | 'rp' |' rt' | 'rtc' | 'tbody' | 'td' | 'tfoot' | 'th' | 'thead' | 'tr' | 'body' | 'html':
                        case _:
                            maker.handleParseError('Parse error.');
                            break;
                    }

                    // TODO: check `Stop Parsing`.
                    return;

                }

            case Keyword(EndTag(tag)) if (tag.name == 'body' || tag.name == 'html'):
                if (!maker.openElements.exists('body')) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    for (id in maker.openElements) switch (id.get().nodeName) {
                        case 'dd' | 'dt' | 'li' | 'optgroup' | 'option' | 'p' | 'rb' | 'rp' |' rt' | 'rtc' | 'tbody' | 'td' | 'tfoot' | 'th' | 'thead' | 'tr' | 'body' | 'html':
                        case _:
                            maker.handleParseError('Parse error.');
                            break;
                    }

                }

                insertionMode = AfterBody;
                if (tag.name == 'html') process(token, maker);

            case Keyword(StartTag(tag)) if (["address", "article", "aside", "blockquote", "center", "details", "dialog", "dir", "div", "dl", "fieldset", "figcaption", "figure", "footer", "header", "hgroup", "main", "menu", "nav", "ol", "p", "section", "summary", "ul"].indexOf(tag.name) > -1):
                if (maker.openElements.exists('p') && maker.openElements.hasElementInButtonScope('p')) {
                    maker.closeParagraphElement();

                }

                maker.insertHtmlElement(tag);

            case Keyword(StartTag(tag)) if (["h1", "h2", "h3", "h4", "h5", "h6"].indexOf(tag.name) > -1):
                if (maker.openElements.exists('p') && maker.openElements.hasElementInButtonScope('p')) {
                    maker.closeParagraphElement();

                }

                switch maker.currentNode.nodeName {
                    case 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6':
                        maker.handleParseError('Parse error.');
                        maker.openElements.pop();

                    case _:

                }

                maker.insertHtmlElement(tag);

            case Keyword(StartTag(tag)) if (tag.name == 'pre' || tag.name == 'listing'):
                if (maker.openElements.exists('p') && maker.openElements.hasElementInButtonScope('p')) {
                    maker.closeParagraphElement();

                }

                maker.insertHtmlElement(tag);

                if (maker.tokenizer.nextInputCharacter == '\u000A') {
                    @:privateAccess maker.tokenizer.pos += 2;
                }

                // TODO: set frameset-ok flag `not ok`.

            case Keyword(StartTag(tag)) if (tag.name == 'form'):
                var hasTemplate = maker.openElements.exists('template');

                if (maker.document.formPtr != null && !hasTemplate) {
                    maker.handleParseError('Parse error.');

                } else {
                    if (maker.openElements.hasElementInButtonScope('p')) {
                        maker.closeParagraphElement();
                    }

                    if (!hasTemplate) {
                        maker.document.formPtr = maker.insertHtmlElement(tag).id;

                    }

                }
        
            case Keyword(StartTag(tag)) if (tag.name == 'li'):
                // TODO: set frameset-ok flag to `not ok`.
                var index = maker.openElements.length - 1;
                var node = maker.openElements[index].get();
                var state = true;
                while (true) {
                    switch state {
                        case true: /**loop**/
                            if (node.nodeName == 'li') {
                                maker.generateImpliedEndTags(['li']);

                                if (maker.currentNode.nodeName != 'li') {
                                    maker.handleParseError('Parse error.');

                                }

                                maker.openElements.popUntilNamed('li');

                                state = false;

                            } else if (node.categoryType() == 0 && ['address', 'div', 'p'].indexOf(node.nodeName) == -1) {
                                state = false;    

                            } else {
                                index--;
                                node = maker.openElements[index];

                            }

                        case false: /**done**/
                            if (maker.openElements.hasElementInButtonScope('p')) {
                                maker.closeParagraphElement();

                            }

                            break;

                    }
                    
                }

                maker.insertHtmlElement(tag);

            case Keyword(StartTag(tag)) if (tag.name == 'dd' || tag.name == 'dt'):
                // Set frameset-ok to `not ok`
                var index = maker.openElements.length - 1;
                var node = maker.currentNode;
                var state = false;

                while (maker.openElements.length > 0) {
                    switch state {
                        case false: /**loop**/

                        switch node.nodeName {
                            case 'dd' | 'dt':
                                maker.generateImpliedEndTags([tag.name]);
                                if (maker.currentNode.nodeName != tag.name) {
                                    maker.handleParseError('Parse error.');

                                }

                                maker.openElements.popUntilNamed(tag.name);

                                state = true;

                            case _:
                                if (node.categoryType() == 0 && ['address', 'div', 'p'].indexOf(node.nodeName) == -1) {
                                    state = true;

                                } else {
                                    index--;
                                    node = maker.openElements[index];

                                }

                        }

                        case true: /**done**/
                            if (maker.openElements.hasElementInButtonScope('p')) {
                                maker.closeParagraphElement();

                            }

                            break;

                    }

                }

                maker.insertHtmlElement(tag);

            case Keyword(StartTag(tag)) if (tag.name == 'plaintext'):
                if (maker.openElements.hasElementInButtonScope('p')) {
                    maker.closeParagraphElement();

                }

                maker.insertHtmlElement(tag);
                maker.tokenizer.backpressure.push( Rules.plaintext_state );

            case Keyword(StartTag(tag)) if (tag.name == 'button'):
                if (maker.openElements.hasElementInScope('button')) {
                    maker.handleParseError('Parse error.');
                    maker.generateImpliedEndTags([]);
                    maker.openElements.popUntilNamed('button');
                }

                maker.activeFormattingElements.reconstruct();
                maker.insertHtmlElement(tag);
                // set frameset-ok `not ok`.

            case Keyword(EndTag(tag)) if (["address", "article", "aside", "blockquote", "center", "details", "dialog", "dir", "div", "dl", "fieldset", "figcaption", "figure", "footer", "header", "hgroup", "main", "menu", "nav", "ol", "p", "section", "summary", "ul"].indexOf(tag.name) > -1):
                if (!maker.openElements.hasElementInScope(tag.name)) {
                    maker.handleParseError('Parse error.');
                    // Ignore the token.

                } else {
                    maker.generateImpliedEndTags([]);
                    if (maker.currentNode.nodeName == tag.name) {
                        maker.handleParseError('Parse error.');

                    }

                    maker.openElements.popUntilNamed(tag.name);

                }

            case Keyword(EndTag(tag)) if (tag.name == 'form'):
                if (!maker.openElements.exists('template')) {
                    var node = maker.document.formPtr;
                    maker.document.formPtr = null;

                    if (node == null || (node != null && !maker.openElements.hasElementInScope(node.get().nodeName))) {
                        maker.handleParseError('Parse error.');
                        // Ignore the token.
                        return;
                    }

                    maker.generateImpliedEndTags([]);
                    if (maker.currentNode != null && maker.currentNode != node) {
                        maker.handleParseError('Parse error.');

                    }

                    maker.openElements.remove( node );

                } else {
                    if (maker.openElements.hasElementInScope('form')) {
                        maker.handleParseError('Parse error.');
                        // Ignore the token.
                        return;
                    }

                    maker.generateImpliedEndTags([]);

                    if (maker.currentNode.nodeName != 'form') {
                        maker.handleParseError('Parse error.');

                    }

                    maker.openElements.popUntilNamed('form');

                }

            case Keyword(EndTag(tag)) if (tag.name == 'p'):
                if (!maker.openElements.hasElementInButtonScope('p')) {
                    maker.handleParseError('Parse error.');
                    maker.insertHtmlElement(tag);
                }

                maker.closeParagraphElement();

            case Keyword(EndTag(tag)) if (tag.name == 'li'):
                if (!maker.openElements.hasElementInListItemScope('li')) {
                    maker.handleParseError('Parse error.');
                    // Ignore the token.

                } else {
                    maker.generateImpliedEndTags(['li']);
                    if (maker.currentNode.nodeName != 'li') {
                        maker.handleParseError('Parse error.');

                    }

                    maker.openElements.popUntilNamed('li');

                }

            case Keyword(EndTag(tag)) if (tag.name == 'dd' || tag.name == 'dt'):
                if (!maker.openElements.hasElementInScope(tag.name)) {
                    maker.handleParseError('Parse error.');
                    // Ignore the token.

                } else {
                    maker.generateImpliedEndTags([tag.name]);
                    if (maker.currentNode.nodeName != tag.name) {
                        maker.handleParseError('Parse error.');

                    }

                    maker.openElements.popUntilNamed(tag.name);

                }

            case Keyword(EndTag(tag)) if (["h1", "h2", "h3", "h4", "h5", "h6"].indexOf(tag.name) > -1):
                if (!maker.openElements.hasElementInScope(tag.name)) {
                    maker.handleParseError('Parse error.');
                    // Ignore the token.

                } else {
                    maker.generateImpliedEndTags([]);
                    if (maker.currentNode.nodeName != tag.name) {
                        maker.handleParseError('Parse error.');

                    }

                    maker.openElements.popUntilNamed(tag.name);

                }

            /*case Keyword(EndTag(tag)) if (tag.name == 'sarcasm'):
                /**
                    Take a deep breath, then act as described in the "any other end tag" entry below.
                **/

            case Keyword(StartTag(tag)) if (tag.name == 'a'):
                if (maker.activeFormattingElements.exists('a')) {
                    maker.handleParseError('Parse error.');
                    adoptionAgencyAlgorithm(tag, maker);
                    /**
                        // TODO:
                        ---
                        ... `run the adoption agency algorithm for the token, 
                        then remove that element from the list of active formatting elements and 
                        the stack of open elements if the adoption agency algorithm didn't already 
                        remove it (it might not have if the element is not in table scope).`
                        ---
                        This implies a recorded link between each `tag` and created `node`.
                        Also that `adoptionAgencyAlgorithm` is meant to return an `element`, which
                        the spec doesnt say.
                    **/

                }

                maker.activeFormattingElements.reconstruct();
                maker.activeFormattingElements.push( maker.insertHtmlElement(tag) );

            case Keyword(StartTag(tag)) if (["b", "big", "code", "em", "font", "i", "s", "small", "strike", "strong", "tt", "u"].indexOf(tag.name) > -1):
                maker.activeFormattingElements.reconstruct();
                maker.activeFormattingElements.push( maker.insertHtmlElement(tag) );

            case Keyword(StartTag(tag)) if (tag.name == 'nobr'):
                maker.activeFormattingElements.reconstruct();

                if (maker.openElements.hasElementInScope('nobr')) {
                    maker.handleParseError('Parse error.');
                    adoptionAgencyAlgorithm(tag, maker);
                    maker.activeFormattingElements.reconstruct();

                }

                maker.activeFormattingElements.push( maker.insertHtmlElement(tag) );

            case Keyword(EndTag(tag)) if (["a", "b", "big", "code", "em", "font", "i", "nobr", "s", "small", "strike", "strong", "tt", "u"].indexOf(tag.name) > -1):
                adoptionAgencyAlgorithm(tag, maker);

            case Keyword(StartTag(tag)) if (["applet", "marquee", "object"].indexOf(tag.name) > -1):
                maker.activeFormattingElements.reconstruct();
                var ele = maker.insertHtmlElement(tag);
                ele.flags.set(FormatType.Marker);
                maker.activeFormattingElements.self().push( ele.id );
                // TODO: set frameset-ok to `not-ok`

            case Keyword(EndTag(tag)) if (["applet", "marquee", "object"].indexOf(tag.name) > -1):
                if (!maker.openElements.hasElementInScope(tag.name)) {
                    maker.handleParseError('Parse error.');
                    // Ignore the token.

                } else {
                    maker.generateImpliedEndTags([]);
                    if (maker.currentNode.nodeType != NodeType.Element && maker.currentNode.nodeName != tag.name) {
                        maker.handleParseError('Parse error.');

                    }

                    maker.openElements.popUntilNamed(tag.name);
                    maker.activeFormattingElements.clear();

                }

            case Keyword(StartTag(tag)) if (tag.name == 'table'):
                if (maker.document.mode != 'quirks' && maker.openElements.hasElementInButtonScope('p')) {
                    maker.closeParagraphElement();

                }

                maker.insertHtmlElement(tag);
                // TODO: set frameset-ok to `not-ok`
                insertionMode = InTable;

            case Keyword(EndTag(tag)) if (tag.name == 'br'):
                maker.handleParseError('Parse error.');
                tag.attributes = [];
                // TODO:
                /**
                    Parse error. Drop the attributes from the token, and act as 
                    described in the next entry; i.e. act as if this was a "br" 
                    start tag token with no attributes, rather than the end tag 
                    token that it actually is.
                **/

            case Keyword(StartTag(tag)) if (["area", "br", "embed", "img", "keygen", "wbr"].indexOf(tag.name) > -1):
                maker.activeFormattingElements.reconstruct();
                maker.insertHtmlElement(tag);
                maker.openElements.pop();
                // TODO: acknowledge the tokens self closing flag, if set.
                // TODO: set frameset-oke flag to `not ok`.

            case Keyword(StartTag(tag)) if (tag.name == 'input'):
                maker.activeFormattingElements.reconstruct();
                maker.insertHtmlElement(tag);
                maker.openElements.pop();
                // TODO: acknowledge the tokens self closing flag, if set.
                for (attribute in tag.attributes) if (attribute.name == 'input' && attribute.value != /*TODO*/ 'hidden') {
                    // TODO: set frameset-ok flag to `not ok`.
                    break;
                }

            case Keyword(StartTag(tag)) if (["param", "source", "track"].indexOf(tag.name) > -1):
                maker.insertHtmlElement(tag);
                maker.openElements.pop();
                // TODO: acknowledge the tokens self closing flag.

            case Keyword(StartTag(tag)) if (tag.name == 'hr'):
                if (maker.openElements.hasElementInButtonScope('p')) {
                    maker.closeParagraphElement();

                }

                maker.insertHtmlElement(tag);
                maker.openElements.pop();
                // TODO: acknowledge the tokens self closing flag.
                // TODO: set frameset-ok flag to `not ok`.

            case Keyword(StartTag(tag)) if (tag.name == 'image'):
                // Parse error. Change the token's tag name to "img" and reprocess it. (Don't ask.)
                maker.handleParseError('Parse error.');
                tag.name = 'img';
                process(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'textarea'):
                maker.insertHtmlElement(tag);
                if (maker.tokenizer.nextInputCharacter == '\u000A') @:privateAccess maker.tokenizer.pos += 2;
                maker.tokenizer.backpressure.push( Rules.rcdata_state );
                originalInsertionMode = insertionMode;
                // TODO: set frameset-ok to `not ok`.
                insertionMode = Text;

            case Keyword(StartTag(tag)) if (tag.name == 'xmp'):
                if (maker.openElements.hasElementInButtonScope('p')) {
                    maker.closeParagraphElement();

                }

                maker.activeFormattingElements.reconstruct();
                // TODO: set frameset-ok flag to `not ok`.
                genericRawTextElementParsing(tag, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'iframe'):
                // TODO set frameset-ok flag to `not ok`.
                genericRawTextElementParsing(tag, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'noembed' || tag.name == 'noscript' /*&& scriptingFlag*/):
                genericRawTextElementParsing(tag, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'select'):
                maker.activeFormattingElements.reconstruct();
                maker.insertHtmlElement(tag);
                // TODO: set frameset-ok flag to `not ok`.
                if ([InTable, InCaption, InTableBody, InRow, InCell].indexOf(insertionMode) > -1) {
                    insertionMode = InSelectInTable;
                } else {
                    insertionMode = InSelect;
                }

            case Keyword(StartTag(tag)) if (tag.name == 'optfroup' || tag.name == 'option'):
                if (maker.currentNode.nodeName == 'option') {
                    maker.openElements.pop();

                }

                maker.activeFormattingElements.reconstruct();
                maker.insertHtmlElement(tag);

            case Keyword(StartTag(tag)) if (tag.name == 'rb' || tag.name == 'rtc'):
                if (maker.openElements.hasElementInScope('ruby')) {
                    maker.generateImpliedEndTags([]);
                    if (maker.currentNode.nodeName != 'ruby') {
                        maker.handleParseError('Parse error.');

                    }

                }

                maker.insertHtmlElement(tag);

            case Keyword(StartTag(tag)) if (tag.name == 'rp' || tag.name == 'rt'):
                if (maker.openElements.hasElementInScope('ruby')) {
                    maker.generateImpliedEndTags(['rtc']);
                    if (maker.currentNode.nodeName != 'rtc' || maker.currentNode.nodeName != 'ruby') {
                        maker.handleParseError('Parse error.');

                    }

                }

                maker.insertHtmlElement(tag);

            case Keyword(StartTag(tag)) if (tag.name == 'math'):
                maker.activeFormattingElements.reconstruct();
                // TODO: adjust MathML attributes for token.
                // TODO: adjust foreign attributes for token.
                maker.insertForeignContent(tag, Namespaces.MathML);
                if (tag.selfClosing) {
                    maker.openElements.pop();
                    // TODO: acknowledge the tokens, self closing flag.
                }

            case Keyword(StartTag(tag)) if (tag.name == 'svg'):
                maker.activeFormattingElements.reconstruct();
                // TODO: adjust svg attributes for token.
                // TODO: adjust foreign attributes for token.
                maker.insertForeignContent(tag, Namespaces.SVG);
                if (tag.selfClosing) {
                    maker.openElements.pop();
                    // TODO: acknowledge the tokens, self closing flag.
                }

            case Keyword(StartTag(tag)) if (["caption", "col", "colgroup", "frame", "head", "tbody", "td", "tfoot", "th", "thead", "tr"].indexOf(tag.name) > -1):
                maker.handleParseError('Parse error.');
                // Ignore the token.

            case Keyword(StartTag(tag)):
                maker.activeFormattingElements.reconstruct();
                maker.insertHtmlElement(tag);

            case Keyword(EndTag(tag)):
                var index = maker.openElements.length - 1;
                var node = maker.openElements[index].get();
                
                while (index > 0) {
                    if (node.nodeType == NodeType.Element && node.nodeName == tag.name) {
                        maker.generateImpliedEndTags([tag.name]);
                        if (node.id != maker.openElements[maker.openElements.length - 1]) {
                            maker.handleParseError('Parse error.');

                        }

                        maker.openElements.popUntilKnown(node.id);
                        break;

                    } else {
                        if (node.categoryType() == 0) {
                            maker.handleParseError('Parse error.');
                            // Ignore the token.
                            return;
                        }

                    }

                    index--;
                    node = maker.openElements[index].get();
                }

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
                maker.handleParseError('Parse error.');
                if (maker.currentNode.nodeName == 'script') {
                    // TODO:
                }

                maker.openElements.pop();

                insertionMode = originalInsertionMode;
                process(token, maker);

            case Keyword(EndTag(tag)) if (tag.name == 'script'):
                // TODO: javascript execution context stack...
                var script = maker.currentNode;
                maker.openElements.pop();
                insertionMode = originalInsertionMode;
                // TODO: rest of case

            case Keyword(EndTag(tag)):
                maker.openElements.pop();
                insertionMode = originalInsertionMode;

            case _:
        }
    }

    private var pendingTableCharacterTokens:Array<String> = [];

    private function clearStackBackToTableContext(maker:Construction):Void {
        var matches = ['table', 'template', 'html'];
        while (maker.openElements.length > 0 && matches.indexOf(maker.currentNode.nodeName) == -1) {
            maker.openElements.pop();
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intable
    **/
    public function inTable(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:char})) if (['table', 'tbody', 'tfoot', 'thead', 'tr'].indexOf(maker.currentNode.nodeName) > -1):
                pendingTableCharacterTokens = [];
                originalInsertionMode = insertionMode;
                insertionMode = InTableText;
                process(token, maker);
            
            case Keyword(Comment({data:value})):
                maker.insertComment(value);

            case Keyword(DOCTYPE(_)):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)) if (tag.name == 'caption'):
                clearStackBackToTableContext(maker);
                var ele = maker.insertHtmlElement(tag);
                ele.flags.set(FormatType.Marker);
                maker.activeFormattingElements.self().push( ele );
                insertionMode = InCaption;

            case Keyword(StartTag(tag)) if (tag.name == 'colgroup'):
                clearStackBackToTableContext(maker);
                maker.insertHtmlElement(tag);
                insertionMode = InColumnGroup;

            case Keyword(StartTag(tag)) if (tag.name == 'col'):
                clearStackBackToTableContext(maker);
                maker.insertHtmlElement(tag); // TODO: process without attributes.
                insertionMode = InColumnGroup;
                process(token, maker);

            case Keyword(StartTag(tag)) if (['tbody', 'tfoot', 'thead'].indexOf(tag.name) > -1):
                clearStackBackToTableContext(maker);
                maker.insertHtmlElement(tag);
                insertionMode = InTableBody;

            case Keyword(StartTag(tag)) if (['tbody', 'th', 'tr'].indexOf(tag.name) > -1):
                clearStackBackToTableContext(maker);
                maker.insertHtmlElement({name:'tbody', attributes:[], selfClosing:false});
                insertionMode = InTableBody;
                process(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'table'):
                maker.handleParseError('Parse error.');
                if (!maker.openElements.hasElementInTableScope('table')) {
                    // Ignore the token.

                } else {
                    maker.openElements.popUntilNamed('table');
                    resetInsertionMode(maker);
                    process(token, maker);

                }

            case Keyword(EndTag(tag)) if (tag.name == 'table'):
                if (!maker.openElements.hasElementInTableScope('table')) {
                    maker.handleParseError('Parse error.');
                    // Ignore the token.

                } else {
                    maker.openElements.popUntilNamed('table');
                    resetInsertionMode(maker);

                }

            case Keyword(EndTag(tag)) if (["body", "caption", "col", "colgroup", "html", "tbody", "td", "tfoot", "th", "thead", "tr"].indexOf(tag.name) > -1):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)) if (["style", "script", "template"].indexOf(tag.name) > -1):
                inHead(token, maker);

            case Keyword(EndTag(tag)) if (tag.name == 'template'):
                inHead(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'input'):
                var match = false;
                for (attribute in tag.attributes) if (attribute.name == 'type' && attribute.value == 'hidden') {
                    match = true;
                    break;
                }

                if (match) {
                    maker.handleParseError('Parse error.');
                    maker.insertHtmlElement(tag);
                    maker.openElements.pop();
                    // TODO: acknowledge the tokens self closing flag.

                } else {
                    // TODO: go to "anything else" case.

                }

            case Keyword(StartTag(tag)) if (tag.name == 'form'):
                maker.handleParseError('Parse error.');
                if (maker.openElements.exists('template') || maker.document.formPtr != null) {
                    // Ignore the token.

                } else {
                    maker.document.formPtr = maker.insertHtmlElement(tag).id;
                    maker.openElements.pop();

                }

            case EOF:
                inBody(token, maker);

            case _:
                maker.handleParseError('Parse error.');
                // TODO: enable foster parenting.
                inBody(token, maker);
                // TODO: disable foster parenting.
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intabletext
    **/
    public function inTableText(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:'\u0000'})):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(Character({data:char})):
                pendingTableCharacterTokens.push(char);

            case _:
                for (value in pendingTableCharacterTokens) if ('\u0009\u000A\u000D\u0020'.indexOf(value) == -1) {
                    maker.handleParseError('Parse error.');
                    inTable_anythingElse(Keyword(Character({data:value})), maker);

                } else {
                    maker.insertCharacter(value);

                }

                insertionMode = originalInsertionMode;
                process(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incaption
    **/
    public function inCaption(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(EndTag(tag)) if (tag.name == 'caption'):
                if (!maker.openElements.hasElementInTableScope(tag.name)) {
                    maker.handleParseError('Parse error.');
                    // Ignore the token.

                } else {
                    maker.generateImpliedEndTags([]);
                    if (maker.currentNode.nodeName != tag.name) {
                        maker.handleParseError('Parse error.');

                    }

                    maker.openElements.popUntilNamed(tag.name);
                    maker.activeFormattingElements.clear();
                    insertionMode = InTable;

                }

            case Keyword(StartTag(tag)) if (["caption", "col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"].indexOf(tag.name) > -1):
                if (!maker.openElements.hasElementInTableScope('caption')) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    maker.generateImpliedEndTags([]);
                    if (maker.currentNode.nodeName != 'caption') {
                        maker.handleParseError('Parse error.');

                    }

                    maker.openElements.popUntilNamed('caption');
                    maker.activeFormattingElements.clear();
                    insertionMode = InTable;
                    process(token, maker);

                }

            case Keyword(EndTag(tag)) if (tag.name == 'table'):
                if (!maker.openElements.hasElementInTableScope('caption')) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    maker.generateImpliedEndTags([]);
                    if (maker.currentNode.nodeName != 'caption') {
                        maker.handleParseError('Parse error.');

                    }

                    maker.openElements.popUntilNamed('caption');
                    maker.activeFormattingElements.clear();
                    insertionMode = InTable;
                    process(token, maker);

                }

            case Keyword(EndTag(tag)) if (["body", "col", "colgroup", "html", "tbody", "td", "tfoot", "th", "thead", "tr"].indexOf(tag.name) > -1):
                maker.handleParseError('Parse error. Ignore the token.');

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
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)) if (tag.name == 'html'): 
                inBody(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'col'):
                maker.insertHtmlElement(tag);
                maker.openElements.pop();
                // TODO acknowledge the self closing flag, is set

            case Keyword(EndTag(tag)) if (tag.name == 'colgroup'):
                if (maker.currentNode.nodeName != tag.name) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    maker.openElements.pop();
                    insertionMode = InTable;

                }
                
            case Keyword(EndTag(tag)) if (tag.name == 'col'):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)), Keyword(EndTag(tag)) if (tag.name == 'template'):
                inHead(token, maker);

            case EOF:
                inBody(token, maker);

            case _:
                if (maker.currentNode.nodeName != 'colgroup') {
                    maker.handleParseError('Parse error. Ignore the token.');

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
                clearStackBackToTableContext(maker);
                maker.insertHtmlElement(tag);
                insertionMode = InRow;

            case Keyword(StartTag(tag)) if (['th', 'td'].indexOf(tag.name) > -1):
                maker.handleParseError('Parse error.');
                clearStackBackToTableContext(maker);
                maker.insertHtmlElement({name: 'tr', attributes: [], selfClosing: false});
                insertionMode = InRow;
                process(token, maker);

            case Keyword(EndTag(tag)) if (['tbody', 'tfoot', 'thead'].indexOf(tag.name) > -1):
                if (!maker.openElements.hasElementInTableScope(tag.name)) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    clearStackBackToTableContext(maker);
                    maker.openElements.pop();
                    insertionMode = InTable;

                }

            case Keyword(StartTag(tag)) if (["caption", "col", "colgroup", "tbody", "tfoot", "thead"].indexOf(tag.name) > -1):
                for (name in ["tbody", "tfoot", "thead"]) if (!maker.openElements.hasElementInTableScope(name)) {
                    maker.handleParseError('Parse error. Ignore the token.');
                    return;
                }

                clearStackBackToTableContext(maker);
                maker.openElements.pop();
                insertionMode = InTable;
                process(token, maker);

            case Keyword(EndTag(tag)) if (tag.name == 'table'):
                for (name in ["tbody", "tfoot", "thead"]) if (!maker.openElements.hasElementInTableScope(name)) {
                    maker.handleParseError('Parse error. Ignore the token.');
                    return;
                }

                clearStackBackToTableContext(maker);
                maker.openElements.pop();
                insertionMode = InTable;
                process(token, maker);

            case Keyword(EndTag(tag)) if (["body", "caption", "col", "colgroup", "html", "td", "th", "tr"].indexOf(tag.name) > -1):
                maker.handleParseError('Parse error. Ignore the token.');

            case _:
                inTable(token, maker);
                
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#clear-the-stack-back-to-a-table-row-context
    **/
    private function clearStackBackToTableRowContext(maker:Construction):Void {
        while (maker.openElements.length > 0) {
            if (['tr', 'template', 'html'].indexOf( maker.currentNode.nodeName ) == -1 ) {
                maker.openElements.pop();
            }
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intr
    **/
    public function inRow(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(StartTag(tag)) if (tag.name == 'th' || tag.name == 'td'):
                clearStackBackToTableRowContext(maker);
                var ele = maker.insertHtmlElement(tag);
                insertionMode = InCell;
                ele.flags.set(FormatType.Marker);
                maker.activeFormattingElements.self().push(ele);

            case Keyword(EndTag(tag)) if (tag.name == 'tr'):
                if (!maker.openElements.hasElementInTableScope(tag.name)) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    clearStackBackToTableRowContext(maker);
                    maker.openElements.pop();
                    insertionMode = InTableBody;

                }

            case Keyword(StartTag(tag)) if (["caption", "col", "colgroup", "tbody", "tfoot", "thead", "tr"].indexOf(tag.name) > -1):
                if (!maker.openElements.hasElementInTableScope('tr')) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    clearStackBackToTableRowContext(maker);
                    maker.openElements.pop();
                    insertionMode = InTableBody;
                    process(token, maker);

                }

            case Keyword(EndTag(tag)) if (tag.name == 'table'):
                if (!maker.openElements.hasElementInTableScope('tr')) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    clearStackBackToTableRowContext(maker);
                    maker.openElements.pop();
                    insertionMode = InTableBody;
                    process(token, maker);

                }

            case Keyword(EndTag(tag)) if (["tbody", "tfoot", "thead"].indexOf(tag.name) > -1):
                if (!maker.openElements.hasElementInTableScope(tag.name)) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else if (!maker.openElements.hasElementInTableScope('tr')) {
                    // Ignore the token.

                } else {
                    clearStackBackToTableRowContext(maker);
                    maker.openElements.pop();
                    insertionMode = InTableBody;
                    process(token, maker);
                }

            case Keyword(EndTag(tag)) if (["body", "caption", "col", "colgroup", "html", "td", "th"].indexOf(tag.name) > -1):
                maker.handleParseError('Parse error. Ignore the token.');

            case _:
                inTable(token, maker);
                
        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#close-the-cell
    **/
    private function closeTheCell(maker:Construction) {
        maker.generateImpliedEndTags([]);
        if (maker.currentNode.nodeName != 'td' || maker.currentNode.nodeName != 'th') {
            maker.handleParseError('Parse error.');

        }

        while (maker.openElements.length > 0) {
            var node = maker.openElements.pop().get();
            if (node.nodeName == 'td' || node.nodeName == 'th') break;
        }

        maker.activeFormattingElements.clear();
        insertionMode = InRow;
        
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intd
    **/
    public function inCell(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(EndTag(tag)) if (tag.name == 'td' || tag.name == 'th'):
                if (!maker.openElements.hasElementInTableScope(tag.name)) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    maker.generateImpliedEndTags([]);
                    if (maker.currentNode.nodeName != tag.name) {
                        maker.handleParseError('Parse error.');

                    }
                    maker.openElements.popUntilNamed(tag.name);
                    maker.activeFormattingElements.clear();
                    insertionMode = InRow;

                }

            case Keyword(StartTag(tag)) if (["caption", "col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"].indexOf(tag.name) > -1):
                if (!maker.openElements.hasElementInTableScope('td') || !maker.openElements.hasElementInTableScope('th')) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    closeTheCell(maker);
                    process(token, maker);

                }

            case Keyword(EndTag(tag)) if (["body", "caption", "col", "colgroup", "html"].indexOf(tag.name) > -1):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(EndTag(tag)) if (["table", "tbody", "tfoot", "thead", "tr"].indexOf(tag.name) > -1):
                if (!maker.openElements.hasElementInTableScope(tag.name)) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    closeTheCell(maker);
                    process(token, maker);

                }

            case _:
                inBody(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inselect
    **/
    public function inSelect(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:'\u0000'})):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(Character({data:char})):
                maker.insertCharacter(char);

            case Keyword(Comment({data:value})):
                maker.insertComment(value);

            case Keyword(DOCTYPE(_)):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                inBody(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'option'):
                if (maker.currentNode.nodeName == tag.name) {
                    maker.openElements.pop();

                }

                maker.insertHtmlElement(tag);

            case Keyword(StartTag(tag)) if (tag.name == 'optgroup'):
                if (maker.currentNode.nodeName == 'option') {
                    maker.openElements.pop();

                }

                if (maker.currentNode.nodeName == tag.name) {
                    maker.openElements.pop();

                }

                maker.insertHtmlElement(tag);

            case Keyword(EndTag(tag)) if (tag.name == 'optgroup'):
                if (maker.currentNode.nodeName == 'option' && maker.openElements[maker.openElements.length - 2].get().nodeName == 'optgroup') {
                    maker.openElements.pop();

                }

                if (maker.currentNode.nodeName == 'optgroup') {
                    maker.openElements.pop();

                } else {
                    maker.handleParseError('Parse error. Ignore the token.');

                }

            case Keyword(EndTag(tag)) if (tag.name == 'option'):
                if (maker.currentNode.nodeName == tag.name) {
                    maker.openElements.pop();

                } else {
                    maker.handleParseError('Parse error. Ignore the token.');

                }

            case Keyword(EndTag(tag)) if (tag.name == 'select'):
                if (!maker.openElements.hasElementInSelectScope(tag.name)) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    maker.openElements.popUntilNamed('select');
                    resetInsertionMode(maker);

                }

            case Keyword(StartTag(tag)) if (tag.name == 'select'):
                maker.handleParseError('Parse error.');
                if (!maker.openElements.hasElementInSelectScope('select')) {
                    // Ignore the token.

                } else {
                    maker.openElements.popUntilNamed('select');
                    resetInsertionMode(maker);

                }

            case Keyword(StartTag(tag)) if (["input", "keygen", "textarea"].indexOf(tag.name) > -1):
                maker.handleParseError('Parse error.');

                if (!maker.openElements.hasElementInSelectScope('select')) {
                    // Ignore the token.

                } else {
                    maker.openElements.popUntilNamed('select');
                    resetInsertionMode(maker);
                    process(token, maker);

                }

            case Keyword(StartTag(tag)) if (tag.name == 'script' || tag.name == 'template'):
                inHead(token, maker);

            case Keyword(EndTag(tag)) if (tag.name == 'template'):
                inHead(token, maker);

            case EOF:
                inBody(token, maker);

            case _:
                maker.handleParseError('Parse error. Ignore the token.');

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inselectintable
    **/
    public function inSelectInTable(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(StartTag(tag)) if (["caption", "table", "tbody", "tfoot", "thead", "tr", "td", "th"].indexOf(tag.name) > -1):
                maker.handleParseError('Parse error.');
                maker.openElements.popUntilNamed('select');
                resetInsertionMode(maker);
                process(token, maker);

            case Keyword(EndTag(tag)) if (["caption", "table", "tbody", "tfoot", "thead", "tr", "td", "th"].indexOf(tag.name) > -1):
                maker.handleParseError('Parse error.');
                if (!maker.openElements.hasElementInTableScope(tag.name)) {
                    // Ignore the token.

                } else {
                    maker.openElements.popUntilNamed('select');
                    resetInsertionMode(maker);
                    process(token, maker);

                }

            case _:
                inSelect(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intemplate
    **/
    public function inTemplate(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character(_) | Comment(_) | DOCTYPE(_)):
                inBody(token, maker);

            case Keyword(StartTag(tag)) if (["base", "basefont", "bgsound", "link", "meta", "noframes", "script", "style", "template", "title"].indexOf(tag.name) > -1):
                inHead(token, maker);

            case Keyword(EndTag(tag)) if (tag.name == 'template'):
                inHead(token, maker);

            case Keyword(StartTag(tag)) if (["caption", "colgroup", "tbody", "tfoot", "thead"].indexOf(tag.name) > -1):
                stackOfTemplateInsertionModes.pop();
                stackOfTemplateInsertionModes.push(InTable);
                insertionMode = InTable;
                process(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'col'):
                stackOfTemplateInsertionModes.pop();
                stackOfTemplateInsertionModes.push(InColumnGroup);
                insertionMode = InColumnGroup;
                process(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'tr'):
                stackOfTemplateInsertionModes.pop();
                stackOfTemplateInsertionModes.push(InTableBody);
                insertionMode = InTableBody;
                process(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'td' || tag.name == 'th'):
                stackOfTemplateInsertionModes.pop();
                stackOfTemplateInsertionModes.push(InRow);
                insertionMode = InRow;
                process(token, maker);

            case Keyword(StartTag(tag)):
                stackOfTemplateInsertionModes.pop();
                stackOfTemplateInsertionModes.push(InBody);
                insertionMode = InBody;
                process(token, maker);

            case Keyword(EndTag(_)):
                maker.handleParseError('Parse error. Ignore the token.');

            case EOF:
                if (!maker.openElements.exists('template')) {
                    return;

                } else {
                    maker.openElements.popUntilNamed('template');
                    maker.activeFormattingElements.clear();
                    stackOfTemplateInsertionModes.pop();
                    resetInsertionMode(maker);
                    process(token, maker);

                }
            
            case _:

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-afterbody
    **/
    public function afterBody(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                inBody(token, maker);

            case Keyword(Comment({data:value})):
                //maker.insertComment(value);
                var comment = new Comment(value);
                comment.id = maker.tree.addVertex( comment );
                maker.openElements[0].get().childrenPtr.push(comment.id);

            case Keyword(DOCTYPE(_)):
                maker.handleParseError('Parse error.');

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                inBody(token, maker);

            case Keyword(EndTag(tag)) if (tag.name == 'html'):
                // TODO: check if parser created in fragment parsing algo.
                insertionMode = AfterAfterBody;

            case EOF:
                // TODO: Stop everything!

            case _:
                maker.handleParseError('Parse error.');
                insertionMode = InBody;
                process(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inframeset
    **/
    public function inFrameset(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                maker.insertCharacter(char);

            case Keyword(Comment({data:value})):
                maker.insertComment(value);

            case Keyword(DOCTYPE(_)):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                inBody(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'frameset'):
                maker.insertHtmlElement(tag);

            case Keyword(EndTag(tag)) if (tag.name == 'frameset'):
                if (maker.currentNode.id == maker.openElements[0]) {
                    maker.handleParseError('Parse error. Ignore the token.');

                } else {
                    maker.openElements.pop();
                    // TODO: check if parser was created as part of fragment parsing algo.


                }

            case Keyword(StartTag(tag)) if (tag.name == 'frame'):
                maker.insertHtmlElement(tag);
                maker.openElements.pop();
                // TODO: acknowledge the tokens self closing flag.

            case Keyword(StartTag(tag)) if (tag.name == 'noframes'):
                inHead(token, maker);

            case EOF:
                if (maker.currentNode.id == maker.openElements[0]) {
                    maker.handleParseError('Parse error.');

                }

            case _:
                maker.handleParseError('Parse error. Ignore the token.');

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-afterframeset
    **/
    public function afterFrameset(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                maker.insertCharacter(char);

            case Keyword(Comment({data:value})):
                maker.insertComment(value);
            
            case Keyword(DOCTYPE(_)):
                maker.handleParseError('Parse error. Ignore the token.');

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                inBody(token, maker);

            case Keyword(EndTag(tag)) if (tag.name == 'html'):
                insertionMode = AfterAfterFrameset;

            case Keyword(StartTag(tag)) if (tag.name == 'noframes'):
                inHead(token, maker);

            case EOF:
                // TODO: stop everything!

            case _:
                maker.handleParseError('Parse error. Ignore the token.');

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#the-after-after-body-insertion-mode
    **/
    public function afterAfterBody(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Comment({data:value})):
                var comment = new Comment(value);
                comment.id = maker.tree.addVertex( comment );
                maker.document.childrenPtr.push( comment.id );

            case Keyword(DOCTYPE(_)):
                inBody(token, maker);

            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                inBody(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                inBody(token, maker);

            case EOF:
                // TODO: stop everything!

            case _:
                maker.handleParseError('Parse error.');
                insertionMode = InBody;
                process(token, maker);

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#the-after-after-frameset-insertion-mode
    **/
    public function afterAfterFrameset(token:Token<HtmlTokens>, maker:Construction):Void {
        switch token {
            case Keyword(Comment({data:value})):
                var comment = new Comment(value);
                comment.id = maker.tree.addVertex( comment );
                maker.document.childrenPtr.push( comment.id );

            case Keyword(DOCTYPE(_)):
                inBody(token, maker);

            case Keyword(Character({data:char})) if (['\u0009', '\u000A', '\u000C', '\u000D', '\u0020'].indexOf(char) > -1):
                inBody(token, maker);

            case Keyword(StartTag(tag)) if (tag.name == 'html'):
                inBody(token, maker);

            case EOF:
                // TODO: stop everything!

            case Keyword(StartTag(tag)) if (tag.name == 'noframes'):
                inHead(token, maker);

            case _:
                maker.handleParseError('Parse error. Ignore the token.');
        }
    }

}