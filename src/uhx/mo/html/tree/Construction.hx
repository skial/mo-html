package uhx.mo.html.tree;

import haxe.io.Eof;
import uhx.mo.dom.Tree;
import uhx.mo.dom.nodes.*;
import uhx.mo.html.Tokenizer;
import hxparse.UnexpectedChar;
import uhx.mo.html.internal.*;
import uhx.mo.html.rules.Rules;
import uhx.mo.infra.Namespaces;
import uhx.mo.dom.nodes.NodeType;
import uhx.mo.html.parsing.OpenElements;
import uhx.mo.html.parsing.InsertionRules;
import uhx.mo.html.parsing.FormattingElements;

using uhx.mo.html.macros.AbstractTools;

/**
    @see https://html.spec.whatwg.org/multipage/parsing.html#tree-construction
**/
class Construction {

    public static var current:Construction;
    public static function make(bytes:byte.ByteData, ?force:Bool = false):Construction {
        if (current == null || force) {
            current = new Construction(bytes);
        }
        return current;
    }

    public var tree:Tree;
    public var document:Document;
    public var insertionRules:InsertionRules;

    // @see https://html.spec.whatwg.org/multipage/parsing.html#next-token
    public var nextToken:String;

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#the-stack-of-open-elements
    */
    public var openElements:OpenElements = new OpenElements();

    // @see https://html.spec.whatwg.org/multipage/parsing.html#current-node
    public var currentNode(get, never):Null<Node>;

    private inline function get_currentNode():Null<Node> {
        return tree.vertices[ openElements[openElements.length - 1] ];
    }

    // @see https://html.spec.whatwg.org/multipage/parsing.html#adjusted-current-node
    public var adjustedCurrentNode(get, never):Node;

