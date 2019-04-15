package uhx.mo.html;

import haxe.CallStack;
import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import haxe.EnumTools;
import hxparse.Ruleset;
import hxparse.Position;
import haxe.ds.StringMap;
import hxparse.UnexpectedChar;
//import be.ds.vertices.Vertex;
//import be.ds.graphs.directed.EdgeGraph;
import uhx.mo.html.HtmlGraph;
//import uhx.mo.html.HtmlGraph.HtmlVertex as Vertex;

using StringTools;
using uhx.mo.html.Lexer;
using be.ds.util.DotGraph;

private typedef Tokens = Array<Token<HtmlKeywords>>;

class Ref<Child> implements be.ds.vertices.IVertex<Child> {
	
	public var value:Child;
	public var tokens:Child;
	public var complete:Bool = true;
	public var id(default, null):Int = be.ds.util.Counter.next();
	//public var parent:GraphNode<HtmlKeywords>;
	
	public function new(tokens:Child/*, ?parent:GraphNode<HtmlKeywords>*/) {
		this.value = this.tokens = tokens;
		//this.parent = parent;
	}
	
	// @see https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode
	// `parent` should be null as the element isnt attached to any document.
	public function clone(deep:Bool) {
		return new Ref<Child>(tokens/*, null*/);
	}

	public inline function compare(other:be.ds.vertices.IVertex<Child>):Bool {
		return this.id == other.id;
	}

	
}

class InstructionRef extends Ref<Array<String>> {
	
	public var isComment(default, null):Bool;
	
	public function new(tokens:Array<String>, ?isComment:Bool = true/*, ?parent:GraphNode<HtmlKeywords>*/) {
		super(tokens/*, parent*/);
		this.isComment = isComment;
	}
	
	// @see https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode
	// `parent` should be null as the element isnt attached to any document.
	override public function clone(deep:Bool) {
		return new InstructionRef(deep ? tokens.copy() : tokens, isComment/*, null*/);
	}
	
}

class HtmlRef extends Ref<Tokens> {
	
	public var name:String;
	//public var complete:Bool = false;
	public var selfClosing:Bool = false;
	public var categories:Array<Category> = [];
	public var attributes:StringMap<String> = new StringMap();
	
	public function new(name:String, attributes:StringMap<String>, categories:Array<Category>, tokens:Tokens, /*?parent:GraphNode<HtmlKeywords>,*/ ?complete:Bool = false, ?selfClosing:Bool = false) {
		super(tokens/*, parent*/);
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
			deep ? [/*for (t in tokens) (t:dtx.mo.DOMNode).cloneNode( deep )*/] : [for (t in tokens) t], 
			//null, 
			complete,
			selfClosing
		);
	}
	
}

enum HtmlKeywords {
	End(name:String);
	Tag(ref:HtmlRef);
	Instruction(ref:InstructionRef);
	Text(ref:Ref<String>);
}

