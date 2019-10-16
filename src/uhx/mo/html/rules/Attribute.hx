package uhx.mo.html.rules;

import uhx.mo.Token;
import hxparse.Ruleset;
import uhx.mo.html.NewLexer;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;

using tink.CoreApi;
using uhx.mo.html.NewLexer;
using uhx.mo.html.internal.TokenUtil;

class Attribute implements uhx.mo.RulesCache {

    // @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-name-state
	public static var attribute_name_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C />]' => lexer -> {
			lexer.reconsume( after_attribute_name_state );
		},
		'' => lexer -> {
			lexer.reconsume( after_attribute_name_state );
		},
		'=' => lexer -> {
			lexer.tokenize( before_attribute_value_state );
		},
		'[A-Z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].name += lexer.currentInputCharacter.toLowerCase();
				
				case x:
					trace( x );
			}
			lexer.tokenize( attribute_name_state );
		},
		NUL => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].name += '\uFFFD';
				
				case x:
					trace( x );
			}
			lexer.tokenize( attribute_name_state );
		},
		'["\u0027<]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].name += lexer.currentInputCharacter.toLowerCase();
				
				case x:
					trace( x );
			}
			lexer.tokenize( attribute_name_state );
		},
		'[^\t\n\u000C />=A-Z$NUL"\u0027<]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].name += lexer.currentInputCharacter.toLowerCase();
				
				case x:
					trace( x );
			}
			lexer.tokenize( attribute_name_state );
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(double-quoted)-state
	public static var attribute_value_double_quoted_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'"' => lexer -> {
			lexer.tokenize( after_attribute_value_quoted_state );
		},
		'&' => lexer -> {
			lexer.consume( Entity.character_reference_state, attribute_value_double_quoted_state );
		},
		NUL => lexer -> {
			/* error */
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_double_quoted_state );
		},
		'' => lexer -> {
			/* error */ 
			lexer.emitToken( EOF );
			null;
		},
		'[^"&$NUL]' => lexer -> {
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
	public static var attribute_value_single_quoted_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u0027' => lexer -> {
			lexer.tokenize( after_attribute_value_quoted_state );
		},
		'&' => lexer -> {
			lexer.consume( Entity.character_reference_state, attribute_value_single_quoted_state );
		},
		NUL => lexer -> {
			/* error */
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_single_quoted_state );
		},
		'' => lexer -> {
			/* error */ 
			lexer.emitToken( EOF );
			null;
		},
		'[^\u0027&$NUL]' => lexer -> {
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
	public static var attribute_value_unquoted_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> {
			lexer.tokenize( before_attribute_name_state );
		},
		'&' => lexer -> {
			lexer.consume( Entity.character_reference_state, attribute_value_unquoted_state );
		},
		'>' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Entry.data_state );
		},
		NUL => lexer -> {
			/* error */
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_unquoted_state );
		},
		'["\u0027<=`]' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_unquoted_state );
		},
		'' => lexer -> {
			lexer.emitToken( EOF );
			null;
		},
		'[^\t\n\u000C &$NUL"\u0027<=`]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_unquoted_state );
		}
	] );

	public static var before_attribute_name_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_attribute_name_state ),
		'[/>]' => lexer -> lexer.reconsume( after_attribute_name_state ),
		'' => lexer -> lexer.reconsume( after_attribute_name_state ),
		'=' => lexer -> {
			/*error*/
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes.push( {name: lexer.currentInputCharacter, value: ''} );

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_name_state );
		},
		'[^\t\n\u000C />=]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes.push( {name:'', value:''} );

				case x:
					trace( x );
			}
			lexer.reconsume( attribute_name_state );
		}
	] );

	public static var after_attribute_name_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C]' => lexer -> lexer.tokenize( after_attribute_name_state ),
		'/' => lexer -> lexer.tokenize( Tag.self_closing_start_tag_state ),
		'=' => lexer -> lexer.tokenize( before_attribute_value_state ),
		'>' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Entry.data_state );
		},
		'' => lexer -> /* error */ EOF,
		'[^\t\n\u000C /=>]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes.push( {name:'', value: ''} );

				case x:
					trace( x );
			}
			lexer.reconsume( attribute_name_state );
		}
	] );

	public static var before_attribute_value_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_attribute_value_state ),
		'"' => lexer -> lexer.tokenize( attribute_value_double_quoted_state ),
		'\u0027' => lexer -> lexer.tokenize( attribute_value_single_quoted_state ),
		'>' => lexer -> {
			/* error */
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Entry.data_state );
		},
		'[^\t\n\u000C "\u0027>]' => lexer -> lexer.reconsume( attribute_value_unquoted_state ),
	] );

	public static var after_attribute_value_quoted_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_attribute_name_state ),
		'/' => lexer -> lexer.tokenize( Tag.self_closing_start_tag_state ),
		'>' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Entry.data_state );
		},
		'' => lexer -> EOF,
		'[^\t\n\u000C />]' => lexer -> {
			/* error */
			lexer.reconsume( before_attribute_name_state );
		}
	] );

}