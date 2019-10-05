package uhx.mo.html;

import hxparse.Lexer;
import byte.ByteData;
import hxparse.Ruleset;
import haxe.io.BytesBuffer;
import uhx.mo.html.internal.HtmlTokens;

using tink.CoreApi;

@:forward
@:forwardStatics
enum abstract Characters(String) to String {
    public var NULL = NUL;
	public var NUL = '\u0000';
}

typedef Tokens = Token<HtmlTokens>;
typedef HtmlRules = Ruleset<NewLexer, Tokens>;

class NewLexer extends Lexer {

    /**
        Before each step of the tokenizer, the user agent must first check 
        the parser pause flag. If it is true, then the tokenizer must abort 
        the processing of any nested invocations of the tokenizer, yielding 
        control back to the caller.
    **/
    public var paused:Bool = false;

    /**
        The insertion mode is a state variable that controls the 
        primary operation of the tree construction stage.
        ---
        @see https://html.spec.whatwg.org/multipage/parsing.html#insertion-mode
    **/
    public var insertionMode:String = '';

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
    public var currentInputCharacter(get, never):Null<String>;

    private inline function get_currentInputCharacter():String {
        return this.current;
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
            trace( rule.name );
			return super.token(rule);
		}
		// Might need to capture result. Check backlog before returning or store into backlog?
		return super.token(ruleset);
    }

    public function emitToken(value:Token<HtmlTokens>):Void {
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

    /*public static function consume<R:HtmlRules>(lexer:NewLexer, next:R, returnState:Null<R> = null, buffer:Null<BytesBuffer> = null):Tokens {
        lexer.returnState = returnState;
		return lexer.tokenize( next );
    }*/

    /**
        When a state says to reconsume a matched character in a specified state, 
        that means to switch to that state, but when it attempts to consume the 
        next input character, provide it with the current input character instead.
    **/
    public static function reconsume<R:HtmlRules>(lexer:NewLexer, ruleset:R, characters:Int = 1):Tokens {
        @:privateAccess lexer.pos -= characters;
		return lexer.tokenize( ruleset );
    }

}