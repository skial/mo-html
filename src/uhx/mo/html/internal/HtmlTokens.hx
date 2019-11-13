package uhx.mo.html.internal;

@:using(uhx.mo.html.internal.HtmlTokens.HtmlTokensUtil)
enum HtmlTokens {	
	DOCTYPE(obj:Doctype);
	StartTag(obj:Tag);
	EndTag(obj:Tag);
	Comment(obj:Data);
	Character(obj:Data);
	ParseError(obj:String);
	// EOF - using the Tokens.EOF istead
}

class HtmlTokensUtil {

	public static function getTag(token:HtmlTokens):Null<Tag> {
		switch token {
			case StartTag(tag), EndTag(tag): return tag;
			case _:
		}
		return null;
	}

	public static function isCharacter(token:HtmlTokens):Bool {
		switch token {
			case Character(_): return true;
			case _:
		}
		return false;
	}

	public static function isStartTag(token:HtmlTokens):Bool {
		switch token {
			case StartTag(_): return true;
			case _:
		}
		return false;
	}

}