package uhx.mo.ecma262.realms;

import uhx.mo.ecma262.GlobalObject;
import uhx.mo.ecma262.datatypes.Record;
import uhx.mo.ecma262.contexts.GlobalEnvironment;

/**
    @see https://tc39.es/ecma262/#sec-code-realms
**/
class Realm {

    public var intrinsics:Record<{}> = {};
    public var globalObject:GlobalObject = new GlobalObject();
    public var globalEnv:GlobalEnvironment = new GlobalEnvironment();
    public var templateMap:Array<Record<{ site:{}, array:{} }>> = [];
    public var hostDefined:Any = null;

    public function new() {}

}