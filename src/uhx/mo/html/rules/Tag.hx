package uhx.mo.html.rules;

import uhx.mo.Token;
import hxparse.Ruleset;
import uhx.mo.html.NewLexer;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;

using tink.CoreApi;
using uhx.mo.html.NewLexer;
using uhx.mo.html.internal.TokenUtil;

class Tag implements uhx.mo.RulesCache {

    public static var tag_open_state:Ruleset<NewLexer, Token<HtmlTokens>>= Mo.rules( [
		'!' => lexer -> lexer.tokenize( Rules.markup_declaration_open_state ),
		'/' => lexer -> lexer.tokenize( end_tag_open_state ),
		'[a-zA-Z]' => lexer -> {
			lexer.currentToken = StartTag( makeTag() );
			lexer.reconsume( tag_name_state );
		},
		'?' => lexer -> {
			lexer.currentToken = Comment({data:''});
			lexer.reconsume( Rules.bogus_comment_state );
		},
		'' => lexer -> {
			lexer.emitToken( EOF );
			lexer.emitToken( Keyword( Character({data:'<'}) ) );
			null;
		},
		'[^!\\/a-zA-Z\\?]' => lexer -> {
			lexer.emitString('<');
			lexer.reconsume( Rules.data_state );
		},
	] );

    public static var end_tag_open_state:Ruleset<NewLexer, Token<HtmlTokens>>= Mo.rules( [
		'[a-zA-Z]' => lexer -> {
			lexer.currentToken = EndTag( makeTag() );
			lexer.reconsume( tag_name_state );
		},
		'>' => lexer -> lexer.tokenize( Rules.data_state ),
		'' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.emitToken(EOF);
			null;
		},
		'[^a-zA-Z>]' => lexer -> {
			lexer.currentToken = Comment( {data:''} );
			lexer.reconsume( Rules.bogus_comment_state );
		},
	] );

    public static var tag_name_state:Ruleset<NewLexer, Token<HtmlTokens>>= Mo.rules( [
		'[\t\n \u000C]' => lexer -> lexer.tokenize( Rules.before_attribute_name_state ),
		'/' => lexer -> lexer.tokenize( self_closing_start_tag_state ),
		'>' => lexer -> {
			lexer.backpressure.push( Rules.data_state );
			lexer.emitToken( Keyword(lexer.lastToken = lexer.currentToken) );
			null;
		},
		'[A-Z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.current.toLowerCase();

				case x:
					trace( x );
			}
			lexer.tokenize( tag_name_state );
		},
		NULL => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( tag_name_state );
		},
		'' => lexer -> {
			lexer.emitToken(EOF);
			null;
		},
		'[^\t\n \u000C/>A-Z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.current;

				case x:
					trace( x );
			}
			lexer.tokenize( tag_name_state );
		},
	] );

    public static var self_closing_start_tag_state:Ruleset<NewLexer, Token<HtmlTokens>>= Mo.rules( [
		'>' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.selfClosing = true;
					lexer.emitToken( Keyword(lexer.currentToken) );

				case x:
					trace( x );
			}
			lexer.tokenize( Rules.data_state );
		},
		'' => lexer -> {
			lexer.emitToken( EOF );
			null;
		},
		'[^>]' => lexer -> {
			/* error */
			lexer.reconsume( Rules.before_attribute_name_state );
		}
	] );

}