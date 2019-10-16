package uhx.mo.html.rules;

import uhx.mo.Token;
import hxparse.Ruleset;
import uhx.mo.html.NewLexer;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;

using tink.CoreApi;
using uhx.mo.html.NewLexer;
using uhx.mo.html.internal.TokenUtil;

class Script implements uhx.mo.RulesCache {

    // @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-state
	public static var script_data_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'<' => lexer -> lexer.tokenize( script_data_less_than_sign_state ),
		NUL => lexer -> lexer.emitString('\uFFFD' ),
		'' => lexer -> lexer.emitToken( EOF ),
		'[^&<]' => lexer -> lexer.emitString(lexer.currentInputCharacter ),
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-less-than-sign-state
	public static var script_data_less_than_sign_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'/' => lexer -> /*temp buffer*/ null,//lexer.token( script_data_end_tag_open_state ),
		'!' => lexer -> /*emit `<` and `!`*/ null,//lexer.token( script_data_escape_start_state ),
		'[^/!]+' => lexer -> /*emit `<`*/ /*reconsume*/ null,//lexer.token( script_data_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-open-state
	public static var script_data_end_tag_open_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[a-z]' => lexer -> /*reconsume*/ null,//lexer.token( script_data_end_tag_name_state ),
		'[^a-z]+' => lexer -> /*emit `<` and `/`*/ /*reconsume*/ null,//lexer.token( script_data_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-name-state
	public static var script_data_end_tag_name_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,//null,
		'/' => lexer -> null,//null,
		'>' => lexer -> null,//null,
		'[A-Z]' => lexer -> null,//null,
		'[a-z]' => lexer -> null,//null,
		'[^\t\n\u000C />A-Za-z]+' => lexer -> null,//null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escape-start-state
	public static var script_data_escape_start_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> /*emit `-`*/ null,//lexer.token( script_data_escape_start_dash_state ),
		'[^\\-]+' => lexer -> /*reconsume*/ null,//lexer.token( script_data_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escape-start-dash-state
	public static var script_data_escape_start_dash_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> lexer.token( script_data_escaped_dash_dash_state ), /*emit `-`*/
		'[^\\-]+' => lexer -> /*reconsume*/ null,//lexer.token( script_data_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-state
	public static var script_data_escaped_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> null,//null,
		'<' => lexer -> null,//null,
		// null character
		// EOF
		'[^\\-<]' => lexer -> lexer.emitString( lexer.current ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-state
	public static var script_data_escaped_dash_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> null,//null,
		'<' => lexer -> null,//null,
		// null character
		// EOF
		'[^\\-<]' => lexer -> null,//null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-dash-state
	public static var script_data_escaped_dash_dash_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> null,//null,
		'<' => lexer -> null,//null,
		'>' => lexer -> null,//null,
		// null character
		// EOF
		'[^\\-<>]' => lexer -> null,//null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-less-than-sign-state
	public static var script_data_escaped_less_than_sign_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'/' => lexer -> /*temp buff*/ null,//lexer.token( script_data_escaped_end_tag_open_state ),
		'[a-zA-Z]' => lexer -> /*temp buff*/ /*emit `<`*/ /*reconsume*/ null,//lexer.token( script_data_double_escape_start_state ),
		'[^/a-zA-Z]' => lexer -> /* `<`*/ /*reconsume*/ null,//lexer.token( script_data_escaped_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-open-state
	public static var script_data_escaped_end_tag_open_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[a-zA-Z]' => lexer -> /*reconsume*/ null,//lexer.token( script_data_escaped_end_tag_name_state ),
		'[^a-zA-Z]' => lexer -> /*emit `<` and `/`*/ /*reconsume*/ null,//lexer.token( script_data_escaped_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-name-state
	public static var script_data_escaped_end_tag_name_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> null,//null,
		'/' => lexer -> null,//null,
		'>' => lexer -> null,//null,
		'[A-Z]' => lexer -> null,//null,
		'[a-z]' => lexer -> null,//null,
		'[^\t\n\u000C />A-Za-z]' => lexer -> null,//null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-start-state
	public static var script_data_double_escape_start_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C />]' => lexer -> null,//null,
		'[A-Z]' => lexer -> null,//null,
		'[a-z]' => lexer -> null,//null,
		'[^\t\n\u000C />A-Za-z]' => lexer -> null,//null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-state
	public static var script_data_double_escaped_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> null,//null,
		'<' => lexer -> null,//null,
		// null character
		// EOF
		'[^\\-<]' => lexer -> lexer.emitString( lexer.current ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-state
	public static var script_data_double_escaped_dash_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> null,//null,
		'<' => lexer -> null,//null,
		// null character
		// EOF
		'[^\\-<]' => lexer -> null,//null,
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-dash-state
	public static var script_data_double_escaped_dash_dash_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-less-than-sign-state
	public static var script_data_double_escaped_less_than_sign_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'/' => lexer -> {
			lexer.temporaryBuffer = '';
			lexer.emitString('/');
			lexer.tokenize( script_data_double_escape_end_state );
		},
		'[^/]' => lexer -> lexer.reconsume( script_data_double_escaped_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-end-state
	public static var script_data_double_escape_end_state:Ruleset<NewLexer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C />]' => lexer -> {
			lexer.emitString(lexer.current);
			if (lexer.temporaryBuffer == 'script') {
				lexer.tokenize( script_data_escaped_state );

			} else {
				lexer.tokenize( script_data_double_escaped_state );

			}
		},
		'[A-Z]' => lexer -> {
			lexer.temporaryBuffer += lexer.current.toLowerCase();
			lexer.emitToken( Keyword(Character({data:lexer.currentInputCharacter})) );
		},
		'[a-z]' => lexer -> {
			lexer.temporaryBuffer += lexer.current;
			lexer.emitToken( Keyword(Character({data:lexer.currentInputCharacter})) );
		},
		'[^\t\n\u000C />A-Za-z]' => lexer -> lexer.reconsume( script_data_double_escaped_state ),
	] );

}