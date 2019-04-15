package uhx.mo.html;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import haxe.EnumTools;
import haxe.CallStack;
import hxparse.Ruleset;
import hxparse.Position;
import haxe.ds.StringMap;
import haxe.io.BytesBuffer;
import uhx.mo.html.NodeGraph;
import hxparse.UnexpectedChar;
import uhx.mo.html.NewLexer.HtmlTokensUtil.*;

using String;
using StringTools;
using haxe.io.Bytes;
using be.ds.util.DotGraph;
using uhx.mo.html.NewLexer;
using uhx.mo.html.NewLexer.HtmlTokensUtil;

private typedef Tokens = Array<Token<Node>>;

interface Node extends be.ds.IComparable<Node> extends be.ds.IIdentity {

    public var root:Node;
    public var parent:Null<Node>;
    public var length(get, null):Int;
    public var nodeName(get, null):String;
    public var nodeType(get, null):NodeType;
    public var nodeValue(get, null):Null<String>;
    public function clone(deep:Bool):Node;

}

class Ref<Child> implements Node {
	
    public var id(default, null):Int = be.ds.util.Counter.next();
    public var root:Node;
    public var value:Child;
	public var parent:Null<Node>;
	public var complete:Bool = true;
    public var length(get, null):Int;
    public var nodeType(get, null):NodeType;
    public var nodeName(get, null):String;
    public var nodeValue(get, null):Null<String>;
	
	public function new(value:Child, ?parent:Node) {
        this.value = value;
		this.parent = parent;
	}
	
	// @see https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode
	// `parent` should be null as the element isnt attached to any document.
	public function clone(deep:Bool) {
		return new Ref<Child>(value, null);
	}

    public function get_length() return 0;
    public function get_nodeType() return Unknown;
    public function get_nodeName() return '#unknown';
    public function get_nodeValue() return Std.string(value);

    public function compare(other:Node):Bool {
        return id == other.id;
    }
	
}

class TextRef extends Ref<String> {
	
    public function new(value:String, ?parent:Node) {
		super(value, parent);
	}
	
	// @see https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode
	// `parent` should be null as the element isnt attached to any document.
	override public function clone(deep:Bool) {
		return new TextRef(value, null);
	}

    override public function get_length() return value.length;
    override public function get_nodeType() return Text;
    override public function get_nodeName() return '#text';
    override public function get_nodeValue() return value;
	
}

class InstructionRef extends Ref<Array<String>> {
	
	public var isComment(default, null):Bool;
	
	public function new(value:Array<String>, ?isComment:Bool = true, ?parent:Node) {
		super(value, parent);
		this.isComment = isComment;
	}
	
	// @see https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode
	// `parent` should be null as the element isnt attached to any document.
	override public function clone(deep:Bool) {
		return new InstructionRef(deep ? value.copy() : value, isComment, null);
	}

    override public function get_length() return value.length;
    override public function get_nodeType() return NodeType.Comment;
    override public function get_nodeName() return '#' + (isComment ? 'comment' : 'instruction');
    override public function get_nodeValue() return value.join('');
	
}

class HtmlRef extends Ref<Tokens> {
	
	public var name:String;
	public var selfClosing:Bool = false;
	public var categories:Array<Category> = [];
	public var attributes:StringMap<String> = new StringMap();
	
	public function new(name:String, attributes:StringMap<String>, categories:Array<Category>, values:Tokens, ?parent:Node, ?complete:Bool = false, ?selfClosing:Bool = false) {
		super(values, parent);
		this.name = name;
		this.complete = complete;
		this.attributes = attributes;
		this.categories = categories;
		this.selfClosing = selfClosing;
	}
	
	// @see https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode
	// `parent` should be null as the element isnt attached to any document.
	override public function clone(deep:Bool) {
		return new HtmlRef(
			'$name', 
			[for (k in attributes.keys()) k => attributes.get(k)], 
			categories.copy(), 
			deep ? [/*for (t in tokens) (t:dtx.mo.DOMNode).cloneNode( deep )*/] : [for (t in value) t], 
			null, 
			complete,
			selfClosing
		);
	}

    override public function get_length() return value.length;
    override public function get_nodeType() return Element;
    override public function get_nodeName() return name.toUpperCase();
    override public function get_nodeValue() return null;
	
}

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

enum abstract Model(Int) from Int to Int {
	public var Empty = 1;
	public var Text = 2;
	public var Element = 3;
}

enum abstract NodeType(Int) from Int to Int {
	public var Unknown = -1;
	public var Document = 0;
	public var Comment = 1;
	public var Text = 2;
	public var Element = 3;
}

enum abstract HtmlTag(String) from String to String {
	public var Base = 'base';
	public var Link = 'link';
	public var Meta = 'meta';
	public var NoScript = 'noscript';
	public var Script = 'script';
	public var Style = 'style';
	public var Template = 'template';
	public var Title = 'title';
	public var A = 'a';
	public var Abbr = 'abbr';
	public var Address = 'address';
	public var Area = 'area';
	public var Article = 'article';
	public var Aside = 'aside';
	public var Audio = 'audio';
	public var B = 'b';
	public var Bdi = 'bdi';
	public var Bdo = 'bdo';
	public var BlockQuote = 'blockquote';
	public var Br = 'br';
	public var Button = 'button';
	public var Canvas = 'canvas';
	public var Cite = 'cite';
	public var Code = 'code';
	public var Data = 'data';
	public var DataList = 'datalist';
	public var Del = 'del';
	public var Details = 'details';
	public var Dfn = 'dfn';
	public var Dialog = 'dialog';
	public var Div = 'div';
	public var Dl = 'dl';
	public var Em = 'em';
	public var Embed = 'embed';
	public var FieldSet = 'fieldset';
	public var Figure = 'figure';
	public var Footer = 'footer';
	public var Form = 'form';
	public var H1 = 'h1';
	public var H2 = 'h2';
	public var H3 = 'h3';
	public var H4 = 'h4';
	public var H5 = 'h5';
	public var H6 = 'h6';
	public var Header = 'header';
	public var Hr = 'hr';
	public var I = 'i';
	public var Iframe = 'iframe';
	public var Img = 'img';
	public var Input = 'input';
	public var Ins = 'ins';
	public var Kbd = 'kbd';
	public var Keygen = 'keygen';
	public var Label = 'label';
	public var Main = 'main';
	public var Map = 'map';
	public var Mark = 'mark';
	public var Math = 'math';
	public var Menu = 'menu';
	public var Meter = 'meter';
	public var Nav = 'nav';
	public var Object = 'object';
	public var Ol = 'ol';
	public var Output = 'output';
	public var P = 'p';
	public var Pre = 'pre';
	public var Progress = 'progress';
	public var Q = 'q';
	public var Ruby = 'ruby';
	public var S = 's';
	public var Samp = 'samp';
	public var Section = 'section';
	public var Select = 'select';
	public var Small = 'small';
	public var Span = 'span';
	public var Strong = 'strong';
	public var Sub = 'sub';
	public var Sup = 'sup';
	public var Svg = 'svg';
	public var Table = 'table';
	public var TextArea = 'textarea';
	public var Time = 'time';
	public var U = 'u';
	public var Ul = 'ul';
	public var Var = 'var';
	public var Video = 'video';
	public var Wbr = 'wbr';
	
