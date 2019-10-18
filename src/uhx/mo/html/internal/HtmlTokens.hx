package uhx.mo.html.internal;

enum HtmlTokens {	
	DOCTYPE(obj:Doctype);
	StartTag(obj:Tag);
	EndTag(obj:Tag);
	Comment(obj:Data);
	Character(obj:Data);
	ParseError(obj:String);
	// EOF - using the Tokens.EOF istead
}