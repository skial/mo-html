package uhx.mo.html.rules;

import uhx.mo.Token;
import hxparse.Ruleset;
import uhx.mo.html.NewLexer;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;

using tink.CoreApi;
using uhx.mo.html.NewLexer;
using uhx.mo.html.internal.TokenUtil;

class CData implements uhx.mo.RulesCache {

    // @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-state
	public static var cdata_section_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u005D' => lexer -> lexer.tokenize( cdata_section_bracket_state ),
		'' => lexer -> {
			/* error */
			lexer.emitToken( EOF );
			null;
		},
		'[^\u005D]' => lexer -> {
			lexer.emitString( lexer.currentInputCharacter );
			lexer.tokenize( cdata_section_state );
		}
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-bracket-state
	public static var cdata_section_bracket_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u005D' => lexer -> lexer.tokenize( cdata_section_end_state ),
		'[^\u005D]' => lexer -> {
			lexer.emitString('\u005D');
			lexer.reconsume( cdata_section_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-end-state
	public static var cdata_section_end_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\u005D' => lexer -> {
			lexer.emitString('\u005D');
			lexer.tokenize( cdata_section_end_state );
		},
		'\u003E' => lexer -> lexer.tokenize( Entry.data_state ),
		'[^\u005D\u003E]' => lexer -> {
			lexer.emitString('\u005D');
			lexer.emitString('\u005D');
			lexer.reconsume( cdata_section_state );
		}
	] );

}