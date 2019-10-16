package uhx.mo.html.rules;

import uhx.mo.Token;
import hxparse.Ruleset;
import uhx.mo.html.NewLexer;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;

using tink.CoreApi;
using uhx.mo.html.NewLexer;
using uhx.mo.html.internal.TokenUtil;

class Comment implements uhx.mo.RulesCache {

    // @see https://html.spec.whatwg.org/multipage/parsing.html#comment-start-state
	public static var comment_start_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D' => lexer -> lexer.tokenize( comment_start_dash_state ),
		'>' => lexer -> {
			/* error */
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Entry.data_state );
		},
		'[^\\->]' => lexer -> lexer.reconsume( comment_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-start-dash-state
	public static var comment_start_dash_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D' => lexer -> lexer.tokenize( comment_end_state ),
		'>' => lexer -> {
			/* error */
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Entry.data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\\->]' => lexer -> {
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
	public static var comment_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'<' => lexer -> {
			switch lexer.currentToken {
				case Comment(data):
					data.data += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( comment_less_than_sign_state );
		},
		'\u002D' => lexer -> lexer.tokenize( comment_end_dash_state ),
		NUL => lexer -> {
			/* error */
			switch lexer.currentToken {
				case Comment(data):
					data.data += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( comment_state );
		},
		'' => lexer -> {
			lexer.emitToken( EOF );
			null;
		},
		//'[^<\u002D$NUL]' => lexer -> {
		'[^<\\-$NUL]' => lexer -> {
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
	public static var comment_less_than_sign_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'!' => lexer -> {
			switch lexer.currentToken {
				case Comment(data):
					data.data += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( comment_less_than_sign_bang_state );
		},
		'<' => lexer -> {
			switch lexer.currentToken {
				case Comment(data):
					data.data += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( comment_less_than_sign_bang_state );
		},
		'[^!<]' => lexer -> lexer.reconsume( comment_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-state
	public static var comment_less_than_sign_bang_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D' => lexer -> lexer.tokenize( comment_less_than_sign_bang_dash_state ),
		'[^\\-]' => lexer -> lexer.reconsume( comment_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-state
	public static var comment_less_than_sign_bang_dash_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D' => lexer -> lexer.tokenize( comment_less_than_sign_bang_dash_dash_state ),
		'[^\\-]' => lexer -> lexer.reconsume( comment_end_dash_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-dash-state
	public static var comment_less_than_sign_bang_dash_dash_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'>' => lexer -> lexer.reconsume( comment_end_state ),
		'' => lexer -> lexer.reconsume( comment_end_state ),
		'[^>]' => lexer -> {
			/* error */
			lexer.reconsume( comment_end_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-end-dash-state
	public static var comment_end_dash_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D' => lexer -> lexer.tokenize( comment_end_state ),
		'' => lexer -> {
			/* error */
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^-]' => lexer -> {
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
	public static var comment_end_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'>' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Entry.data_state );
		},
		'!' => lexer -> lexer.tokenize( comment_end_bang_state ),
		'\u002D' => lexer -> {
			switch lexer.currentToken {
				case Comment(data):
					data.data += '-';

				case x:
					trace( x );
			}
			lexer.tokenize( comment_end_state );
		},
		'' => lexer -> {
			/* error */
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		//'[^>!\u002D]' => lexer -> {
		'[^>!\\-]' => lexer -> {
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
	public static var comment_end_bang_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D' => lexer -> {
			switch lexer.currentToken {
				case Comment(data):
					data.data += '--!';

				case x:
					trace( x );
			}
			lexer.tokenize( comment_end_dash_state );
		},
		'>' => lexer -> {
			/* error */
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Entry.data_state );
		},
		'' => lexer -> {
			/* error */
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^->]' => lexer -> {
			switch lexer.currentToken {
				case Comment(data):
					data.data += '--!';

				case x:
					trace( x );
			}
			lexer.reconsume( comment_state );
		}
	] );

	public static var bogus_comment_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'>' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Entry.data_state );
		},
		'' => lexer -> {
			lexer.emitToken( EOF );
			null;
		},
		NULL => lexer -> {
			/* error */
			switch lexer.currentToken {
				case Comment(data):
					data.data += '\uFFFD';
				
				case x:
					trace( x );
			}
			lexer.tokenize( bogus_comment_state );
		},
		'[^>$NULL]' => lexer -> {
			switch lexer.currentToken {
				case Comment(data):
					data.data += lexer.currentInputCharacter;
				
				case x:
					trace( x );
			}
			lexer.tokenize( bogus_comment_state );
		}
	] );

	public static var markup_declaration_open_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D\u002D' => lexer -> {
			lexer.currentToken = Comment({data:''});
			lexer.tokenize( comment_start_state );
		},
		'(d|D)(o|O)(c|C)(t|T)(y|Y)(p|P)(e|E)' => lexer -> {
			lexer.tokenize( Doctype.doctype_state );
		},
		//'\u005B(c|C)(d|D)(a|A)(t|T)(a|A)\u005B' => lexer -> {
		'\\[(c|C)(d|D)(a|A)(t|T)(a|A)\\[' => lexer -> {
			// TODO check against `adjusted current node`.
			lexer.currentToken = Comment({data:'[CDATA['});
			lexer.tokenize( bogus_comment_state );
		},
		'.' => lexer -> {
			/* error */
			lexer.currentToken = Comment({data:''});
			lexer.tokenize( bogus_comment_state );
			// TODO check this note: > (don't consume anything in the current state).
		}
	] );

}