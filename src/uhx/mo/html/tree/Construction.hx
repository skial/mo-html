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

using uhx.mo.html.util.TokenUtil;
using uhx.mo.html.macros.AbstractTools;

// @see https://html.spec.whatwg.org/multipage/parsing.html#tree-construction
class Construction {

    public var tree:Tree;
    public var document:Document;

    // @see https://html.spec.whatwg.org/multipage/parsing.html#next-token
    public var nextToken:String;

    // @see https://html.spec.whatwg.org/multipage/parsing.html#the-stack-of-open-elements
    public var openElements:Array<NodePtr> = [];

    // @see https://html.spec.whatwg.org/multipage/parsing.html#current-node
    public var currentNode(get, never):Node;

    private inline function get_currentNode():Node {
        return tree.vertices[ openElements[openElements.length - 1] ];
    }

    // @see https://html.spec.whatwg.org/multipage/parsing.html#adjusted-current-node
    public var adjustedCurrentNode(get, never):Node;

    private inline function get_adjustedCurrentNode():Node {
        // TODO handle fragment parsing, which should return the `context` element.
        return currentNode;
    }

    // @see https://html.spec.whatwg.org/multipage/parsing.html#the-list-of-active-formatting-elements
    public var activeFormattingElements:Array<Any> = [];

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
        tokenizer = new Tokenizer(bytes, 'html-parser');
        tree = new Tree();
        document = new Document(tree);
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

            switch token {
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

        }

    }

    // @see https://html.spec.whatwg.org/multipage/parsing.html#tree-construction
    public function dispatcher(token:Token<HtmlTokens>) {
        trace( token );
        var tkn = token.sure(); // TODO this is wrong. Ignores consts.
        var tknTag = tkn.getTag();
        var acn = adjustedCurrentNode;
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
            || token.isEOF();

        if (bool) {
            // insertionMode(token);

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

    // @see https://html.spec.whatwg.org/multipage/parsing.html#appropriate-place-for-inserting-a-node
    public function appropriateInsertionPoint(?overrideTarget:Node):Int {
        var target = overrideTarget == null ? currentNode : overrideTarget;
        if (fosterParenting && (target.nodeName == 'table' || target.nodeName == 'tbody' || target.nodeName == 'tfoot' || target.nodeName == 'thead' || target.nodeName == 'tr')) {
            // TODO: implement steps.
            throw 'Not Implemented';

        } else {
            return target.length > 1 ? target.length - 1 : 0;

        }

        return 0;
    }

    // @see https://html.spec.whatwg.org/multipage/parsing.html#create-an-element-for-the-token
    public function createElement(tag:Tag, namespace:String, intendedParent:Node):Element {
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

    // @see https://html.spec.whatwg.org/multipage/parsing.html#insert-a-comment
    public function insertComment(value:String, ?position:Int):Void {
        var comment = new Comment(value);
        comment.id = tree.addVertex( comment );
    }

}