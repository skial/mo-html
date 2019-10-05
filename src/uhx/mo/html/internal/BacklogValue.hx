package uhx.mo.html.internal;

import haxe.io.Bytes;

using String;
using haxe.io.Bytes;

/*@:callable 
abstract BacklogValue(Array<Token<HtmlTokens>>->Void) from Array<Token<HtmlTokens>>->Void to Array<Token<HtmlTokens>>->Void {

	@:from public static inline function fromToken(t:Token<HtmlTokens>):BacklogValue {
		return values -> values.push( t );
	}

	@:from public static inline function fromHtmlToken(h:HtmlTokens):BacklogValue {
		return values -> values.push( Keyword( h ) );
	}

	@:from public static inline function fromString(v:String):BacklogValue {
		return values -> values.push( Keyword( Character({data:v}) ) );
	}

	@:from public static inline function fromBytes(b:Bytes):BacklogValue {
		return values -> for (i in 0...b.length) values.push( Keyword( Character({data:b.getData().fastGet(i).fromCharCode()}) ) );
	}

}*/