	public var Col = 'col';
	public var Command = 'command';
	public var FigCaption = 'figcaption';
	public var HGroup = 'hgroup';
	public var Param = 'param';
	public var RP = 'rp';
	public var RT = 'rt';
	public var Source = 'source';
	public var Summary = 'summary';
	public var Track = 'track';
	
	public var Content = 'content';
	
	public var Html = 'html';
	public var Head = 'head';
}

/**
 * ...
 * @author Skial Bainn
 */

class NewLexer extends hxparse.Lexer {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public var graph:NodeGraph = new NodeGraph();
	public var parent:Null<HtmlRef> = null;
	public var openTags:Array<HtmlRef> = [];
	
	public static var openClose = Mo.rules( [
	'<' => lexer.token( tags ),
	'>' => GreaterThan,
	'[^<>]+' => {
		var ref = new TextRef( lexer.current/*, lexer.parent*/ );
		//var enm = HtmlKeywords.Text( ref );
		//var node = new Vertex( enm );
		lexer.graph.addVertex( ref );
		if (lexer.parent != null) lexer.graph.addEdge(lexer.parent, ref);
		//Keyword( enm );
		//Ignore;
        Keyword( ref );
	}
	] );
	
	public static var tags = Mo.rules( [ 
	' +' => Space(lexer.current.length),
	'\r' => Carriage,
	'\n' => Newline,
	'\t' => Tab(1),
	'/>' => lexer.token( openClose ),
	'[!?]' => {
		var attrs = [];
		var aComment = lexer.current == '!';
		
		try while (true) {
			var token:String = lexer.token( instructions );
			attrs.push( token );
			
		} catch (e:Eof) {
            trace( e );

         } catch (e:UnexpectedChar) {
            if (e.char == '>') {
                lexer.pos++;

            } else {
                throw e;

            }
			
		} catch (e:Any) {
			trace( e );

		}
		
		if (!aComment && attrs[attrs.length -1] == '?') attrs = attrs.slice(0, attrs.length - 1);
		
		var ref = new InstructionRef( attrs, aComment/*, lexer.parent*/ );
		lexer.graph.addVertex( ref );
		if (lexer.parent != null) lexer.graph.addEdge(lexer.parent, ref); 
        Keyword( ref );
	},
	'/[^\r\n\t <>]+>' => {
		//Keyword( End( lexer.current.substring(1, lexer.current.length -1) ) );
        trace('end', lexer.current);
        Keyword( new Ref<String>( lexer.current.substring(1, lexer.current.length-1) ) );
	},
	'[a-zA-Z0-9:]+' => {
		var tokens:Tokens = [];
		var tag:String = lexer.current;
		var categories = tag.categories();
		var model = tag.model();
		var attrs = new StringMap<String>();
		
		var isVoid = model == Model.Empty;
		
		try while (true) {
			var token:Array<String> = lexer.token( attributes );
			attrs.set( token[0], token[1] );
			
		} catch (e:Eof) { } catch (e:UnexpectedChar) {
			if (e.char == '/') {
                lexer.pos++;
				isVoid = true;
				
				// This skips over the self closing characters `/>`
				// I cant see at the moment how to handle this better.
				try while (true) {
					var token:Token<Node> = lexer.token( openClose );
					switch (token) {
                        case GreaterThan:
                            break;

                        case x:
							throw x;

					}
				} catch (e:Any) {
					trace( e );

				}
				
			} else if (e.char == '>') {
				lexer.pos++;

			} else {
                trace( e.pos, e.char );

            }
			
		} catch (e:Any) {}
		
		var first = lexer.openTags.length == 0;
		var ref = new HtmlRef(
			tag, 
			attrs,
			categories, 
			tokens/*,
			lexer.parent*/
		);
		
		var position = -1;
		//var enm = Tag(ref);
		//var node = new Vertex( enm );
		lexer.graph.addVertex( ref );
		
		if (!isVoid) {
			
			switch (categories) {
				case x if (x.indexOf( Category.Metadata ) != -1):
					position = buildMetadata( ref, lexer );
					
				case _:
					position = buildChildren( ref, lexer );
					
			}
			
			
		} else {
			ref.complete = true;
		}
		
		// If this node is the first, mark it as the document.
		if (first && ref.categories.indexOf( Category.Root ) == -1) ref.categories.push( Category.Root );
		ref.selfClosing = isVoid;
		
		//if (lexer.parent != null) lexer.graph.addSingleArc(lexer.parent, node);

		//Keyword( enm );
		//Ignore;
        Keyword( ref );
	},
	] );
	
	public static var attributes = Mo.rules( [
	'[ \r\n\t]' => lexer.token( attributes ),
	'[^\r\n\t /=>]+[\r\n\t ]*=[\r\n\t ]*' => {
		var index = lexer.current.indexOf('=');
		var key = lexer.current.substring(0, index).rtrim();
		var value = try {
			lexer.token( attributesValue );
		} catch (e:Any) {
			'';
		}
		
		[key, value];
	},
	'[^\r\n\t /=>]+' => [lexer.current, '']
	] );
	
	public static var attributesValue = Mo.rules( [
	'"[^"]*"' => lexer.current.substring(1, lexer.current.length-1),
	'\'[^\']*\'' => lexer.current.substring(1, lexer.current.length-1),
	'[^ "\'><]+' => lexer.current,
	] );
	
	public static var instructions = Mo.rules( [
	'[a-zA-Z0-9]+' => lexer.current,
	'[^a-zA-Z0-9 \r\n\t<>"\\[]+' => lexer.current,
	'[a-zA-Z0-9#][^\r\n\t <>"\\[]+[^\\- \r\n\t<>"\\[]+' => lexer.current,
	'[\r\n\t ]+' => lexer.current,
	'\\[' => {
		var value = '';
		var original = lexer.current;
		
		try while (true) {
			var token:String = lexer.token( instructionText );
			
			switch (token) {
				case ']' if (original == '['):
					value = '[$value]';
					break;
					
				case _:
					
			}
			
			value += token;
		} catch (e:Any) {
			trace( e );
		}
		value;
	},
	'<' => {
		var value = '';
		var counter = 0;
		
		try while (true) {
			var token:String = lexer.token( instructionText );
			
			switch (token) {
				case '>' if (counter > 0):
					counter--;
					
				case '>':
					break;
					
				case '<':
					counter++;
					
				case _:
					
			}
			
			value += token;
		} catch (e:Any) {
			trace( e );
		}
		'<$value>';
	},
	'"' => {
		var value = '';
		
		try while (true) {
			var token = lexer.token( Mo.rules([ '"' => '"', '[^"]+' => lexer.current ])  );
			
			switch (token) {
				case '"':
					break;
					
				case _:
					
			}
			
			value += token;
		} catch (e:Any) {
			trace( e );
		}
		'$value';
	}
	] );
	