    private inline function get_adjustedCurrentNode():Node {
        // TODO: handle fragment parsing, which should return the `context` element.
        return currentNode;
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#the-list-of-active-formatting-elements
    **/
    public var activeFormattingElements:FormattingElements = new FormattingElements();

    // @see https://html.spec.whatwg.org/multipage/parsing.html#the-element-pointers
    public var headPointer:Null<Any> = null;
    public var formPointer:Null<Any> = null;

    // @see https://html.spec.whatwg.org/multipage/parsing.html#scripting-flag
    public var scriptingFlag:Bool = false;

    // @see https://html.spec.whatwg.org/multipage/parsing.html#frameset-ok-flag
    public var framesetOkFlag:Bool = true;

    public var fosterParenting:Bool = false;

    public var tokenizer:Tokenizer;

    public function new(bytes:byte.ByteData) {
        tree = new Tree();
        document = new Document(tree);
        tree.addVertex( document );
        insertionRules = new InsertionRules();
        tokenizer = new Tokenizer(bytes, 'html-parser::${document.id}::');
    }

    public function parse():Void {
        try while (true) {
            /**
            When a token is emitted, it must immediately be handled by the tree 
            construction stage. The tree construction stage can affect the state 
            of the tokenization stage, and can insert additional characters 
            into the stream. (For example, the script element can result in 
            scripts executing and using the dynamic markup insertion APIs to 
            insert characters into the stream being tokenized.)
            **/
            var token = tokenizer.tokenize( Rules.data_state );
            trace( token );
            switch token {
                case Keyword(ParseError(error)): handleParseError(error);
                case EOF: break;
                case _:
            }

            dispatcher( token );

        } catch (e:Eof) {
            trace( e );

        } catch (e:UnexpectedChar) {
            trace( e, e.char, e.pos );

        } catch (e:Any) {
            trace( e );
            trace( haxe.CallStack.toString( haxe.CallStack.exceptionStack() ) );

        }

    }

    public function handleParseError(error:String, ?pos:haxe.PosInfos):Void {
        trace(error, pos);
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#tree-construction
    **/
    public function dispatcher(token:Token<HtmlTokens>) {
        var tkn:HtmlTokens = switch token {
            case Keyword(t): t;
            case _: null;
        }
        if (tkn == null) return;
        var tknTag = tkn.getTag();
        var acn = openElements.length > 0 ? adjustedCurrentNode : null;
        var isMathMlPoint = isMathMLTextIntegrationPoint();
        var isHtmlPoint = isHtmlIntegrationPoint();
        var bool = 
            openElements.length == 0
            || (acn != null && isInHtmlNamespace(acn.nodeName))
            || (tknTag != null && isMathMlPoint && tknTag.name != 'mglyph' && tknTag.name != 'malignmark')
            || (tkn != null && isMathMlPoint && tkn.isCharacter())
            || (acn != null && tknTag != null && acn.nodeName == 'annotation-xml' && tknTag.name == 'svg')
            || (tkn != null && isHtmlPoint && tkn.isStartTag())
            || (tkn != null && isHtmlPoint && tkn.isCharacter())
            || token.match( EOF );

        if (bool) {
            insertionRules.process(token, this);

        } else {
            // foreignContent(token);

        }
        
    }

    // @see https://html.spec.whatwg.org/multipage/parsing.html#mathml-text-integration-point
    public function isMathMLTextIntegrationPoint():Bool {
        return false;
    }

    // @see https://html.spec.whatwg.org/multipage/parsing.html#html-integration-point
    public function isHtmlIntegrationPoint():Bool {
        return false;
    }

    // TODO sort alphabetically?
    public static final HtmlElements:Array<String> = uhx.mo.html.internal.HtmlTag.asArray();

    public inline function isInHtmlNamespace(tag:String):Bool {
        return HtmlElements.indexOf(tag) > -1;
    }

    //

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#appropriate-place-for-inserting-a-node
        @return InsertionLocation { node:Node, pos:Int }
    **/
    public function appropriateInsertionPoint(?overrideTarget:Node):InsertionLocation {
        var target = overrideTarget == null ? currentNode : overrideTarget;
        var targetIs = ['table', 'tbody', 'tfoot', 'thead', 'tr'];
        var pos = if (fosterParenting && targetIs.indexOf( target.nodeName ) > -1) {
            // TODO: implement steps.
            throw 'Not Implemented';

        } else {
            target.length > 1 ? target.length - 1 : 0;

        }

        return { node:target, pos:pos };
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#create-an-element-for-the-token
    **/
    public function createAnElementForToken(tag:Tag, namespace:String, intendedParent:Node):Element {
        var document:Document = intendedParent.ownerDocument;
        var localName:String = tag.name;
        var is = null;
        var definition = null; // TODO custom elements.
        var executeScript = false;
        var element = document.createAnElement(localName, Namespaces.HTML, null, is, false);
        // 8. Append each attribute in the given token to element.
        for (attr in tag.attributes) {
            // NOTE: `.self()` is accessing the raw array instead of the Abstract type.
            element.attributes.self().push( new Attr(attr.name, null, null, attr.value, element) );

        }
        
        return element;
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#insert-a-character
    **/
    public function insertCharacter(data:String):Void {
        var adjustedInsertionLocation = appropriateInsertionPoint();
        if (currentNode.nodeType == NodeType.Document) return;
        var pos = adjustedInsertionLocation.pos;
        var node = adjustedInsertionLocation.node.get();
        var parent = node.parent;
        var prev = parent.childNodes[pos-1];
        if (pos > 0 && prev != null && prev.nodeType == NodeType.Text) {
            prev.nodeValue += data;

        } else {
            var text = new Text(data, node.ownerDocument);
            adjustedInsertionLocation.insert( text );

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#insert-a-comment
    **/
    public function insertComment(value:String, ?position:Int):Void {
        var comment = new Comment(value);
        var adjustedInsertionLocation:InsertionLocation = position != null 
            ? { node:currentNode, pos:position }
            : appropriateInsertionPoint();

        comment.id = tree.addVertex( comment );
        adjustedInsertionLocation.insert( comment );
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#insert-a-foreign-element
    **/
    public function insertForeignContent(tag:Tag, namespace:String):Element {
        var adjustedInsertionLocation = appropriateInsertionPoint();
        var element = createAnElementForToken(tag, namespace, currentNode);

        // TODO: fully implement step 3.
        adjustedInsertionLocation.insert(element.id);

        openElements.push( element.id );
        return element;
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#insert-an-html-element
    **/
    public inline function insertHtmlElement(tag:Tag):Element {
        return insertForeignContent(tag, Namespaces.HTML);
    }

    /**
        ----
        Closing elements helper methods
        ----
    **/

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#generate-implied-end-tags
    **/
    public function generateImpliedEndTags(exclude:Array<String>):Void {
        while (currentNode != null) {
            switch currentNode.nodeName {
                case 'dd' | 'dt' | 'li' | 'optgroup' | 'option' | 'p' | 'rb' | 'rp' | 'rt' | 'rtc':
                    if (exclude.length > 0 && exclude.indexOf(currentNode.nodeName) == -1) {
                        openElements.pop();
                    }

                case _:
                    break;

            }

        }

    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#generate-all-implied-end-tags-thoroughly
    **/
    public function generateImpliedEndTagsThoroughly():Void {
        while (currentNode != null) {
            switch currentNode.nodeName {
                case 'caption' | 'colgroup' | 'dd' | 'dt' | 'li' | 'optgroup' | 'option' | 'p' | 'rb' | 'rp' | 'rt' | 'rtc' | 'tbody' | 'td' | 'tfoot' | 'th' | 'thead' | 'tr':
                    openElements.pop();

                case _:
                    break;

            }

        }
    }

    /**
        @see https://html.spec.whatwg.org/multipage/parsing.html#close-a-p-element
    **/
    public function closeParagraphElement():Void {
        generateImpliedEndTags(['p']);
        if (currentNode.nodeName != 'p') handleParseError('Parse error.');
        while (openElements.length > 0) {
            var element = openElements.pop().get();
            if (element.nodeName == 'p') break;
        }
    }

}