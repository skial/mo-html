package uhx.mo.html.internal;

import uhx.mo.html.NewLexer;

class TokenUtil {

	public static inline function makeTag(name:String = '', selfClosing:Bool = false, ?attributes:Array<Attribute>):Tag {
		return { name: name, selfClosing: selfClosing, attributes: attributes == null ? [] : attributes };
	}

	/*public static function isAppropiateEndTag(lexer:NewLexer):Bool {
		if (lexer.lastToken != null) return switch [lexer.lastToken, lexer.currentToken] {
			case [StartTag({name:s}), EndTag({name:e})]: s == e;
			case _: false;
		}

		return false;
	}*/

}