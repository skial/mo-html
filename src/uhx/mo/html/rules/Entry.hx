package uhx.mo.html.rules;

import uhx.mo.Token;
import hxparse.Ruleset;
import uhx.mo.html.NewLexer;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;

using tink.CoreApi;
using uhx.mo.html.NewLexer;
using uhx.mo.html.internal.TokenUtil;

class Entry implements uhx.mo.RulesCache {

    public static var data_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'&' => lexer -> lexer.consume( Entity.character_reference_state, data_state ),
		'<' => lexer -> lexer.tokenize( Tag.tag_open_state ),
		NUL => lexer -> {
			lexer.emitString(lexer.currentInputCharacter);
			null;
		},
		'' => lexer -> {
			lexer.emitToken( EOF );
			null;
		},
		'[^&<]' => lexer -> {
			lexer.emitString(lexer.currentInputCharacter);
			null;
		},
	] );

    public static var plaintext_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		NUL => lexer -> {
			lexer.emitString('\uFFFD');
			null;
		},
		'' => lexer -> {
			lexer.emitToken( EOF );
			null;
		},
		'[^&<]' => lexer -> {
			lexer.emitString(lexer.current);
			null;
		},
	] );

}