	public static var instructionText = Mo.rules( [
	'[^\\]<>]+' => lexer.current,
	'\\]' => ']',
	'<' => '<',
	'>' => '>'
	] );
	
	public static var root = openClose;
	
	// Get the categories that each element falls into.
	private static function categories(tag:String):Array<Category> {
		/**
		Unknown = -1;
		Metadata = 0;
		Flow = 1;
		Sectioning = 2;
		Heading = 3;
		Phrasing = 4;
		Embedded = 5;
		Interactive = 6;
		Palpable = 7;
		Scripted = 8;
		 */
		return switch (tag) {
			case Base, Link, Meta: [0];
			case Style: [0, 1];
			case Dialog, Hr: [1];
			case NoScript, Command: [0, 1, 4];
			case Area, Br, DataList, Del, Time, Wbr: [1, 4];
			case TextArea: [1, 4, 6];
			case H1, H2, H3, H4, H5, H6, HGroup: [1, 3, 7];
			case Address, BlockQuote, Div, Dl, FieldSet, Figure,
				 Footer, Form, Header, Main, Menu, Ol, P, Pre, 
				 Table, Ul: [1, 7];
			case Article, Aside, Nav, Section: [1, 2, 7];
			case Abbr, B, Bdi, Bdo, Cite, Code, Data, Dfn, Em, 
				 I, Ins, Kbd, Map, Mark, Meter, Output, Progress,
				 Q, Ruby, S, Samp,  Small, Span, Strong,
				 Sub, Sup, U, Var: [1, 4, 7];
			case Details: [1, 6, 7];
			case Canvas, Math, Svg: [1, 4, 5, 7];
			case A, Button, Input, Keygen, Label, Select: [1, 4, 6, 7];
			case Audio, Embed, Iframe, Img, Object, Video: [1, 4, 5, 6, 7];
			case Script, Template: [0, 1, 4, 8];
			case _: [ -1];
		}
	}
	
	// Get the expected content model for the html element.
	private static function model(tag:String):Model {
		return switch (tag) {
			case Area, Base, Br, Col, Command, Embed, Hr, Img,
				 Input, Keygen, Link, Meta, Param, Source, Track,
				 Wbr:
				Model.Empty;
				
			case NoScript, Script, Style, Title, Template:
				Model.Text;
				
			case _:
				Model.Element;
				
		}
	}
	
	// Build descendant html elements
	private static function buildChildren(ref:HtmlRef, lexer:NewLexer):Int {
		var position = lexer.openTags.push( ref ) - 1;
		trace(ref);
		var previousParent = lexer.parent;
		lexer.parent = ref;
		
		var tag = null;
		var index = -1;
		try while (true) {
			var token:Token<Node> = lexer.token( openClose );
			
			switch (token) {
				case GreaterThan:
					continue;
					
				//case Keyword( End( t ) ):
                case Keyword( { nodeType:Unknown, nodeValue:t } ) if(t != null):
                    trace( t );
					index = -1;
					tag = null;
					
					var i = lexer.openTags.length - 1;
					while (i >= 0) {
						tag = lexer.openTags[i];
						if (tag != null && !tag.complete && t == tag.name) {
							index = i;
							tag.complete = true;
							
							break;
						}
						i--;
					}
					
					if (index == position) {
						break;
						
					} else if (index > -1) {
						continue;
						
					}
					
				case x:
                    trace( x );
			}
			
			var node = switch token {
				//case Keyword(enm): new Vertex( enm );
                case Keyword(node): node;
				case x: 
					trace(x);
					null;
			};
			//trace(lexer.parent.val);
			//trace(node);
			if (node != null) {
				lexer.graph.addVertex( node );
				lexer.graph.addEdge(lexer.parent, node);

			}
			//ref.tokens.push( token );
		} catch (e:Eof) {
			
		} catch (e:UnexpectedChar) {
			trace( e );

		} catch (e:Any) {
			//trace( lexer.graph.asDotGraph( 'htmlgraph' ) );
			trace( e, CallStack.exceptionStack() );

		}
		
		lexer.parent = previousParent;
		
		return position;
	}
	
	private static function scriptedRule(tag:String) return Mo.rules( [
	'</[ ]*$tag[ ]*>' => {
		//Keyword( End( lexer.current.substring(2, lexer.current.length - 1) ) );
        trace(lexer.current);
        Keyword( new Ref<String>( lexer.current.substring(2, lexer.current.length - 1) ) );
	},
	'[^\r\n\t<]+' => {
		Const(CString( lexer.current ));
	},
	'[\r\n\t]+' => {
		Const(CString( lexer.current ));
	},
	'<' => {
		Const(CString( lexer.current ));
	},
	] );
	
	// Build Html Category of type Metadata
	private static function buildMetadata(ref:HtmlRef, lexer:NewLexer):Int {
		var position = lexer.openTags.push( ref ) - 1;
		var rule = scriptedRule( ref.name );
		
		try while (true) {
			var token:Token<Node> = lexer.token( rule );
			
			switch (token) {
				//case Keyword(End( x )) if (x == ref.name):
                case Keyword( { nodeType:Unknown, nodeValue:x } ) if (x != null && x == ref.name):
                trace(x);
					// Set the reference as complete.
					ref.complete = true;
					// Combine all tokens into one token.
					/*var enm = HtmlKeywords.Text(new Ref( 
							[for (t in ref.tokens) switch(t) {
								case Const(CString(x)): x;
								case _: '';
							}].join('')
						//, new GraphNode( Tag(ref) )
						));*/
                    var node = new TextRef( [for (t in ref.value) switch(t) {
								case Const(CString(x)): x;
								case _: '';
							}].join('') );
					//var node = new Vertex( enm );
					lexer.graph.addVertex( node );
					lexer.graph.addEdge(lexer.parent, node);
					//ref.tokens = [ Keyword( enm ) ];
					break;
					
				case _:
					
			}
			
			//ref.tokens.push( token );
		} catch (e:Dynamic) {
			trace( e );
		}
		
		return position;
	}

	public var openElements:Array<Node> = [];
	public var returnState:Null<Ruleset<Token<HtmlTokens>>> = null;
	public var temporaryBuffer:Null<String> = null;
	public var currentInputCharacter:Null<String> = null;
	public var currentToken:Null<HtmlTokens> = null;
	public var lastToken:Null<HtmlTokens> = null;

	private var backlog:Array<Token<HtmlTokens>> = [];
	private var backpressure:Array<Ruleset<Token<HtmlTokens>>> = [];

	public inline function emit(value:BacklogValue):Void {
		value(backlog);
	}

