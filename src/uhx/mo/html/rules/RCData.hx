package uhx.mo.html.rules;

import uhx.mo.Token;
import hxparse.Ruleset;
import uhx.mo.html.NewLexer;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;

using tink.CoreApi;
using uhx.mo.html.NewLexer;
using uhx.mo.html.internal.TokenUtil;

class RCData implements uhx.mo.RulesCache {

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-state
    public static var rcdata_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'&' => lexer -> {
			lexer.consume( Entity.character_reference_state, rcdata_state );
		},
		'<' => lexer -> {
			lexer.tokenize( rcdata_less_than_sign_state );
		},
		NUL => lexer -> {
			lexer.emitString( '\uFFFD' );
			null;
		},
		'' => lexer -> {
			lexer.emitToken( EOF );
			null;
		},
		'[^&<]' => lexer -> {
			lexer.emitString( lexer.currentInputCharacter );
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-less-than-sign-state
	public static var rcdata_less_than_sign_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'/' => lexer -> {
			lexer.temporaryBuffer = '';
			lexer.reconsume( rcdata_end_tag_open_state );
		},
		'[^/]' => lexer -> {
			lexer.emitString('<');
			lexer.reconsume( rcdata_state );
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-open-state
	public static var rcdata_end_tag_open_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[a-zA-Z]' => lexer -> {
			lexer.currentToken = EndTag( makeTag() );
			lexer.reconsume( rcdata_end_tag_name_state );
		},
		'[^a-zA-Z]' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.reconsume( rcdata_state );
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-name-state
	public static var rcdata_end_tag_name_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> {
			if (lexer.isAppropiateEndTag()) {
				lexer.tokenize( Rules.before_attribute_name_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.emitString( lexer.temporaryBuffer );
				lexer.reconsume( rcdata_state );

			}
		},
		'/' => lexer -> {
			if (lexer.isAppropiateEndTag()) {
				lexer.tokenize( Tag.self_closing_start_tag_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.emitString( lexer.temporaryBuffer );
				lexer.reconsume( rcdata_state );

			}
		},
		'>' => lexer -> {
			if (lexer.isAppropiateEndTag()) {
				lexer.emitToken( Keyword(lexer.currentToken) );
				lexer.tokenize( Rules.data_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.emitString( lexer.temporaryBuffer );
				lexer.reconsume( rcdata_state );

			}
		},
		'[A-Z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.current.toLowerCase();

				case x:
					trace(x);

			}
			lexer.temporaryBuffer += lexer.current;
			lexer.tokenize( rcdata_end_tag_name_state );
		},
		'[a-z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.current;

				case x:
					trace(x);

			}
			lexer.temporaryBuffer += lexer.current;
			lexer.tokenize( rcdata_end_tag_name_state );
		},
		'[^\t\n\u000C />A-Za-z]' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.emitString( lexer.temporaryBuffer );
			lexer.reconsume( rcdata_state );
		},
	] );

}