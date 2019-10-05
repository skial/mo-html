package uhx.mo.html.internal;

enum HtmlTokens {
	DOCTYPE(obj:Doctype);
	StartTag(obj:Tag);
	EndTag(obj:Tag);
	Comment(obj:Data);
	Character(obj:Data);
	// EOF - using the Tokens.EOF istead
}