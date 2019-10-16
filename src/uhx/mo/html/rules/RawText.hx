package uhx.mo.html.rules;

import uhx.mo.Token;
import hxparse.Ruleset;
import uhx.mo.html.NewLexer;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;

using tink.CoreApi;
using uhx.mo.html.NewLexer;
using uhx.mo.html.internal.TokenUtil;

class RawText implements uhx.mo.RulesCache {

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-state
	public static var rawtext_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'<' => lexer -> lexer.tokenize( rawtext_less_than_sign_state ),
		NUL => lexer -> lexer.emitString( '\uFFFD' ),
		'' => lexer -> lexer.emitToken( EOF ),
		'[^&<]' => lexer -> lexer.emitString( lexer.currentInputCharacter ),
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-less-than-sign-state
	public static var rawtext_less_than_sign_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'/' => lexer -> {
			lexer.temporaryBuffer = '';
			lexer.tokenize( rawtext_end_tag_open_state );
		},
		'[^/]' => lexer -> {
			lexer.emitString('<');
			lexer.reconsume( rawtext_state );
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-open-state
	public static var rawtext_end_tag_open_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[a-z]' => lexer -> {
			lexer.currentToken = EndTag( makeTag() );
			lexer.reconsume( rawtext_end_tag_name_state );
		},
		'[^a-z]' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.reconsume( rawtext_state );
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-name-state
	public static var rawtext_end_tag_name_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> {
			if (lexer.isAppropiateEndTag()) {
				lexer.tokenize( Rules.before_attribute_name_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.emitString( lexer.temporaryBuffer );
				lexer.reconsume( rawtext_state );

			}
		},
		'/' => lexer -> {
			if (lexer.isAppropiateEndTag()) {
				lexer.tokenize( Tag.self_closing_start_tag_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.emitString( lexer.temporaryBuffer );
				lexer.reconsume( rawtext_state );

			}
		},
		'>' => lexer -> {
			if (lexer.isAppropiateEndTag()) {
				lexer.emitToken( Keyword( lexer.currentToken ) );
				lexer.tokenize( Rules.data_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.emitString( lexer.temporaryBuffer );
				lexer.reconsume( rawtext_state );

			}
		},
		NUL => lexer -> {
			lexer.emitString('\uFFFD');
			lexer.tokenize( Script.script_data_double_escaped_state );
		},
		'' => lexer -> lexer.emitToken(EOF),
		'[^\t\n\u000C />]' => lexer -> {
			lexer.emitString(lexer.current);
			lexer.tokenize( Script.script_data_double_escaped_state );
		},
	] );

}