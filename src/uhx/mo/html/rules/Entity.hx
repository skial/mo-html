package uhx.mo.html.rules;

import uhx.mo.Token;
import hxparse.Ruleset;
import uhx.mo.html.NewLexer;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;

using tink.CoreApi;
using uhx.mo.html.NewLexer;
using uhx.mo.html.internal.TokenUtil;

class Entity implements uhx.mo.RulesCache {

    // @see https://html.spec.whatwg.org/multipage/parsing.html#character-reference-state
	public static var character_reference_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[0-9a-zA-Z]' => lexer -> {
			lexer.temporaryBuffer = '&';
			lexer.reconsume( named_character_reference_state );
		},
		'#' => lexer -> {
			lexer.temporaryBuffer = '&';
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( numeric_character_reference_state );
		},
		'[^0-9a-zA-Z#]' => lexer -> {
			// TODO flush code points.
			lexer.tokenize( lexer.returnState );
		}
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#named-character-reference-state
	public static var named_character_reference_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#ambiguous-ampersand-state
	public static var ambiguous_ampersand_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-state
	public static var numeric_character_reference_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-start-state
	public static var hexadecimal_character_reference_start_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-start-state
	public static var decimal_character_reference_start_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-state
	public static var hexadecimal_character_reference_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-state
	public static var decimal_character_reference_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-end-state
	public static var numeric_character_reference_end_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [] );

}