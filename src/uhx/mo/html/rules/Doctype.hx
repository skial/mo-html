package uhx.mo.html.rules;

import uhx.mo.Token;
import hxparse.Ruleset;
import uhx.mo.html.NewLexer;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;

using tink.CoreApi;
using uhx.mo.html.NewLexer;
using uhx.mo.html.internal.TokenUtil;

class Doctype implements uhx.mo.RulesCache {

    // @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-state
	public static var doctype_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\uFFFD ]' => lexer -> lexer.tokenize( before_doctype_name_state ),
		'>' => lexer -> lexer.reconsume( before_doctype_name_state ),
		'' => lexer -> {
			/* error */
			lexer.currentToken = DOCTYPE({forceQuirks:true});
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\t\n\uFFFD >]' => lexer -> {
			/* error */
			lexer.reconsume( before_doctype_name_state );
		}
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-name-state
	public static var doctype_name_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( after_doctype_name_state ),
		'>' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'[A-Z]' => lexer -> {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.name += lexer.currentInputCharacter.toLowerCase();

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_name_state );
		},
		NUL => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.name += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_name_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\t\n\u000C >A-Z$NUL]' => lexer -> {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.name += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_name_state );
		}
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-public-identifier-(double-quoted)-state
	public static var doctype_public_identifier_double_quoted_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'"' => lexer -> lexer.tokenize( after_doctype_public_identifier_state ),
		NUL => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_double_quoted_state );
		},
		'>' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^"$NUL>]' => lexer -> {
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
	public static var doctype_public_identifier_single_quoted_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u0027' => lexer -> lexer.tokenize( after_doctype_public_identifier_state ),
		NUL => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_single_quoted_state );
		},
		'>' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\u0027$NUL>]' => lexer -> {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_single_quoted_state );
		}
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-system-identifier-(double-quoted)-state
	public static var doctype_system_identifier_double_quoted_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'"' => lexer -> lexer.tokenize( after_doctype_system_identifier_state ),
		NUL => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'>' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^"$NUL>]' => lexer -> {
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
	public static var doctype_system_identifier_single_quoted_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u0027' => lexer -> lexer.tokenize( after_doctype_system_identifier_state ),
		NUL => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'>' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\u0027$NUL>]' => lexer -> {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId += lexer.currentInputCharacter;

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		}
	] );

	public static var before_doctype_name_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\uFFFD ]' => lexer -> lexer.tokenize( before_doctype_name_state ),
		'[A-Z]' => lexer -> {
			lexer.currentToken = DOCTYPE({name:lexer.currentInputCharacter.toLowerCase(), forceQuirks:false});
			lexer.tokenize( doctype_name_state );
		},
		NUL => lexer -> {
			/* error */
			lexer.currentToken = DOCTYPE({name:'\uFFFD', forceQuirks:false});
			lexer.tokenize( doctype_name_state );
		},
		'>' => lexer -> {
			/* error */
			lexer.currentToken = DOCTYPE({forceQuirks:true});
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			/* error */
			lexer.currentToken = DOCTYPE({forceQuirks:true});
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\t\n\uFFFD A-Z>]' => lexer -> {
			lexer.currentToken = DOCTYPE({name:lexer.currentInputCharacter, forceQuirks:false});
			lexer.tokenize( doctype_name_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-name-state
	public static var after_doctype_name_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( after_doctype_name_state ),
		'>' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}

			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		/** see Anything section **/
		'(p|P)(u|U)(b|B)(l|L)(i|I)(c|C)' => lexer -> lexer.tokenize( after_doctype_public_keyword_state ),
		'(s|S)(y|Y)(s|S)(t|T)(e|E)(m|M)' => lexer -> lexer.tokenize( after_doctype_system_keyword_state ),
		'[^\t\n\u000C >]' => lexer -> {
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
	public static var after_doctype_public_keyword_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\n\t\u000C ]' => lexer -> lexer.tokenize( before_doctype_public_identifier_state ),
		'"' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_double_quoted_state );
		},
		'\u0027' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_single_quoted_state );
		},
		'>' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\t\n\u000C "\u0022>]' => lexer -> {
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
	public static var before_doctype_public_identifier_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_doctype_public_identifier_state ),
		'"' => lexer -> {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_double_quoted_state );
		},
		'\u0027' => lexer -> {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_public_identifier_single_quoted_state );
		},
		'>' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\t\n\u000C "\u0027>]' => lexer -> {
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

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-public-identifier-state
	public static var after_doctype_public_identifier_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( between_doctype_public_and_system_identifiers_state ),
		'>' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'"' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'\u0027' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\t\n\u000C >"\u0027]' => lexer -> {
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
	public static var between_doctype_public_and_system_identifiers_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( between_doctype_public_and_system_identifiers_state ),
		'>' => lexer -> lexer.tokenize( Rules.data_state ),
		'"' => lexer -> {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'\u0027' => lexer -> {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\t\n\u000C >"\u0027]' => lexer -> {
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
	public static var after_doctype_system_keyword_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_doctype_system_identifier_state ),
		'"' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'\u0027' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'>' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\t\n\u000C "\u0027>]' => lexer -> {
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
	public static var before_doctype_system_identifier_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_doctype_system_identifier_state ),
		'"' => lexer -> {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'\u0027' => lexer -> {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );
			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'>' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\t\n\u000C "\u0027>]' => lexer -> {
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

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-system-identifier-state
	public static var after_doctype_system_identifier_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( after_doctype_system_identifier_state ),
		'>' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			/* error */
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^\t\n\u000C >]' => lexer -> {
			/* error */
			lexer.reconsume( bogus_doctype_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#bogus-doctype-state
	public static var bogus_doctype_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'>' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.tokenize( Rules.data_state );
		},
		NUL => lexer -> {
			/* error */
			lexer.tokenize( bogus_doctype_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword(lexer.currentToken) );
			lexer.emitToken( EOF );
			null;
		},
		'[^>$NULL]' => lexer -> lexer.tokenize( bogus_doctype_state ),
	] );

}