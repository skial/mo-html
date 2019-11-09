package uhx.mo.ecma262.contexts;

/**
    @see https://tc39.es/ecma262/#sec-lexical-environments
**/
class LexicalEnvironment {

    public var environmentRecord:{};
    public var outer:Null<LexicalEnvironment> = null;

}