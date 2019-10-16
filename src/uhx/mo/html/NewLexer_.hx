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
import uhx.mo.html.internal.*;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;

using String;
using StringTools;
using haxe.io.Bytes;
using be.ds.util.DotGraph;
using uhx.mo.html.NewLexer;
using uhx.mo.html.internal.TokenUtil;

private typedef Tokens = Array<Token<Node>>;

@:forward
@:forwardStatics
enum abstract Characters(String) to String {
    public var NULL = NUL;
	public var NUL = '\u0000';
}

/**
 * ...
 * @author Skial Bainn
 */

class NewLexer extends hxparse.Lexer/* implements uhx.mo.RulesCache */{

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public var graph:NodeGraph = new NodeGraph();
	public var parent:Null<HtmlRef> = null;
	public var openTags:Array<HtmlRef> = [];
	
	public static var openClose:Ruleset<NewLexer, Token<Ref<Dynamic>>> = Mo.rules( [
	'<' => lexer -> lexer.token( tags ),
	'>' => lexer -> GreaterThan,
	'[^<>]+' => lexer -> {
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
	
	public static var tags:Ruleset<NewLexer, Token<Ref<Dynamic>>> = Mo.rules( [ 
	' +' => lexer -> Space(lexer.current.length),
	'\r' => lexer -> Carriage,
	'\n' => lexer -> Newline,
	'\t' => lexer -> Tab(1),
	'/>' => lexer -> lexer.token( openClose ),
	'[!?]' => lexer -> {
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
	'/[^\r\n\t <>]+>' => lexer -> {
		//Keyword( End( lexer.current.substring(1, lexer.current.length -1) ) );
        trace('end', lexer.current);
        Keyword( new Ref<String>( lexer.current.substring(1, lexer.current.length-1) ) );
	},
	'[a-zA-Z0-9:]+' => lexer -> {
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
	
	public static var attributes:Ruleset<NewLexer, Array<String>>= Mo.rules( [
	'[ \r\n\t]' => lexer -> lexer.token( attributes ),
	'[^\r\n\t /=>]+[\r\n\t ]*=[\r\n\t ]*' => lexer -> {
		var index = lexer.current.indexOf('=');
		var key = lexer.current.substring(0, index).rtrim();
		var value = try {
			lexer.token( attributesValue );
		} catch (e:Any) {
			'';
		}
		
		[key, value];
	},
	'[^\r\n\t /=>]+' => lexer -> [lexer.current, '']
	] );
	
	public static var attributesValue:Ruleset<NewLexer, String> = Mo.rules( [
	'"[^"]*"' => lexer -> lexer.current.substring(1, lexer.current.length-1),
	'\'[^\']*\'' => lexer -> lexer.current.substring(1, lexer.current.length-1),
	'[^ "\'><]+' => lexer -> lexer.current,
	] );
	
	public static var instructions:Ruleset<NewLexer, String> = Mo.rules( [
	'[a-zA-Z0-9]+' => lexer -> lexer.current,
	'[^a-zA-Z0-9 \r\n\t<>"\\[]+' => lexer -> lexer.current,
	'[a-zA-Z0-9#][^\r\n\t <>"\\[]+[^\\- \r\n\t<>"\\[]+' => lexer -> lexer.current,
	'[\r\n\t ]+' => lexer -> lexer.current,
	'\\[' => lexer -> {
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
	'<' => lexer -> {
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
	'"' => lexer -> {
		var value = '';
		
		try while (true) {
			var token = lexer.token( (Mo.rules([ '"' => lexer -> '"', '[^"]+' => lexer -> lexer.current ]):Ruleset<NewLexer, String>)  );
			
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
	
	public static var instructionText:Ruleset<NewLexer, String>= Mo.rules( [
	'[^\\]<>]+' => lexer -> lexer.current,
	'\\]' => lexer -> ']',
	'<' => lexer -> '<',
	'>' => lexer -> '>'
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
		return switch (tag:HtmlTag) {
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
		return switch (tag:HtmlTag) {
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
	public var returnState:Null<Ruleset<NewLexer, Token<HtmlTokens>>> = null;
	public var temporaryBuffer:Null<String> = null;
	public var currentInputCharacter:Null<String> = null;
	public var currentToken:Null<HtmlTokens> = null;
	public var lastToken:Null<HtmlTokens> = null;

	public var backlog:Array<Token<HtmlTokens>> = [];
	public var backpressure:Array<Ruleset<NewLexer, Token<HtmlTokens>>> = [];

	public inline function emitString(value:String):Void {
		backlog.push( Const(CString(value)) );
	}

    public inline function emitToken(value:Token<HtmlTokens>):Void {
        backlog.push( value );
    }

	public function tokenize(ruleset:Ruleset<NewLexer, Token<HtmlTokens>>):Token<HtmlTokens> {
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

	public static function consume<R:Ruleset<NewLexer, Token<HtmlTokens>>>(lexer:NewLexer, next:R, returnState:Null<R> = null, buffer:Null<BytesBuffer> = null) {
		lexer.returnState = returnState;
		return lexer.tokenize( next );
	}

    public static function reconsume<R:Ruleset<NewLexer, Token<HtmlTokens>>>(lexer:NewLexer, ruleset:R, characters:Int = 1) {
        lexer.pos -= characters;
		return lexer.tokenize( ruleset );
    }

}