// @see http://www.w3.org/html/wg/drafts/html/master/dom.html#content-models
@:enum abstract Category(Int) from Int to Int {
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

@:enum abstract Model(Int) from Int to Int {
	public var Empty = 1;
	public var Text = 2;
	public var Element = 3;
}

@:enum abstract NodeType(Int) from Int to Int {
	public var Unknown = -1;
	public var Document = 0;
	public var Comment = 1;
	public var Text = 2;
	public var Element = 3;
}

@:enum abstract HtmlTag(String) from String to String {
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

class Lexer extends hxparse.Lexer {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public var graph:HtmlGraph<HtmlKeywords> = new HtmlGraph();
	//public var parent:Null<Vertex<HtmlKeywords>> = null;
	public var parent:Null<HtmlRef> = null;
	//public var _parent:Void->Token<HtmlKeywords> = null;
	public var openTags:Array<HtmlRef> = [];
	
	public static var openClose = Mo.rules( [
	'<' => lexer.token( tags ),
	'>' => GreaterThan,
	'[^<>]+' => {
		var ref = new Ref( lexer.current/*, lexer.parent*/ );
		var enm = HtmlKeywords.Text( ref );
		var node = new Vertex( enm );
		lexer.graph.addVertex( node );
		if (lexer.parent != null) lexer.graph.addEdge(lexer.parent, node);
		//Keyword( enm );
		Ignore;
	}
	] );
	
	public static var tags = Mo.rules( [ 
	' +' => Space(lexer.current.length),
	'\r' => Carriage,
	'\n' => Newline,
	'\t' => Tab(1),
	'/>' => lexer.token( openClose ),
	'[!?]' => {
		var tag = '';
		var attrs = [];
		var tokens = [];
		var aComment = lexer.current == '!';
		
		try while (true) {
			var token:String = lexer.token( instructions );
			attrs.push( token );
			
		} catch (e:Eof) { } catch (e:UnexpectedChar) {
			// This skips over the self closing characters `/>`
			// I cant see at the moment how to handle this better.
			try while (true) {
				var token = lexer.token( openClose );
				
				switch (token) {
					case GreaterThan:
						break;
						
					case _:
						break;
				}
				
				tokens.push( token );
			} catch (e:Any) { };
			
		} catch (e:Any) {
			trace( e );

		}
		
		if (!aComment && attrs[attrs.length -1] == '?') attrs = attrs.slice(0, attrs.length - 1);
		
		var ref = new InstructionRef( attrs, aComment/*, lexer.parent*/ );
		var enm = Instruction( ref );
		//var node = new Vertex( enm );
		var node = ref;
		lexer.graph.addVertex( node );
		if (lexer.parent != null) lexer.graph.addEdge(lexer.parent, node); 
		//Keyword( enm );
		Ignore;
	},
	'/[^\r\n\t <>]+>' => {
		Keyword( End( lexer.current.substring(1, lexer.current.length -1) ) );
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
				isVoid = true;
				
				// This skips over the self closing characters `/>`
				// I cant see at the moment how to handle this better.
				try while (true) {
					var token = lexer.token( openClose );
					
					switch (token) {
						case Keyword(HtmlKeywords.Text(e)) if (e.tokens.trim() == '/'):
							continue;
							
						/*case Keyword(HtmlKeywords.Text( { tokens:'/' } )), Space(_):
							continue;
						*/
						case GreaterThan, _:
							break;
					}
				} catch (e:Any) {
					trace( e );

				}
				
			} else if (e.char == '>') {
				untyped lexer.pos++;

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
		var enm = Tag(ref);
		var node = new Vertex( enm );
		lexer.graph.addVertex( node );
		
		if (!isVoid) {
			
			switch (categories) {
				case x if (x.indexOf( Category.Metadata ) != -1):
					position = buildMetadata( ref, lexer );
					
				case _:
					position = buildChildren( ref, node, lexer );
					
			}
			
			
		} else {
			ref.complete = true;
		}
		
		// If this node is the first, mark it as the document.
		if (first && ref.categories.indexOf( Category.Root ) == -1) ref.categories.push( Category.Root );
		ref.selfClosing = isVoid;
		
		//if (lexer.parent != null) lexer.graph.addSingleArc(lexer.parent, node);

		//Keyword( enm );
		Ignore;
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
			var token = lexer.token( instructionText );
			
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
			var token = lexer.token( instructionText );
			
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
			case Area, Br, DataList, Del, Link, Meta, Time, Wbr: [1, 4];
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
	private static function buildChildren(ref:HtmlRef, refNode:HtmlRef, lexer:Lexer):Int {
		var position = lexer.openTags.push( ref ) - 1;
		
		var previousParent = lexer.parent;
		lexer.parent = refNode;
		
		var tag = null;
		var index = -1;
		try while (true) {
			
			var token:Token<HtmlKeywords> = lexer.token( openClose );
			
			switch (token) {
				case GreaterThan:
					continue;
					
				case Keyword( End( t ) ):
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
					
				case _:
			}
			
			var node = switch token {
				case Keyword(enm): new Vertex( enm );
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
			trace( lexer.graph.asDotGraph( 'htmlgraph' ) );
			trace( e, CallStack.exceptionStack() );

		}
		
		lexer.parent = previousParent;
		
		return position;
	}
	
	private static function scriptedRule(tag:String) return Mo.rules( [
	'</[ ]*$tag[ ]*>' => {
		Keyword( End( lexer.current.substring(2, lexer.current.length - 1) ) );
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
	private static function buildMetadata(ref:HtmlRef, lexer:Lexer):Int {
		var position = lexer.openTags.push( ref ) - 1;
		var rule = scriptedRule( ref.name );
		
		try while (true) {
			var token = lexer.token( rule );
			
			switch (token) {
				case Keyword(End( x )) if (x == ref.name):
					// Set the reference as complete.
					ref.complete = true;
					// Combine all tokens into one token.
					var enm = HtmlKeywords.Text(new Ref( 
							[for (t in ref.tokens) switch(t) {
								case Const(CString(x)): x;
								case _: '';
							}].join('')
						//, new GraphNode( Tag(ref) )
						));
					var node = new Vertex( enm );
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
	
}