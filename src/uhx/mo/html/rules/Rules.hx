package uhx.mo.html.rules;

import uhx.mo.Token;
import hxparse.Ruleset;
import uhx.mo.html.Tokenizer;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.internal.TokenUtil.*;
import uhx.mo.html.parsing.ParseErrors.*;

using tink.CoreApi;
using uhx.mo.html.Tokenizer;
using uhx.mo.html.internal.TokenUtil;

class Rules implements uhx.mo.RulesCache {

	// @see https://html.spec.whatwg.org/multipage/parsing.html#data-state
    public static var data_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'&' => lexer -> {
			lexer.returnState = data_state;
			lexer.tokenize( character_reference_state );
		},
		'<' => lexer -> lexer.tokenize( tag_open_state ),
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			Keyword(Character({data:lexer.currentInputCharacter}));
		},
		'' => lexer -> {
			EOF;
		},
		'.' => lexer -> {
			Keyword(Character({data:lexer.currentInputCharacter}));
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#plaintext-state
    public static var plaintext_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			Keyword(Character({data:'\uFFFD'}));
		},
		'' => lexer -> {
			EOF;
		},
		'.' => lexer -> {
			Keyword(Character({data:lexer.current}));
		},
	] );

	// RCData rules

	// @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-state
    public static var rcdata_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'&' => lexer -> {
			lexer.returnState = rcdata_state;
			lexer.tokenize( character_reference_state );
		},
		'<' => lexer -> {
			lexer.tokenize( rcdata_less_than_sign_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			Keyword(Character({data:'\uFFFD'}));
		},
		'' => lexer -> {
			EOF;
		},
		'.' => lexer -> {
			Keyword(Character({data:lexer.currentInputCharacter}));
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-less-than-sign-state
	public static var rcdata_less_than_sign_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'/' => lexer -> {
			lexer.temporaryBuffer = '';
			lexer.tokenize( rcdata_end_tag_open_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.reconsume( rcdata_state );
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-open-state
	public static var rcdata_end_tag_open_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[a-zA-Z]' => lexer -> {
			lexer.currentToken = EndTag( makeTag() );
			lexer.reconsume( rcdata_end_tag_name_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.reconsume( rcdata_state );
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-name-state
	public static var rcdata_end_tag_name_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.tokenize( before_attribute_name_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.flushAsCharacterReference();
				lexer.reconsume( rcdata_state );

			}
		},
		'/' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.tokenize( self_closing_start_tag_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.flushAsCharacterReference();
				lexer.reconsume( rcdata_state );

			}
		},
		'>' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.emitHtmlToken( lexer.currentToken );
				lexer.tokenize( data_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.flushAsCharacterReference();
				lexer.reconsume( rcdata_state );

			}
		},
		'[A-Z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.currentInputCharacter.toLowerCase();

				case x:
					trace(x);

			}
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( rcdata_end_tag_name_state );
		},
		'[a-z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.currentInputCharacter;

				case x:
					trace(x);

			}
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( rcdata_end_tag_name_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.flushAsCharacterReference();
			lexer.reconsume( rcdata_state );
		},
	] );

	// RAWTEXT rules

	// @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-state
	public static var rawtext_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'<' => lexer -> lexer.tokenize( rawtext_less_than_sign_state ),
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			Keyword(Character({data:'\uFFFD'}));
		},
		'' => lexer -> {
			EOF;
		},
		'.' => lexer -> {
			Keyword(Character({data:lexer.currentInputCharacter}));
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-less-than-sign-state
	public static var rawtext_less_than_sign_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'/' => lexer -> {
			lexer.temporaryBuffer = '';
			lexer.tokenize( rawtext_end_tag_open_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.reconsume( rawtext_state );
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-open-state
	public static var rawtext_end_tag_open_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[a-z]' => lexer -> {
			lexer.currentToken = EndTag( makeTag() );
			lexer.reconsume( rawtext_end_tag_name_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.reconsume( rawtext_state );
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-name-state
	public static var rawtext_end_tag_name_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.tokenize( before_attribute_name_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.flushAsCharacterReference();
				lexer.reconsume( rawtext_state );

			}
		},
		'/' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.tokenize( self_closing_start_tag_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.flushAsCharacterReference();
				lexer.reconsume( rawtext_state );

			}
		},
		'>' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.emitToken( Keyword( lexer.currentToken ) );
				lexer.tokenize( data_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.flushAsCharacterReference();
				lexer.reconsume( rawtext_state );

			}
		},
		'[A-Z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.currentInputCharacter.toLowerCase();

				case x:
					trace(x);

			}
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( rawtext_end_tag_name_state );
		},
		'[a-z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.currentInputCharacter;

				case x:
					trace(x);

			}
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( rawtext_end_tag_name_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.flushAsCharacterReference();
			lexer.reconsume( rawtext_state );
		}
	] );

    // Entity rules

    // @see https://html.spec.whatwg.org/multipage/parsing.html#character-reference-state
	// Set the temporary buffer to the empty string. Append a U+0026 AMPERSAND (&) character to the temporary buffer. Consume the next input character:
	public static var character_reference_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[0-9a-zA-Z]' => lexer -> {
			lexer.temporaryBuffer = '&';
			lexer.reconsume( named_character_reference_state );
		},
		'#' => lexer -> {
			lexer.temporaryBuffer = '&';
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( numeric_character_reference_state );
		},
		'.' => lexer -> {
			lexer.temporaryBuffer = '&';
			lexer.flushAsCharacterReference();
			lexer.reconsume( lexer.returnState );
		}
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#named-character-reference-state
	public static var named_character_reference_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[a-zA-Z0-9]+(;|=|[a-zA-Z0-9])?' => lexer -> {
			lexer.temporaryBuffer += lexer.current;

			if (uhx.sys.HtmlEntity.has(lexer.temporaryBuffer)) {
				var partOfAttribute = lexer.isPartOfAttribute();

				if (partOfAttribute && !StringTools.endsWith(lexer.current, ';') && ~/=|[a-zA-Z0-9]/g.match(lexer.current.charAt(lexer.current.length - 1))) {
					@:privateAccess lexer.pos--;
					lexer.flushAsCharacterReference();
					lexer.tokenize( lexer.returnState );
					
				} else {
					if (!StringTools.endsWith(lexer.current, ';')) {
						lexer.emitToken( Keyword( ParseError( MissingSemicolonAfterCharacterReference(lexer.curPos()) ) ) );

					} 
					var value = lexer.temporaryBuffer;
					lexer.temporaryBuffer = '';
					lexer.temporaryBuffer += be.Heed.decode(
						value, partOfAttribute // TODO check to see if heed needs to handle attributes
					);
					lexer.flushAsCharacterReference();
					lexer.tokenize( lexer.returnState );

				}
				
			} else {
				lexer.flushAsCharacterReference();
				lexer.tokenize( ambiguous_ampersand_state );

			}
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#ambiguous-ampersand-state
	public static var ambiguous_ampersand_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[a-zA-Z0-9]' => lexer -> {
			if (lexer.isPartOfAttribute()) {
				switch lexer.currentToken {
					case StartTag(data) | EndTag(data):
						data.attributes[data.attributes.length - 1].value += lexer.currentInputCharacter;

					case x:
						trace( x );

				}
				lexer.tokenize( ambiguous_ampersand_state );

			} else {
				Keyword(Character({data:lexer.currentInputCharacter}));

			}
		},
		';' => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnknownNamedCharacterReference(lexer.curPos()) ) ) );
			lexer.reconsume( lexer.returnState );
		},
		'.' => lexer -> {
			lexer.reconsume( lexer.returnState );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-state
	public static var numeric_character_reference_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u0078|\u0058' => lexer -> {
			lexer.characterReferenceCode = 0;
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( hexadecimal_character_reference_start_state );
		},
		'.' => lexer -> {
			lexer.characterReferenceCode = 0;
			lexer.reconsume( decimal_character_reference_start_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-start-state
	public static var hexadecimal_character_reference_start_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[A-Z]|[a-z]' => lexer -> {
			lexer.reconsume( hexadecimal_character_reference_state );
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( AbsenceOfDigitsInNumericCharacterReference(lexer.curPos()) ) ) );
			lexer.flushAsCharacterReference();
			lexer.reconsume( lexer.returnState );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-start-state
	public static var decimal_character_reference_start_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[0-9]' => lexer -> {
			lexer.reconsume( decimal_character_reference_state );
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( AbsenceOfDigitsInNumericCharacterReference(lexer.curPos()) ) ) );
			lexer.flushAsCharacterReference();
			lexer.reconsume( lexer.returnState );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-state
	public static var hexadecimal_character_reference_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[0-9]' => lexer -> {
			var charCode = lexer.current.charCodeAt(0);
			lexer.characterReferenceCode *= 16;
			lexer.characterReferenceCode += (charCode - 0x0030);
			lexer.tokenize( hexadecimal_character_reference_state );
		},
		'[A-F]' => lexer -> {
			var charCode = lexer.current.charCodeAt(0);
			lexer.characterReferenceCode *= 16;
			lexer.characterReferenceCode += (charCode - 0x0037);
			lexer.tokenize( hexadecimal_character_reference_state );
		},
		'[a-f]' => lexer -> {
			var charCode = lexer.current.charCodeAt(0);
			lexer.characterReferenceCode *= 16;
			lexer.characterReferenceCode += (charCode - 0x0057);
			lexer.tokenize( hexadecimal_character_reference_state );
		},
		';' => lexer -> {
			lexer.tokenize( numeric_character_reference_end_state );
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingSemicolonAfterCharacterReference(lexer.curPos()) ) ) );
			lexer.reconsume( numeric_character_reference_end_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-state
	public static var decimal_character_reference_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'0-9' => lexer -> {
			var charCode = lexer.current.charCodeAt(0);
			lexer.characterReferenceCode *= 10;
			lexer.characterReferenceCode += (charCode - 0x0030);
			lexer.tokenize( decimal_character_reference_state );
		},
		';' => lexer -> {
			lexer.tokenize( numeric_character_reference_end_state );
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingSemicolonAfterCharacterReference(lexer.curPos()) ) ) );
			lexer.reconsume( numeric_character_reference_end_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-end-state
	public static var numeric_character_reference_end_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'.' => lexer -> {
			switch lexer.characterReferenceCode {
				case 0x00:
					lexer.emitToken( Keyword( ParseError( NullCharacterReference(lexer.curPos()) ) ) );
					lexer.characterReferenceCode = 0xFFFD;

				case x if (x > 0x10FFFF):
					lexer.emitToken( Keyword( ParseError( CharacterReferenceOutsideUnicodeRange(lexer.curPos()) ) ) );
					lexer.characterReferenceCode = 0xFFFD;

				// is a surrogate
				case x if (unifill.Unicode.isHighSurrogate(x) && unifill.Unicode.isLowSurrogate(x)):
					lexer.emitToken( Keyword( ParseError( SurrogateCharacterReference(lexer.curPos()) ) ) );
					lexer.characterReferenceCode = 0xFFFD;

				// is a noncharacter
				//case x if (Tokenizer.nonCharacterRange.has(x)):
				case x if (be.Heed.invalidReferenceCodePoints.indexOf(x) > -1):
					lexer.emitToken( Keyword( ParseError( NoncharacterCharacterReference(lexer.curPos()) ) ) );

				// control character
				//case x if (Tokenizer.controlCodeRange.has(x)):
				case x if (be.Heed.decodeMapNumericKeys.indexOf(x) > -1):
					lexer.emitToken( Keyword( ParseError( ControlCharacterReference(lexer.curPos()) ) ) );

				case _:

			}
			lexer.temporaryBuffer = 
			be.Heed.codePointToSymbol( lexer.characterReferenceCode );
			lexer.flushAsCharacterReference();
			lexer.tokenize( lexer.returnState );
		}
	] );

    // Tag rules

	// @see https://html.spec.whatwg.org/multipage/parsing.html#tag-open-state
    public static var tag_open_state:Ruleset<Tokenizer, Token<HtmlTokens>>= Mo.rules( [
		'!' => lexer -> lexer.tokenize( markup_declaration_open_state ),
		'/' => lexer -> lexer.tokenize( end_tag_open_state ),
		'[a-zA-Z]' => lexer -> {
			lexer.currentToken = StartTag( makeTag() );
			lexer.reconsume( tag_name_state );
		},
		'?' => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedQuestionMarkInsteadOfTagName(lexer.curPos()) ) ) );
			lexer.currentToken = Comment({data:''});
			lexer.reconsume( bogus_comment_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofBeforeTagName(lexer.curPos()) ) ) );
			lexer.emitToken( Keyword( Character({data:'<'}) ) );
			lexer.emitToken( EOF );
			lexer.backlog.shift();
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( InvalidFirstCharacterOfTagName(lexer.curPos()) ) ) );
			lexer.emitString('<');
			lexer.reconsume( data_state );
		},
	] );

	// https://html.spec.whatwg.org/multipage/parsing.html#end-tag-open-state
    public static var end_tag_open_state:Ruleset<Tokenizer, Token<HtmlTokens>>= Mo.rules( [
		'[a-zA-Z]' => lexer -> {
			lexer.currentToken = EndTag( makeTag() );
			lexer.reconsume( tag_name_state );
		},
		'>' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingEndTagName(lexer.curPos()) ) ) );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofBeforeTagName(lexer.curPos()) ) ) );
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.emitToken(EOF);
			lexer.backlog.shift();
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( InvalidFirstCharacterOfTagName(lexer.curPos()) ) ) );
			lexer.currentToken = Comment( {data:''} );
			lexer.reconsume( bogus_comment_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#tag-name-state
    public static var tag_name_state:Ruleset<Tokenizer, Token<HtmlTokens>>= Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_attribute_name_state ),
		'/' => lexer -> lexer.tokenize( self_closing_start_tag_state ),
		'>' => lexer -> {
			lexer.backpressure.push( data_state );
			Keyword(lexer.lastToken = lexer.currentToken);
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
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( tag_name_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInTag(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.current;

				case x:
					trace( x );
			}
			lexer.tokenize( tag_name_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#self-closing-start-tag-state
    public static var self_closing_start_tag_state:Ruleset<Tokenizer, Token<HtmlTokens>>= Mo.rules( [
		'>' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.selfClosing = true;
					lexer.emitHtmlToken( lexer.currentToken );

				case x:
					trace( x );

			}
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInTag(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedSolidusInTag(lexer.curPos()) ) ) );
			lexer.reconsume( before_attribute_name_state );
		}
	] );

    // Comment rules

    // @see https://html.spec.whatwg.org/multipage/parsing.html#comment-start-state
	public static var comment_start_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D' => lexer -> lexer.tokenize( comment_start_dash_state ),
		'>' => lexer -> {
			lexer.emitToken( Keyword( ParseError( AbruptClosingOfEmptyComment(lexer.curPos()) ) ) );
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'.' => lexer -> lexer.reconsume( comment_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-start-dash-state
	public static var comment_start_dash_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D' => lexer -> lexer.tokenize( comment_end_state ),
		'>' => lexer -> {
			lexer.emitToken( Keyword( ParseError( AbruptClosingOfEmptyComment(lexer.curPos()) ) ) );
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInComment(lexer.curPos()) ) ) );
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
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
	public static var comment_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
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
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case Comment(data):
					data.data += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( comment_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInComment(lexer.curPos()) ) ) );
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
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
	public static var comment_less_than_sign_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
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
		'.' => lexer -> lexer.reconsume( comment_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-state
	public static var comment_less_than_sign_bang_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D' => lexer -> lexer.tokenize( comment_less_than_sign_bang_dash_state ),
		'.' => lexer -> lexer.reconsume( comment_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-state
	public static var comment_less_than_sign_bang_dash_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D' => lexer -> lexer.tokenize( comment_less_than_sign_bang_dash_dash_state ),
		'.' => lexer -> lexer.reconsume( comment_end_dash_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-dash-state
	public static var comment_less_than_sign_bang_dash_dash_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'>' => lexer -> lexer.reconsume( comment_end_state ),
		'' => lexer -> lexer.reconsume( comment_end_state ),
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( NestedComment(lexer.curPos()) ) ) );
			lexer.reconsume( comment_end_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#comment-end-dash-state
	public static var comment_end_dash_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D' => lexer -> lexer.tokenize( comment_end_state ),
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInComment(lexer.curPos()) ) ) );
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
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
	public static var comment_end_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'>' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
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
			lexer.emitToken( Keyword( ParseError( EofInComment(lexer.curPos()) ) ) );
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
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
	public static var comment_end_bang_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
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
			lexer.emitToken( Keyword( ParseError( IncorrectlyClosedComment(lexer.curPos()) ) ) );
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInComment(lexer.curPos()) ) ) );
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
			switch lexer.currentToken {
				case Comment(data):
					data.data += '--!';

				case x:
					trace( x );

			}
			lexer.reconsume( comment_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#bogus-comment-state
	public static var bogus_comment_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'>' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		NULL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case Comment(data):
					data.data += '\uFFFD';
				
				case x:
					trace( x );

			}
			lexer.tokenize( bogus_comment_state );
		},
		'.' => lexer -> {
			switch lexer.currentToken {
				case Comment(data):
					data.data += lexer.currentInputCharacter;
				
				case x:
					trace( x );

			}
			lexer.tokenize( bogus_comment_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#markup-declaration-open-state
	public static var markup_declaration_open_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u002D\u002D' => lexer -> {
			lexer.currentToken = Comment({data:''});
			lexer.tokenize( comment_start_state );
		},
		'(d|D)(o|O)(c|C)(t|T)(y|Y)(p|P)(e|E)' => lexer -> {
			lexer.tokenize( doctype_state );
		},
		'\\[CDATA\\[' => lexer -> {
			// TODO check against `adjusted current node`.
			// lexer.tokenize( cdata_section_state );
			lexer.currentToken = Comment({data:'[CDATA['});
			lexer.tokenize( bogus_comment_state );
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( IncorrectlyOpenedComment(lexer.curPos()) ) ) );
			lexer.currentToken = Comment({data:''});
			@:privateAccess lexer.pos--;
			lexer.tokenize( bogus_comment_state );
			// TODO check this note: > (don't consume anything in the current state).
		}
	] );

    // Attribute rules

	// @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-name-state
    public static var attribute_name_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
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
					data.attributes[data.attributes.length - 1].name 
					+= lexer.currentInputCharacter.toLowerCase();
				
				case x:
					trace( x );

			}
			lexer.tokenize( attribute_name_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].name += '\uFFFD';
				
				case x:
					trace( x );

			}
			lexer.tokenize( attribute_name_state );
		},
		'["\u0027<]' => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedCharacterInAttributeName(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].name 
					+= lexer.currentInputCharacter;
				
				case x:
					trace( x );

			}
			lexer.tokenize( attribute_name_state );
		},
		'.' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].name 
					+= lexer.currentInputCharacter;
				
				case x:
					trace( x );

			}
			lexer.tokenize( attribute_name_state );
		},
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(double-quoted)-state
	public static var attribute_value_double_quoted_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'"' => lexer -> {
			lexer.tokenize( after_attribute_value_quoted_state );
		},
		'&' => lexer -> {
			lexer.returnState = attribute_value_double_quoted_state;
			lexer.tokenize( character_reference_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += '\uFFFD';

				case x:
					trace( x );

			}
			lexer.tokenize( attribute_value_double_quoted_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInTag(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value 
					+= lexer.currentInputCharacter;

				case x:
					trace( x );

			}
			lexer.tokenize( attribute_value_double_quoted_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(single-quoted)-state
	public static var attribute_value_single_quoted_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u0027' => lexer -> {
			lexer.tokenize( after_attribute_value_quoted_state );
		},
		'&' => lexer -> {
			lexer.returnState = attribute_value_single_quoted_state;
			lexer.tokenize( character_reference_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += '\uFFFD';

				case x:
					trace( x );
			}
			lexer.tokenize( attribute_value_single_quoted_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInTag(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value 
					+= lexer.currentInputCharacter;

				case x:
					trace( x );

			}
			lexer.tokenize( attribute_value_single_quoted_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(unquoted)-state
	public static var attribute_value_unquoted_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> {
			lexer.tokenize( before_attribute_name_state );
		},
		'&' => lexer -> {
			lexer.returnState = attribute_value_unquoted_state;
			lexer.tokenize( character_reference_state );
		},
		'>' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value += '\uFFFD';

				case x:
					trace( x );

			}
			lexer.tokenize( attribute_value_unquoted_state );
		},
		'["\u0027<=`]' => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedCharacterInUnquotedAttributeValue(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value 
					+= lexer.currentInputCharacter;

				case x:
					trace( x );

			}
			lexer.tokenize( attribute_value_unquoted_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInTag(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes[data.attributes.length - 1].value 
					+= lexer.currentInputCharacter;

				case x:
					trace( x );

			}
			lexer.tokenize( attribute_value_unquoted_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#before-attribute-name-state
	public static var before_attribute_name_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_attribute_name_state ),
		'[/>]' => lexer -> lexer.reconsume( after_attribute_name_state ),
		'' => lexer -> lexer.reconsume( after_attribute_name_state ),
		'=' => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedEqualsSignBeforeAttributeName(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes.push( {
						name: lexer.currentInputCharacter, 
						value: ''
					} );

				case x:
					trace( x );

			}
			lexer.tokenize( attribute_name_state );
		},
		'.' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes.push( {name:'', value:''} );

				case x:
					trace( x );
					
			}
			lexer.reconsume( attribute_name_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-attribute-name-state
	public static var after_attribute_name_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( after_attribute_name_state ),
		'/' => lexer -> lexer.tokenize( self_closing_start_tag_state ),
		'=' => lexer -> lexer.tokenize( before_attribute_value_state ),
		'>' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInTag(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.attributes.push( {name:'', value: ''} );

				case x:
					trace( x );

			}
			lexer.reconsume( attribute_name_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#before-attribute-value-state
	public static var before_attribute_value_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_attribute_value_state ),
		'"' => lexer -> lexer.tokenize( attribute_value_double_quoted_state ),
		'\u0027' => lexer -> lexer.tokenize( attribute_value_single_quoted_state ),
		'>' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingAttributeValue(lexer.curPos()) ) ) );
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'.' => lexer -> lexer.reconsume( attribute_value_unquoted_state ),
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-attribute-value-(quoted)-state
	public static var after_attribute_value_quoted_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_attribute_name_state ),
		'/' => lexer -> lexer.tokenize( self_closing_start_tag_state ),
		'>' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInTag(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingWhitespaceBetweenAttributes(lexer.curPos()) ) ) );
			lexer.reconsume( before_attribute_name_state );
		}
	] );

    // CDATA rules

    // @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-state
	public static var cdata_section_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u005D' => lexer -> lexer.tokenize( cdata_section_bracket_state ),
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInCData(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitString( lexer.currentInputCharacter );
			lexer.tokenize( cdata_section_state );
		}
		// U+0000 NULL characters are handled in the tree construction stage, as part of the in 
		// foreign content insertion mode, which is the only place where CDATA sections can appear.
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-bracket-state
	public static var cdata_section_bracket_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u005D' => lexer -> lexer.tokenize( cdata_section_end_state ),
		'.' => lexer -> {
			lexer.emitString('\u005D');
			lexer.reconsume( cdata_section_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-end-state
	public static var cdata_section_end_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u005D' => lexer -> {
			lexer.emitString('\u005D');
			lexer.tokenize( cdata_section_end_state );
		},
		'\u003E' => lexer -> lexer.tokenize( data_state ),
		'.' => lexer -> {
			lexer.emitString('\u005D');
			lexer.emitString('\u005D');
			lexer.reconsume( cdata_section_state );
		}
	] );

    // DOCTYPE rules

    // @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-state
	public static var doctype_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_doctype_name_state ),
		'>' => lexer -> lexer.reconsume( before_doctype_name_state ),
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			lexer.currentToken = DOCTYPE({forceQuirks:true});
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingWhitespaceBeforeDoctypeName(lexer.curPos()) ) ) );
			lexer.reconsume( before_doctype_name_state );
		}
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#doctype-name-state
	public static var doctype_name_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( after_doctype_name_state ),
		'>' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
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
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.name += '\uFFFD';

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_name_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );
			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
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
	public static var doctype_public_identifier_double_quoted_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'"' => lexer -> lexer.tokenize( after_doctype_public_identifier_state ),
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId += '\uFFFD';

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_public_identifier_double_quoted_state );
		},
		'>' => lexer -> {
			lexer.emitToken( Keyword( ParseError( AbruptDoctypePublicIdentifier(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
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
	public static var doctype_public_identifier_single_quoted_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u0027' => lexer -> lexer.tokenize( after_doctype_public_identifier_state ),
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId += '\uFFFD';

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_public_identifier_single_quoted_state );
		},
		'>' => lexer -> {
			lexer.emitToken( Keyword( ParseError( AbruptDoctypePublicIdentifier(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
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
	public static var doctype_system_identifier_double_quoted_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'"' => lexer -> lexer.tokenize( after_doctype_system_identifier_state ),
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId += '\uFFFD';

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'>' => lexer -> {
			lexer.emitToken( Keyword( ParseError( AbruptDoctypeSystemIdentifier(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
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
	public static var doctype_system_identifier_single_quoted_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\u0027' => lexer -> lexer.tokenize( after_doctype_system_identifier_state ),
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId += '\uFFFD';

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'>' => lexer -> {
			lexer.emitToken( Keyword( ParseError( AbruptDoctypeSystemIdentifier(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId += lexer.currentInputCharacter;

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-name-state
	public static var before_doctype_name_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_doctype_name_state ),
		'[A-Z]' => lexer -> {
			lexer.currentToken = DOCTYPE({
				name:lexer.currentInputCharacter.toLowerCase(), 
				forceQuirks:false
			});
			lexer.tokenize( doctype_name_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			lexer.currentToken = DOCTYPE({name:'\uFFFD', forceQuirks:false});
			lexer.tokenize( doctype_name_state );
		},
		'>' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingDoctypeName(lexer.curPos()) ) ) );
			lexer.currentToken = DOCTYPE({forceQuirks:true});
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			lexer.currentToken = DOCTYPE({forceQuirks:true});
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
			lexer.currentToken = DOCTYPE({
				name:lexer.currentInputCharacter, 
				forceQuirks:false
			});
			lexer.tokenize( doctype_name_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-name-state
	public static var after_doctype_name_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( after_doctype_name_state ),
		'>' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}

			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		/** see Anything else section **/
		'(p|P)(u|U)(b|B)(l|L)(i|I)(c|C)' => lexer -> {
			lexer.tokenize( after_doctype_public_keyword_state );
		},
		'(s|S)(y|Y)(s|S)(t|T)(e|E)(m|M)' => lexer -> {
			lexer.tokenize( after_doctype_system_keyword_state );
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( InvalidCharacterSequenceAfterDoctypeName(lexer.curPos()) ) ) );
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
	public static var after_doctype_public_keyword_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\n\t\u000C ]' => lexer -> lexer.tokenize( before_doctype_public_identifier_state ),
		'"' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingWhitespaceAfterDoctypePublicKeyword(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId = '';

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_public_identifier_double_quoted_state );
		},
		'\u0027' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingWhitespaceAfterDoctypePublicKeyword(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.publicId = '';

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_public_identifier_single_quoted_state );
		},
		'>' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingDoctypePublicIdentifier(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingQuoteBeforeDoctypePublicIdentifier(lexer.curPos()) ) ) );
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
	public static var before_doctype_public_identifier_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
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
			lexer.emitToken( Keyword( ParseError( MissingDoctypePublicIdentifier(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingQuoteBeforeDoctypePublicIdentifier(lexer.curPos()) ) ) );
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
	public static var after_doctype_public_identifier_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( between_doctype_public_and_system_identifiers_state ),
		'>' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'"' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingWhitespaceBetweenDoctypePublicAndSystemIdentifiers(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'\u0027' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingWhitespaceBetweenDoctypePublicAndSystemIdentifiers(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingQuoteBeforeDoctypeSystemIdentifier(lexer.curPos()) ) ) );
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
	public static var between_doctype_public_and_system_identifiers_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( between_doctype_public_and_system_identifiers_state ),
		'>' => lexer -> lexer.tokenize( data_state ),
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
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingQuoteBeforeDoctypeSystemIdentifier(lexer.curPos()) ) ) );
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
	public static var after_doctype_system_keyword_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( before_doctype_system_identifier_state ),
		'"' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingWhitespaceAfterDoctypeSystemKeyword(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_system_identifier_double_quoted_state );
		},
		'\u0027' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingWhitespaceAfterDoctypeSystemKeyword(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.systemId = '';

				case x:
					trace( x );

			}
			lexer.tokenize( doctype_system_identifier_single_quoted_state );
		},
		'>' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingDoctypeSystemIdentifier(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingQuoteBeforeDoctypeSystemIdentifier(lexer.curPos()) ) ) );
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
	public static var before_doctype_system_identifier_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
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
			lexer.emitToken( Keyword( ParseError( MissingDoctypeSystemIdentifier(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( MissingQuoteBeforeDoctypeSystemIdentifier(lexer.curPos()) ) ) );
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
	public static var after_doctype_system_identifier_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> lexer.tokenize( after_doctype_system_identifier_state ),
		'>' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInDoctype(lexer.curPos()) ) ) );
			switch lexer.currentToken {
				case DOCTYPE(data):
					data.forceQuirks = true;

				case x:
					trace( x );

			}
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedCharacterAfterDoctypeSystemIdentifier(lexer.curPos()) ) ) );
			lexer.reconsume( bogus_doctype_state );
		}
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#bogus-doctype-state
	public static var bogus_doctype_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'>' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			lexer.tokenize( data_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			lexer.tokenize( bogus_doctype_state );
		},
		'' => lexer -> {
			lexer.emitHtmlToken( lexer.currentToken );
			EOF;
		},
		'.' => lexer -> lexer.tokenize( bogus_doctype_state ),
	] );

	// Script rules

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-state
	public static var script_data_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'<' => lexer -> lexer.tokenize( script_data_less_than_sign_state ),
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			Keyword(Character({data:'\uFFFD'}));
		},
		'' => lexer -> {
			EOF;
		},
		'[^&<]' => lexer -> Keyword(Character({data:lexer.currentInputCharacter})),
	] );

    // @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-less-than-sign-state
	public static var script_data_less_than_sign_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'/' => lexer -> {
			lexer.temporaryBuffer = '';
			lexer.tokenize( script_data_end_tag_open_state );
		},
		'!' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('!');
			lexer.tokenize( script_data_escape_start_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.reconsume( script_data_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-open-state
	public static var script_data_end_tag_open_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[a-z]' => lexer -> {
			lexer.currentToken = EndTag( makeTag() );
			lexer.reconsume( script_data_end_tag_name_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.reconsume( script_data_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-name-state
	public static var script_data_end_tag_name_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.tokenize( before_attribute_name_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.flushAsCharacterReference();
				lexer.reconsume( script_data_state );

			}
		},
		'/' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.tokenize( self_closing_start_tag_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.flushAsCharacterReference();
				lexer.reconsume( script_data_state );

			}
		},
		'>' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.tokenize( data_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.flushAsCharacterReference();
				lexer.reconsume( script_data_state );

			}
		},
		'[A-Z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.currentInputCharacter.toLowerCase();

				case x:
					trace( x );

			}
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( script_data_end_tag_name_state );
		},
		'[a-z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.currentInputCharacter;
				
				case x:
					trace( x );

			}
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( script_data_end_tag_name_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.flushAsCharacterReference();
			lexer.reconsume( script_data_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escape-start-state
	public static var script_data_escape_start_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> {
			lexer.emitString('-');
			lexer.tokenize( script_data_escape_start_dash_state );
		},
		'.' => lexer -> {
			lexer.reconsume( script_data_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escape-start-dash-state
	public static var script_data_escape_start_dash_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> {
			lexer.emitString('-');
			lexer.tokenize( script_data_escaped_dash_dash_state );
		},
		'.' => lexer -> {
			lexer.reconsume( script_data_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-state
	public static var script_data_escaped_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> {
			lexer.emitString('-');
			lexer.tokenize( script_data_escaped_dash_state);
		},
		'<' => lexer -> {
			lexer.tokenize( script_data_escaped_less_than_sign_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			Keyword(Character({data:'\uFFFD'}));
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInScriptHtmlCommentLikeText(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			Keyword(Character({data:lexer.currentInputCharacter}));
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-state
	public static var script_data_escaped_dash_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> {
			lexer.emitString('-');
			lexer.tokenize( script_data_escaped_dash_state );
		},
		'<' => lexer -> {
			lexer.tokenize( script_data_escaped_less_than_sign_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			lexer.emitString('\uFFFD');
			lexer.tokenize( script_data_escaped_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInScriptHtmlCommentLikeText(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitString( lexer.currentInputCharacter );
			lexer.tokenize( script_data_escaped_state ); 
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-dash-state
	public static var script_data_escaped_dash_dash_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> {
			Keyword(Character({data:'-'}));
		},
		'<' => lexer -> {
			lexer.tokenize( script_data_escaped_less_than_sign_state );
		},
		'>' => lexer -> {
			lexer.emitString('>');
			lexer.tokenize( script_data_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			lexer.emitString('\uFFFD');
			lexer.tokenize( script_data_escaped_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInScriptHtmlCommentLikeText(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitString( lexer.currentInputCharacter );
			lexer.tokenize( script_data_escaped_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-less-than-sign-state
	public static var script_data_escaped_less_than_sign_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'/' => lexer -> {
			lexer.temporaryBuffer = '';
			lexer.tokenize( script_data_escaped_end_tag_open_state );
		},
		'[a-zA-Z]' => lexer -> {
			lexer.temporaryBuffer = '';
			lexer.emitString('<');
			lexer.reconsume( script_data_double_escape_start_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.reconsume( script_data_escaped_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-open-state
	public static var script_data_escaped_end_tag_open_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[a-zA-Z]' => lexer -> {
			lexer.currentToken = EndTag( makeTag() );
			lexer.reconsume( script_data_escaped_end_tag_name_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.reconsume( script_data_escaped_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-name-state
	public static var script_data_escaped_end_tag_name_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C ]' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.tokenize( before_attribute_name_state );

			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.emitString( lexer.temporaryBuffer );
				lexer.reconsume( script_data_escaped_state );

			}
		},
		'/' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.tokenize( self_closing_start_tag_state );
				
			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.emitString( lexer.temporaryBuffer );
				lexer.reconsume( script_data_escaped_state );

			}
		},
		'>' => lexer -> {
			if (lexer.isAppropriateEndTag()) {
				lexer.tokenize( data_state );
				
			} else {
				lexer.emitString('<');
				lexer.emitString('/');
				lexer.emitString( lexer.temporaryBuffer );
				lexer.reconsume( script_data_escaped_state );

			}
		},
		'[A-Z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.currentInputCharacter.toLowerCase();

				case x:
					trace( x );

			}
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( script_data_escaped_end_tag_name_state );
		},
		'[a-z]' => lexer -> {
			switch lexer.currentToken {
				case StartTag(data) | EndTag(data):
					data.name += lexer.currentInputCharacter;

				case x:
					trace( x );

			}
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			lexer.tokenize( script_data_escaped_end_tag_name_state );
		},
		'.' => lexer -> {
			lexer.emitString('<');
			lexer.emitString('/');
			lexer.emitString( lexer.temporaryBuffer );
			lexer.reconsume( script_data_escaped_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-start-state
	public static var script_data_double_escape_start_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C />]' => lexer -> {
			lexer.emitString( lexer.currentInputCharacter );
			if (lexer.temporaryBuffer == 'script') {
				lexer.tokenize( script_data_double_escaped_state );

			} else {
				lexer.tokenize( script_data_escaped_state );

			}
		},
		'[A-Z]' => lexer -> {
			lexer.temporaryBuffer += lexer.currentInputCharacter.toLowerCase();
			Keyword(Character({data:lexer.currentInputCharacter}));
		},
		'[a-z]' => lexer -> {
			lexer.temporaryBuffer += lexer.currentInputCharacter;
			Keyword(Character({data:lexer.currentInputCharacter}));
		},
		'.' => lexer -> {
			lexer.reconsume( script_data_escaped_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-state
	public static var script_data_double_escaped_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> {
			lexer.emitString('-');
			lexer.tokenize( script_data_double_escaped_dash_state );
		},
		'<' => lexer -> {
			lexer.emitString('<');
			lexer.tokenize( script_data_double_escaped_less_than_sign_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			Keyword(Character({data:'\uFFFD'}));
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInScriptHtmlCommentLikeText(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			Keyword(Character({data: lexer.currentInputCharacter }));
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-state
	public static var script_data_double_escaped_dash_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> {
			lexer.emitString('-');
			lexer.tokenize( script_data_double_escaped_dash_dash_state );
		},
		'<' => lexer -> {
			lexer.emitString('<');
			lexer.tokenize( script_data_double_escaped_less_than_sign_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			lexer.emitString('\uFFFD');
			lexer.tokenize( script_data_double_escaped_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInScriptHtmlCommentLikeText(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitString(lexer.currentInputCharacter);
			lexer.tokenize( script_data_double_escaped_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-dash-state
	public static var script_data_double_escaped_dash_dash_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'\\-' => lexer -> {
			Keyword(Character({data:'-'}));
		},
		'<' => lexer -> {
			lexer.emitString('<');
			lexer.tokenize( script_data_double_escaped_less_than_sign_state );
		},
		'>' => lexer -> {
			lexer.emitString('>');
			lexer.tokenize( script_data_state );
		},
		NUL => lexer -> {
			lexer.emitToken( Keyword( ParseError( UnexpectedNullCharacter(lexer.curPos()) ) ) );
			lexer.emitString('\uFFFD');
			lexer.tokenize( script_data_double_escaped_state );
		},
		'' => lexer -> {
			lexer.emitToken( Keyword( ParseError( EofInScriptHtmlCommentLikeText(lexer.curPos()) ) ) );
			EOF;
		},
		'.' => lexer -> {
			lexer.emitString(lexer.currentInputCharacter);
			lexer.tokenize( script_data_escaped_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-less-than-sign-state
	public static var script_data_double_escaped_less_than_sign_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'/' => lexer -> {
			lexer.temporaryBuffer = '';
			lexer.emitString('/');
			lexer.tokenize( script_data_double_escape_end_state );
		},
		'.' => lexer -> {
			lexer.reconsume( script_data_double_escaped_state );
		},
	] );

	// @see https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-end-state
	public static var script_data_double_escape_end_state:Ruleset<Tokenizer, Token<HtmlTokens>> = Mo.rules( [
		'[\t\n\u000C />]' => lexer -> {
			lexer.emitString(lexer.currentInputCharacter);

			if (lexer.temporaryBuffer == 'script') {
				lexer.tokenize( script_data_escaped_state );

			} else {
				lexer.tokenize( script_data_double_escaped_state );

			}
		},
		'[A-Z]' => lexer -> {
			lexer.temporaryBuffer += lexer.current.toLowerCase();
			Keyword(Character({data:lexer.currentInputCharacter}));
		},
		'[a-z]' => lexer -> {
			lexer.temporaryBuffer += lexer.current;
			Keyword(Character({data:lexer.currentInputCharacter}));
		},
		'.' => lexer -> {
			lexer.reconsume( script_data_double_escaped_state );
		},
	] );

}