	public function tokenize(ruleset:Ruleset<Token<HtmlTokens>>):Token<HtmlTokens> {
		if (backlog.length > 0) {
			backpressure.push( ruleset );
			return backlog.shift();
		}
		if (backpressure.length > 0) {
			return super.token(backpressure.shift());
		}
		// Might need to capture result. Check backlog before returning or store into backlog?
		return super.token(ruleset);
	}

	public static function consume<R:Ruleset<Token<HtmlTokens>>>(lexer:NewLexer, next:R, returnState:Null<R> = null, buffer:Null<BytesBuffer> = null) {
		lexer.returnState = returnState;
		return lexer.tokenize( next );
	}

    public static function reconsume<R:Ruleset<Token<HtmlTokens>>>(lexer:NewLexer, ruleset:R, characters:Int = 1) {
        lexer.pos -= characters;
		return lexer.tokenize( ruleset );
    }

	// @see https://html.spec.whatwg.org/multipage/parsing.html#data-state
	public static var data_state = Mo.rules( [
		'&' => lexer.consume( character_reference_state, data_state ),
		'<' => lexer.tokenize( tag_open_state ),
		NULL => Const(CString(lexer.currentInputCharacter)),
		'' => EOF,
		'[^&<]' => Const(CString(lexer.currentInputCharacter)),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-state
	public static var rcdata_state = Mo.rules( [
		'&' => lexer.consume( character_reference_state, rcdata_state ),
		'<' => lexer.tokenize( rcdata_less_than_sign_state ),
		NULL => Const(CString('\uFFFD')),
		'' => EOF,
		'[^&<]' => Const(CString(lexer.currentInputCharacter)),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-state
	public static var rawtext_state = Mo.rules( [
		'<' => lexer.tokenize( rawtext_less_than_sign_state ),
		NULL => Const(CString('\uFFFD')),
		'' => EOF,
		'[^&<]' => Const(CString(lexer.currentInputCharacter)),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-state
	public static var script_data_state = Mo.rules( [
		'<' => lexer.tokenize( script_data_less_than_sign_state ),
		NULL => Const(CString('\uFFFD')),
		'' => EOF,
		'[^&<]' => Const(CString(lexer.currentInputCharacter)),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#plaintext-state
	public static var plaintext_state = Mo.rules( [
		NULL => Const(CString('\uFFFD')),
		'' => EOF,
		'[^&<]' => Const(CString(lexer.current)),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#tag-open-state
	public static var tag_open_state = Mo.rules( [
		'!' => lexer.tokenize( markup_declaration_open_state ),
		'/' => lexer.tokenize( end_tag_open_state ),
		'[a-zA-Z]' => {
			lexer.currentToken = StartTag( makeTag() );
			lexer.reconsume( tag_name_state );
		},
		'?' => {
			lexer.currentToken = Comment({data:''});
			lexer.reconsume( bogus_comment_state );
		},
		'' => {
			lexer.emit(EOF);
			Keyword( Character({data:'<'}) );
		},
		'[^!\\/a-zA-Z\\?]' => {
			lexer.emit('<');
			lexer.reconsume( data_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#end-tag-open-state
	public static var end_tag_open_state = Mo.rules( [
		'[a-zA-Z]' => {
			lexer.currentToken = EndTag( makeTag() );
			lexer.reconsume( tag_name_state );
		},
		'>' => lexer.tokenize( data_state ),
		'' => {
			lexer.emit('<');
			lexer.emit('/');
			EOF;
		},
		'[^a-zA-Z>]' => {
			lexer.currentToken = Comment( {data:''} );
			lexer.reconsume( bogus_comment_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#tag-name-state
	public static var tag_name_state = Mo.rules( [
		'[\t\n \u000C]' => lexer.tokenize( before_attribute_name_state ),
		'/' => lexer.tokenize( self_closing_start_tag_state ),
		'>' = {
			lexer.backpressure.push( data_state );
			Keyword(lexer.lastTag = lexer.currentToken);
		},
		'[A-Z]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.current.toLowerCase();

				case x:
					trace( x );
			}
			lexer.tokenize( tag_name_state );
		},
		NULL => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( tag_name_state );
		},
		'' => EOF,
		'[^\t\n \u000C/>A-Z]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.current;

				case x:
					trace( x );
			}
			lexer.tokenize( tag_name_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-less-than-sign-state
	public static var rcdata_less_than_sign_state = Mo.rules( [
		'/' => {
			lexer.temporaryBuffer = '';
			lexer.reconsume( rcdata_end_tag_open_state );
		},
		'[^/]' => {
			lexer.emit('<');
			lexer.reconsume( rcdata_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-open-state
	public static var rcdata_end_tag_open_state = Mo.rules( [
		'[a-zA-Z]' => {
			lexer.currentToken = EndTag( makeTag() );
			lexer.reconsume( rcdata_end_tag_name_state );
		},
		'[^a-zA-Z]' => {
			lexer.emit('<');
			lexer.emit('/');
			lexer.reconsume( rcdata_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-name-state
	public static var rcdata_end_tag_name_state = Mo.rules( [
		'[\t\n\u000C ]' => {
			if (lexer.isAppropiateEndTag()) {
				lexer.tokenize( before_attribute_name_state );

			} else {
				lexer.emit('<');
				lexer.emit('/');
				lexer.emit( lexer.temporaryBuffer );
				lexer.reconsume( rcdata_state );

			}
		},
		'/' => {
			if (lexer.isAppropiateEndTag()) {
				lexer.tokenize( self_closing_start_tag_state );

			} else {
				lexer.emit('<');
				lexer.emit('/');
				lexer.emit( lexer.temporaryBuffer );
				lexer.reconsume( rcdata_state );

			}
		},
		'>' => {
			if (lexer.isAppropiateEndTag()) {
				lexer.emit( Keyword(lexer.currentToken) );
				lexer.tokenize( data_state );

			} else {
				lexer.emit('<');
				lexer.emit('/');
				lexer.emit( lexer.temporaryBuffer );
				lexer.reconsume( rcdata_state );

			}
		},
		'[A-Z]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.current.toLowerCase();

				case x:
					trace(x);

			}
			lexer.temporaryBuffer += lexer.current;
			lexer.tokenize( rcdata_end_tag_name_state );
		},
		'[a-z]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.current;

				case x:
					trace(x);

			}
			lexer.temporaryBuffer += lexer.current;
			lexer.tokenize( rcdata_end_tag_name_state );
		},
		'[^\t\n\u000C />A-Za-z]' => {
			lexer.emit('<');
			lexer.emit('/');
			lexer.emit( lexer.temporaryBuffer );
			lexer.reconsume( rcdata_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-less-than-sign-state
	public static var rawtext_less_than_sign_state = Mo.rules( [
		'/' => {
			lexer.temporaryBuffer = '';
			lexer.tokenize( rawtext_end_tag_open_state );
		},
		'[^/]' => {
			lexer.emit('<');
			lexer.reconsume( rawtext_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-open-state
	public static var rawtext_end_tag_open_state = Mo.rules( [
		'[a-z]' => {
			lexer.currentToken = EndTag( makeTag() );
			lexer.reconsume( rawtext_end_tag_name_state );
		},
		'[^a-z]' => {
			lexer.emit('<');
			lexer.emit('/');
			lexer.reconsume( rawtext_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-name-state
	public static var rawtext_end_tag_name_state = Mo.rules( [
		'[\t\n\u000C ]' => {
			if (lexer.isAppropiateEndTag()) {
				lexer.tokenize( before_attribute_name_state );

			} else {
				lexer.emit('<');
				lexer.emit('/');
				lexer.emit( lexer.temporaryBuffer );
				lexer.reconsume( rawtext_state );

			}
		},
		'/' => {
			if (lexer.isAppropiateEndTag()) {
				lexer.tokenize( self_closing_start_tag_state );

			} else {
				lexer.emit('<');
				lexer.emit('/');
				lexer.emit( lexer.temporaryBuffer );
				lexer.reconsume( rawtext_state );

			}
		},
		'>' => {
			if (lexer.isAppropiateEndTag()) {
				lexer.emit( Keyword( lexer.currentToken ) );
				lexer.tokenize( data_state );

			} else {
				lexer.emit('<');
				lexer.emit('/');
				lexer.emit( lexer.temporaryBuffer );
				lexer.reconsume( rawtext_state );

			}
		},
		NULL => {
			lexer.emit('\uFFFD');
			lexer.tokenize( script_data_double_escaped_state );
		},
		'' => EOF,
		'[^\t\n\u000C />]' => {
			lexer.emit(lexer.current);
			lexer.tokenize( script_data_double_escaped_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-less-than-sign-state
	public static var script_data_less_than_sign_state = Mo.rules( [
		'/' => /*temp buffer*/ lexer.token( script_data_end_tag_open_state ),
		'!' => /*emit `<` and `!`*/ lexer.token( script_data_escape_start_state ),
		'[^/!]+' => /*emit `<`*/ /*reconsume*/ lexer.token( script_data_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-open-state
	public static var script_data_end_tag_open_state = Mo.rules( [
		'[a-z]' => /*reconsume*/ lexer.token( script_data_end_tag_name_state ),
		'[^a-z]+' => /*emit `<` and `/`*/ /*reconsume*/ lexer.token( script_data_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-name-state
	public static var script_data_end_tag_name_state = Mo.rules( [
		'[\t\n\u000C ]' => null,
		'/' => null,
		'>' => null,
		'[A-Z]' => null,
		'[a-z]' => null,
		'[^\t\n\u000C />A-Za-z]+' => null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escape-start-state
	public static var script_data_escape_start_state = Mo.rules( [
		'\\-' => /*emit `-`*/ lexer.token( script_data_escape_start_dash_state ),
		'[^\\-]+' => /*reconsume*/ lexer.token( script_data_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escape-start-dash-state
	public static var script_data_escape_start_dash_state = Mo.rules( [
		'\\-' => lexer.token( script_data_escaped_dash_dash_state ), /*emit `-`*/
		'[^\\-]+' => /*reconsume*/ lexer.token( script_data_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-state
	public static var script_data_escaped_state = Mo.rules( [
		'\\-' => null,
		'<' => null,
		// null character
		// EOF
		'[^\\-<]' => Const(CString(lexer.current)),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-state
	public static var script_data_escaped_dash_state = Mo.rules( [
		'\\-' => null,
		'<' => null,
		// null character
		// EOF
		'[^\\-<]' => null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-dash-state
	public static var script_data_escaped_dash_dash_state = Mo.rules( [
		'\\-' => null,
		'<' => null,
		'>' => null,
		// null character
		// EOF
		'[^\\-<>]' => null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-less-than-sign-state
	public static var script_data_escaped_less_than_sign_state = Mo.rules( [
		'/' => /*temp buff*/ lexer.token( script_data_escaped_end_tag_open_state ),
		'[a-zA-Z]' => /*temp buff*/ /*emit `<`*/ /*reconsume*/ lexer.token( script_data_double_escape_start_state ),
		'[^/a-zA-Z]' => /* `<`*/ /*reconsume*/ lexer.token( script_data_escaped_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-open-state
	public static var script_data_escaped_end_tag_open_state = Mo.rules( [
		'[a-zA-Z]' => /*reconsume*/ lexer.token( script_data_escaped_end_tag_name_state ),
		'[^a-zA-Z]' => /*emit `<` and `/`*/ /*reconsume*/ lexer.token( script_data_escaped_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-name-state
	public static var script_data_escaped_end_tag_name_state = Mo.rules( [
		'[\t\n\u000C ]' => null,
		'/' => null,
		'>' => null,
		'[A-Z]' => null,
		'[a-z]' => null,
		'[^\t\n\u000C />A-Za-z]' => null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-start-state
	public static var script_data_double_escape_start_state = Mo.rules( [
		'[\t\n\u000C />]' => null,
		'[A-Z]' => null,
		'[a-z]' => null,
		'[^\t\n\u000C />A-Za-z]' => null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-state
	public static var script_data_double_escaped_state = Mo.rules( [
		'\\-' => null,
		'<' => null,
		// null character
		// EOF
		'[^\\-<]' => Const(CString(lexer.current)),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-state
	public static var script_data_double_escaped_dash_state = Mo.rules( [
		'\\-' => null,
		'<' => null,
		// null character
		// EOF
		'[^\\-<]' => null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-dash-state
	public static var script_data_double_escaped_dash_dash_state = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-less-than-sign-state
	public static var script_data_double_escaped_less_than_sign_state = Mo.rules( [
		'/' => {
			lexer.temporaryBuffer = '';
			lexer.emit('/');
			lexer.tokenize( script_data_double_escape_end_state );
		},
		'[^/]' => lexer.reconsume( script_data_double_escaped_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-end-state
	public static var script_data_double_escape_end_state = Mo.rules( [
		'[\t\n\u000C />]' => {
			lexer.emit(lexer.current);
			if (lexer.temporaryBuffer == 'script') {
				lexer.tokenize( script_data_escaped_state );

			} else {
				lexer.tokenize( script_data_double_escaped_state );

			}
		},
		'[A-Z]' => {
			lexer.temporaryBuffer += lexer.current.toLowerCase();
			Keyword(Character({data:lexer.currentInputCharacter}));
		},
		'[a-z]' => {
			lexer.temporaryBuffer += lexer.current;
			Keyword(Character({data:lexer.currentInputCharacter}));
		},
		'[^\t\n\u000C />A-Za-z]' => lexer.reconsume( script_data_double_escaped_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#before-attribute-name-state
	public static var before_attribute_name_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( before_attribute_name_state ),
		'[/>]' => lexer.reconsume( after_attribute_name_state ),
		'' => lexer.reconsume( after_attribute_name_state ),
		'=' => {
			/*error*/
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes.push( {name: lexer.currentInputCharacter, value: ''} );

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_name_state );
		},
		'[^\t\n\u000C />=]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes.push( {name:'', value:''} );

				case x:
					trace( x );
			}
			lexer.reconsume( attribute_name_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-name-state
	public static var attribute_name_state = Mo.rules( [
		'[\t\n\u000C />]' => lexer.reconsume( after_attribute_name_state ),
		'' => lexer.reconsume( after_attribute_name_state ),
		'=' => lexer.tokenize( before_attribute_value_state ),
		'[A-Z]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].name += lexer.currentInputCharacter.toLowerCase();
				
				case x:
					trace( x );
			}
			lexer.tokenize( attribute_name_state );
		},
		NULL => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].name += '\uFFFD';
				
				case x:
					trace( x );
			}
			lexer.tokenize( attribute_name_state );
		},
		'["\u0027<]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].name += lexer.currentInputCharacter.toLowerCase();
				
				case x:
					trace( x );
			}
			lexer.tokenize( attribute_name_state );
		},
		'[^\t\n\u000C />=A-Z$NULL"\u0027<]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].name += lexer.currentInputCharacter.toLowerCase();
				
				case x:
					trace( x );
			}
			lexer.tokenize( attribute_name_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-attribute-name-state
	public static var after_attribute_name_state = Mo.rules( [
		'[\t\n\u000C]' => lexer.tokenize( after_attribute_name_state ),
		'/' => lexer.tokenize( self_closing_start_tag_state ),
		'=' => lexer.tokenize( before_attribute_value_state ),
		'>' => {
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'' => /* error */ EOF,
		'[^\t\n\u000C /=>]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes.push( {name:'', value: ''} );

				case x:
					trace( x );
			}
			lexer.reconsume( attribute_name_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#before-attribute-value-state
	public static var before_attribute_value_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( before_attribute_value_state ),
		'"' => lexer.tokenize( attribute_value_double_quoted_state ),
		'\u0027' => lexer.tokenize( attribute_value_single_quoted_state ),
		'>' => {
			/* error */
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'[^\t\n\u000C "\u0027>]' => lexer.reconsume( attribute_value_unquoted_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(double-quoted)-state
	public static var attribute_value_double_quoted_state = Mo.rules( [
		'"' => lexer.tokenize( after_attribute_value_quoted_state ),
		'&' => lexer.consume( character_reference_state, attribute_value_double_quoted_state ),
		NULL => {
			/* error */
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_double_quoted_state );
		},
		'' => /* error */ EOF,
		'[^"&$NULL]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_double_quoted_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(single-quoted)-state
	public static var attribute_value_single_quoted_state = Mo.rules( [
		'\u0027' => lexer.tokenize( after_attribute_value_quoted_state ),
		'&' => lexer.consume( character_reference_state, attribute_value_single_quoted_state ),
		NULL => {
			/* error */
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_single_quoted_state );
		},
		'' => /* error */ EOF,
		'[^\u0027&$NULL]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_single_quoted_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(unquoted)-state
	public static var attribute_value_unquoted_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( before_attribute_name_state ),
		'&' => lexer.consume( character_reference_state, attribute_value_unquoted_state ),
		'>' => {
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		NULL => {
			/* error */
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_unquoted_state );
		},
		'["\u0027<=`]' => {
			/* error */
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_unquoted_state );
		},
		'' => EOF,
		'[^\t\n\u000C &$NULL"\u0027<=`]' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_unquoted_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-attribute-value-(quoted)-state
	public static var after_attribute_value_quoted_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( before_attribute_name_state ),
		'/' => lexer.tokenize( self_closing_start_tag_state ),
		'>' => {
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'' => EOF,
		'[^\t\n\u000C />]' => {
			/* error */
			lexer.reconsume( before_attribute_name_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#self-closing-start-tag-state
	public static var self_closing_start_tag_state = Mo.rules( [
		'>' => {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.selfClosing = true;
					lexer.emit( Keyword(lexer.currentToken) );

				case x:
					trace( x );
			}
			lexer.tokenize( data_state );
		},
		'' => EOF,
		'[^>]' => {
			/* error */
			lexer.reconsume( before_attribute_name_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#bogus-comment-state
	public static var bogus_comment_state = Mo.rules( [
		'>' => {
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'' => EOF,
		NULL => {
			/* error */
			switch lexer.currentToken {
				case Comment(data):
					data.data += '\uFFFD';
				
				case x:
					trace( x );
			}
			lexer.tokenize( bogus_comment_state );
		},
		'[^>$NULL]' => {
			switch lexer.currentToken {
				case Comment(data):
					data.data += lexer.currentInputCharacter;
				
				case x:
					trace( x );
			}
			lexer.tokenize( bogus_comment_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#markup-declaration-open-state
	public static var markup_declaration_open_state = Mo.rules( [
		'\u002D\u002D' => {
			lexer.currentToken = Comment({data:''});
			lexer.tokenize( comment_start_state );
		},
		'(d|D)(o|O)(c|C)(t|T)(y|Y)(p|P)(e|E)' => {
			lexer.tokenize( doctype_state );
		},
		'\u005B(c|C)(d|D)(a|A)(t|T)(a|A)\u005B' => {
			// TODO check against `adjusted current node`.
			lexer.currentToken = Comment({data:'[CDATA['});
			lexer.tokenize( bogus_comment_state );
		},
		'.' => {
			/* error */
			lexer.currentToken = Comment({data:''});
			lexer.tokenize( bogus_comment_state );
			// TODO check this note: > (don't consume anything in the current state).
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-start-state
	public static var comment_start_state = Mo.rules( [
		'\u002D' => lexer.tokenize( comment_start_dash_state ),
		'>' => {
			/* error */
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'[^->]' => lexer.reconsume( comment_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-start-dash-state
	public static var comment_start_dash_state = Mo.rules( [
		'\u002D' => lexer.tokenize( comment_end_state ),
		'>' => {
			/* error */
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'' => {
			lexer.emit( Keyword(lexer.currentToken) );
			EOF;
		},
		'[^->]' => {
			switch lexer.currentToken {
				case Comment(data):
					data.data += '-';
				
				case x:
					trace( x );
			}
			lexer.reconsume( comment_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-state
	public static var comment_state = Mo.rules( [
		'<' => {
			switch lexer.currentToken {
				case Comment(data):
					data.data += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( comment_less_than_sign_state );
		},
		'\u002D' => lexer.tokenize( comment_end_dash_state ),
		NULL => {
			/* error */
			switch lexer.currentToken {
				case Comment(data):
					data.data += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( comment_state );
		},
		'' => EOF,
		'[^<\u002D$NULL]' => {
			switch lexer.currentToken {
				case Comment(data):
					data.data += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( comment_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-state
	public static var comment_less_than_sign_state = Mo.rules( [
		'!' => {
			switch lexer.currentToken {
				case Comment(data):
					data.data += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( comment_less_than_sign_bang_state );
		},
		'<' => {
			switch lexer.currentToken {
				case Comment(data):
					data.data += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( comment_less_than_sign_bang_state );
		},
		'[^!<]' => lexer.reconsume( comment_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-state
	public static var comment_less_than_sign_bang_state = Mo.rules( [
		'\u002D' => lexer.tokenize( comment_less_than_sign_bang_dash_state ),
		'[^-]' => lexer.reconsume( comment_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-state
	public static var comment_less_than_sign_bang_dash_state = Mo.rules( [
		'\u002D' => lexer.tokenize( comment_less_than_sign_bang_dash_dash_state ),
		'[^-]' => lexer.reconsume( comment_end_dash_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-dash-state
	public static var comment_less_than_sign_bang_dash_dash_state = Mo.rules( [
		'>' => lexer.reconsume( comment_end_state ),
		'' => lexer.reconsume( comment_end_state ),
		'[^>]' => {
			/* error */
			lexer.reconsume( comment_end_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-end-dash-state
	public static var comment_end_dash_state = Mo.rules( [
		'\u002D' => lexer.tokenize( comment_end_state ),
		'' => {
			/* error */
			lexer.emit( Keyword(lexer.currentToken) );
			EOF;
		},
		'[^-]' => {
			switch lexer.currentToken {
				case Comment(data):
					data.data += '-';

				case x:
					trace( x );
			}
			lexer.reconsume( comment_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-end-state
	public static var comment_end_state = Mo.rules( [
		'>' => {
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'!' => lexer.tokenize( comment_end_bang_state ),
		'\u002D' => {
			switch lexer.currentToken {
				case Comment(data):
					data.data += '-';

				case x:
					trace( x );
			}
			lexer.tokenize( comment_end_state );
		},
		'' => {
			/* error */
			lexer.emit( Keyword(lexer.currentToken) );
			EOF;
		},
		'[^>!\u002D]' => {
			switch lexer.currentToken {
				case Comment(data):
					data.data += '--';

				case x:
					trace( x );
			}
			lexer.reconsume( comment_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-end-bang-state
	public static var comment_end_bang_state = Mo.rules( [
		'\u002D' => {
			switch lexer.currentToken {
				case Comment(data):
					data.data += '--!';

				case x:
					trace( x );
			}
			lexer.tokenize( comment_end_dash_state );
		},
		'>' => {
			/* error */
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			lexer.emit( Keyword(lexer.currentToken) );
			EOF;
		},
		'[^->]' => {
			switch lexer.currentToken {
				case Comment(data):
					data.data += '--!';

				case x:
					trace( x );
			}
			lexer.reconsume( comment_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-state
	public static var doctype_state = Mo.rules( [
		'[\t\n\uFFFD ]' => lexer.tokenize( before_doctype_name_state ),
		'>' => lexer.reconsume( before_doctype_name_state ),
		'' => {
			/* error */
			lexer.currentToken = DOCTYPE({forceQuirks:true});
			lexer.emit( Keyword(lexer.currentToken) );
			EOF;
		},
		'[^\t\n\uFFFD >]' => {
			/* error */
			lexer.reconsume( before_doctype_name_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-name-state
	public static var before_doctype_name_state = Mo.rules( [
		'[\t\n\uFFFD ]' => lexer.tokenize( before_doctype_name_state ),
		'[A-Z]' => {
			lexer.currentToken = DOCTYPE({name:lexer.currentInputCharacter.toLowerCase(), forceQuirks:false});
			lexer.tokenize( doctype_name_state );
		},
		NULL => {
			/* error */
			lexer.currentToken = DOCTYPE({name:'\uFFFD', forceQuirks:false});
			lexer.tokenize( doctype_name_state );
		},
		'>' => {
			/* error */
			lexer.currentToken = DOCTYPE({forceQuirks:true});
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			lexer.currentToken = DOCTYPE({forceQuirks:true});
			lexer.emit( Keyword(lexer.currentToken) );
			EOF;
		},
		'[^\t\n\uFFFD A-Z>]' => {
			lexer.currentToken = DOCTYPE({name:lexer.currentInputCharacter, forceQuirks:false});
			lexer.tokenize( doctype_name_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-name-state
	public static var doctype_name_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( after_doctype_name_state ),
		'>' => {
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'[A-Z]' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.name += lexer.currentInputCharacter.toLowerCase();

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_name_state );
		},
		NULL => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.name += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_name_state );
		},
		EOF => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( Keyword(lexer.currentToken) );
			EOF;
		},
		'[^\t\n\u000C >A-Z$NULL]' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.name += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_name_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-name-state
	public static var after_doctype_name_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( after_doctype_name_state ),
		'>' => {
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}

			lexer.emit( Keyword(lexer.currentToken) );
			EOF;
		},
		/** see Anything section **/
		'(p|P)(u|U)(b|B)(l|L)(i|I)(c|C)' => lexer.tokenize( after_doctype_public_keyword_state ),
		'(s|S)(y|Y)(s|S)(t|T)(e|E)(m|M)' => lexer.tokenize( after_doctype_system_keyword_state ),
		'[^\t\n\u000C >]' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.reconsume( bogus_doctype_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-public-keyword-state
	public static var after_doctype_public_keyword_state = Mo.rules( [
		'[\n\t\u000C ]' => lexer.tokenize( before_doctype_public_identifier_state ),
		'"' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_double_quoted_state );
		},
		'\u0027' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_single_quoted_state );
		},
		'>' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( Keyword(lexer.currentToken) );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( Keyword(lexer.currentToken) );
			EOF;
		},
		'[^\t\n\u000C "\u0022>]' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.reconsume( bogus_doctype_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-public-identifier-state
	public static var before_doctype_public_identifier_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( before_doctype_public_identifier_state ),
		'"' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_double_quoted_state );
		},
		'\u0027' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_single_quoted_state );
		},
		'>' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			EOF;
		},
		'[^\t\n\u000C "\u0027>]' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.reconsume( bogus_doctype_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-public-identifier-(double-quoted)-state
	public static var doctype_public_identifier_double_quoted_state = Mo.rules( [
		'"' => lexer.tokenize( after_doctype_public_identifier_state ),
		NULL => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_double_quoted_state );
		},
		'>' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			EOF;
		},
		'[^"$NULL>]' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_double_quoted_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-public-identifier-(single-quoted)-state
	public static var doctype_public_identifier_single_quoted_state = Mo.rules( [
		'\u0027' => lexer.tokenize( after_doctype_public_identifier_state ),
		NULL => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_single_quoted_state );
		},
		'>' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			EOF;
		},
		'[^\u0027$NULL>]' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_single_quoted_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-public-identifier-state
	public static var after_doctype_public_identifier_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( between_doctype_public_and_system_identifiers_state ),
		'>' => {
			lexer.emit( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'"' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'\u0027' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			EOF;
		},
		'[^\t\n\u000C >"\u0027]' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.reconsume( bogus_doctype_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#between-doctype-public-and-system-identifiers-state
	public static var between_doctype_public_and_system_identifiers_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( between_doctype_public_and_system_identifiers_state ),
		'>' => lexer.tokenize( data_state ),
		'"' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'\u0027' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			EOF;
		},
		'[^\t\n\u000C >"\u0027]' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.reconsume( bogus_doctype_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-system-keyword-state
	public static var after_doctype_system_keyword_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( before_doctype_system_identifier_state ),
		'"' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'\u0027' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'>' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			EOF;
		},
		'[^\t\n\u000C "\u0027>]' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.reconsume( bogus_doctype_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-system-identifier-state
	public static var before_doctype_system_identifier_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( before_doctype_system_identifier_state ),
		'"' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'\u0027' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'>' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			EOF;
		},
		'[^\t\n\u000C "\u0027>]' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.reconsume( bogus_doctype_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-system-identifier-(double-quoted)-state
	public static var doctype_system_identifier_double_quoted_state = Mo.rules( [
		'"' => lexer.tokenize( after_doctype_system_identifier_state ),
		NULL => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'>' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			EOF;
		},
		'[^"$NULL>]' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-system-identifier-(single-quoted)-state
	public static var doctype_system_identifier_single_quoted_state = Mo.rules( [
		'\u0027' => lexer.tokenize( after_doctype_system_identifier_state ),
		NULL => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'>' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			EOF;
		},
		'[^\u0027$NULL>]' => {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-system-identifier-state
	public static var after_doctype_system_identifier_state = Mo.rules( [
		'[\t\n\u000C ]' => lexer.tokenize( after_doctype_system_identifier_state ),
		'>' => {
			lexer.emit( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emit( lexer.currentToken );
			EOF;
		},
		'[^\t\n\u000C >]' => {
			/* error */
			lexer.reconsume( bogus_doctype_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#bogus-doctype-state
	public static var bogus_doctype_state = Mo.rules( [
		'>' => {
			lexer.emit( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		NULL => {
			/* error */
			lexer.tokenize( bogus_doctype_state );
		},
		'' => {
			lexer.emit( lexer.currentToken );
			EOF;
		},
		'[^>$NULL]' => lexer.tokenize( bogus_doctype_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-state
	public static var cdata_section_state = Mo.rules( [
		'\u005D' => lexer.tokenize( cdata_section_bracket_state ),
		'' => {
			/* error */
			EOF;
		},
		'[^\u005D]' => {
			lexer.emit( lexer.currentInputCharacter );
			lexer.tokenize( cdata_section_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-bracket-state
	public static var cdata_section_bracket_state = Mo.rules( [
		'\u005D' => lexer.tokenize( cdata_section_end_state ),
		'[^\u005D]' => {
			lexer.emit('\u005D');
			lexer.reconsume( cdata_section_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-end-state
	public static var cdata_section_end_state = Mo.rules( [
		'\u005D' => {
			lexer.emit('\u005D');
			lexer.tokenize( cdata_section_end_state );
		},
		'\u003E' => lexer.tokenize( data_state ),
		'[^\u005D\u003E]' => {
			lexer.emit('\u005D');
			lexer.emit('\u005D');
			lexer.reconsume( cdata_section_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#character-reference-state
	public static var character_reference_state = Mo.rules( [
		'[0-9a-zA-Z]' => {
			lexer.temporaryBuffer = '&';
			lexer.reconsume( named_character_reference_state );
		},
		'#' => {
			lexer.temporaryBuffer = '&';
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( numeric_character_reference_state );
		},
		'[^0-9a-zA-Z#]' => {
			// TODO flush code points.
			lexer.tokenize( lexer.returnState );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#named-character-reference-state
	public static var named_character_reference_state = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#ambiguous-ampersand-state
	public static var ambiguous_ampersand_state = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-state
	public static var numeric_character_reference_state = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-start-state
	public static var hexadecimal_character_reference_start_state = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-start-state
	public static var decimal_character_reference_start_state = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-state
	public static var hexadecimal_character_reference_state = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-state
	public static var decimal_character_reference_state = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-end-state
	public static var numeric_character_reference_end_state = Mo.rules( [] );
	
}

@:forward @:forwardStatics enum abstract Characters(String) to String {
	public var NULL = '\u0000';
}

typedef Doctype = {
	?name:Null<String>, 
	?publicId:Null<String>, 
	?systemId:Null<String>, 
	?forceQuirks:Bool,
}

typedef Tag = {
	name:String, selfClosing:Bool, attributes:Array<Attribute>,
}

typedef Data = {
	data:String,
}

/**
	@:see https://html.spec.whatwg.org/multipage/parsing.html#attribute-name-state
	---
	> When the user agent leaves the attribute name state 
	> (and before emitting the tag token, if appropriate), the 
	> complete attribute's name must be compared to the other 
	> attributes on the same token; if there is already an 
	> attribute on the token with the exact same name, then 
	> this is a duplicate-attribute parse error and the new 
	> attribute must be removed from the token.
	--- NOTE ---
	> If an attribute is so removed from a token, it, and 
	> the value that gets associated with it, if any, 
	> are never subsequently used by the parser, and are 
	> therefore effectively discarded. Removing the 
	> attribute in this way does not change its 
	> status as the "current attribute" for 
	> the purposes of the tokenizer, however.
**/
typedef Attribute = {
	name:String, value:String,
}

enum HtmlTokens {
	DOCTYPE(obj:Doctype);
	StartTag(obj:Tag);
	EndTag(obj:Tag);
	Comment(obj:Data);
	Character(obj:Data);
	// EOF - using the Tokens.EOF istead
}

class HtmlTokensUtil {

	public static inline function makeTag(name:String = '', selfClosing:Bool = false, ?attributes:Array<Attribute>):Tag {
		return { name: name, selfClosing: selfClosing, attributes: attributes == null ? [] : attributes };
	}

	public static function isAppropiateEndTag(lexer:NewLexer):Bool {
		if (lexer.lastToken != null) return switch [lexer.lastToken, lexer.currentToken] {
			case [StartTag({name:s}), EndTag({name:e})]: s == e;
			case _: false;
		}

		return false;
	}

}

@:callable abstract BacklogValue(Array<Token<HtmlTokens>>->Void) from Array<Token<HtmlTokens>>->Void to Array<Token<HtmlTokens>>->Void {

	@:from public static inline function fromToken(t:Token<HtmlTokens>):BacklogValue {
		return values -> values.push( t );
	}

	@:from public static inline function fromHtmlToken(h:HtmlTokens):BacklogValue {
		return values -> values.push( Keyword( h ) );
	}

	@:from public static inline function fromString(v:String):BacklogValue {
		return values -> values.push( Keyword( Character({data:v}) ) );
	}

	@:from public static inline function fromBytes(b:Bytes):BacklogValue {
		return values -> for (i in 0...b.length) values.push( Keyword( Character({data:b.getData().fastGet(i).fromCharCode()}) ) );
	}

}