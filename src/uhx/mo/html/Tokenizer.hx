package uhx.mo.html;

import hxparse.Lexer;
import byte.ByteData;
import hxparse.Ruleset;
import haxe.io.BytesBuffer;
import uhx.sys.seri.Range;
import uhx.sys.seri.Ranges;
import uhx.mo.html.internal.HtmlTokens;
import uhx.mo.html.parsing.InsertionMode;

using tink.CoreApi;

@:notNull
@:forward
@:forwardStatics
enum abstract Characters(String) to String {
    public var NULL = NUL;
	public var NUL = '\u0000';
}

typedef Tokens = Token<HtmlTokens>;
typedef HtmlRules = Ruleset<Tokenizer, Tokens>;

class Tokenizer extends Lexer {

    /**
        Before each step of the tokenizer, the user agent must first check 
        the parser pause flag. If it is true, then the tokenizer must abort 
        the processing of any nested invocations of the tokenizer, yielding 
        control back to the caller.
    **/
    public var paused:Bool = false;

    /**
        The insertion point is the position (just before a character or just 
        before the end of the input stream) where content inserted using 
        `document.write()` is actually inserted. The insertion point is 
        relative to the position of the character immediately after it, it 
        is not an absolute offset into the input stream. Initially, the 
        insertion point is undefined.
        ---
        The insertion mode is a state variable that controls the 
        primary operation of the tree construction stage.
        ---
        @see https://html.spec.whatwg.org/multipage/parsing.html#insertion-mode
    **/
    public var insertionMode:InsertionMode = Initial;

    /**
        Initially, the stack of open elements is empty. The stack grows downwards; 
        the topmost node on the stack is the first one added to the stack, and 
        the bottommost node of the stack is the most recently added node in the 
        stack (notwithstanding when the stack is manipulated in a random access 
        fashion as part of the handling for misnested tags).
        ---
        @see https://html.spec.whatwg.org/multipage/parsing.html#stack-of-open-elements
    **/
    public var backlog:Array<Tokens> = [];
    public var lastToken:Null<HtmlTokens> = null;
    /**
        When a state says to flush code points consumed as a character reference, 
        it means that for each code point in the temporary buffer (in the order 
        they were added to the buffer) user agent must append the code point from 
        the buffer to the current attribute's value if the character reference 
        was consumed as part of an attribute, or emit the code point as a character 
        token otherwise.
    **/
    public var temporaryBuffer:Null<String> = null;
    public var currentToken:Null<HtmlTokens> = null;
    public var characterReferenceCode:Int = 0;

    // The current input character is the last character to have been consumed.
    // @see https://html.spec.whatwg.org/multipage/parsing.html#current-input-character
    public var currentInputCharacter(get, never):Null<String>;

    private inline function get_currentInputCharacter():String {
        return this.current;
    }

    /**
        The next input character is the first character in the input stream 
        that has not yet been consumed or explicitly ignored by the requirements 
        in this section. Initially, the next input character is the first 
        character in the input.
        @see https://html.spec.whatwg.org/multipage/parsing.html#next-input-character
    **/
    public var nextInputCharacter(get, never):Null<String>;

    private inline function get_nextInputCharacter():Null<String> {
        return (pos + 1 == this.input.length) 
            ? null 
            : String.fromCharCode(this.input.readByte(pos + 1));
    }

    /**
        The exact behavior of certain states depends on the 
        insertion mode and the stack of open elements. Certain states 
        also use a temporary buffer to track progress, and the character 
        reference state uses a return state to return to the state it was 
        invoked from.
    **/
    public var returnState:Null<HtmlRules> = null;
	public var backpressure:Array<HtmlRules> = [];

    public function new(content:ByteData, name:String) {
        super(content, name);
    }

    public function tokenize(ruleset:HtmlRules):Token<HtmlTokens> {
        //trace( this.current );
        if (backlog.length > 0) {
			backpressure.push( ruleset );
			return backlog.shift();
		}
		if (backpressure.length > 0) {
            var rule = backpressure.shift();
			return super.token(rule);
		}
		// Might need to capture result. Check backlog before returning or store into backlog?
		return super.token(ruleset);
    }

    public inline function emitToken(value:Token<HtmlTokens>):Void {
        backlog.push( value );
    }

    public inline function emitString(value:String):Void {
        emitToken( Const(CString(value)) );
    }

    public inline function flushAsCharacterReference() {
       emitToken( Const(CString(temporaryBuffer)) );
    }

    public function isAppropiateEndTag():Bool {
		if (lastToken != null) return switch [lastToken, currentToken] {
			case [StartTag({name:s}), EndTag({name:e})]: s == e;
			case _: false;
		}

		return false;
	}

    // @see https://html.spec.whatwg.org/multipage/parsing.html#charref-in-attribute
    public function isPartOfAttribute():Bool {
        return 
        this.returnState == uhx.mo.html.rules.Rules.attribute_value_double_quoted_state
        || this.returnState == uhx.mo.html.rules.Rules.attribute_value_single_quoted_state
        || this.returnState == uhx.mo.html.rules.Rules.attribute_value_unquoted_state;
    }

    // @see https://infra.spec.whatwg.org/#noncharacter
    /*public static final nonCharacterRange:Ranges = new Ranges([
        new Range(0xFDD0, 0xFDEF), 0xFFFE, 0xFFFF, 0x1FFFE, 
        0x1FFFF, 0x2FFFE, 0x2FFFF, 0x3FFFE, 0x3FFFF, 0x4FFFE, 
        0x4FFFF, 0x5FFFE, 0x5FFFF, 0x6FFFE, 0x6FFFF, 0x7FFFE, 
        0x7FFFF, 0x8FFFE, 0x8FFFF, 0x9FFFE, 0x9FFFF, 0xAFFFE, 
        0xAFFFF, 0xBFFFE, 0xBFFFF, 0xCFFFE, 0xCFFFF, 0xDFFFE, 
        0xDFFFF, 0xEFFFE, 0xEFFFF, 0xFFFFE, 0xFFFFF, 0x10FFFE, 
        0x10FFFF
    ]);*/

    /*public static final controlCodeRange:Ranges = {
        var rs = new Ranges([
            0x0D, new Range(0x0000, 0x001F), new Range(0x007F, 0x009F)
        ]);
        rs.remove(0x0009);
        rs.remove(0x000A);
        rs.remove(0x000D);
        rs.remove(0x0020);
        rs;
    }

    public static final characterReferenceKeys:Array<Int> = [
        0x80, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A,
        0x8B, 0x8C, 0x8E, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
        0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9E, 0x9F
    ];

    public static final characterReferenceValues:Array<Int> = [
        0x20AC, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, 
        0x02C6, 0x2030, 0x0160,
        0x2039, 0x0152, 0x017D, 0x2018, 0x2019, 0x201C, 0x201D, 
        0x2022, 0x2013, 0x2014,
        0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x017E, 0x0178
    ];*/

    /*public static function consume<R:HtmlRules>(lexer:NewLexer, next:R, returnState:Null<R> = null, buffer:Null<BytesBuffer> = null):Tokens {
        lexer.returnState = returnState;
		return lexer.tokenize( next );
    }*/

    /**
        When a state says to reconsume a matched character in a specified state, 
        that means to switch to that state, but when it attempts to consume the 
        next input character, provide it with the current input character instead.
    **/
    public static function reconsume<R:HtmlRules>(lexer:Tokenizer, ruleset:R, characters:Int = 1):Tokens {
        @:privateAccess lexer.pos -= characters;
		return lexer.tokenize( ruleset );
    }

}