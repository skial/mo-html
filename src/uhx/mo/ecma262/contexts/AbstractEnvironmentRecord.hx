package uhx.mo.ecma262.contexts;

/**
    @see https://tc39.es/ecma262/#table-15
**/
interface AbstractEnvironmentRecord {

    public function hasBinding(n:String):Bool;
    public function createMutableBinding(n:String, d:Bool):Void;
    public function createImmutableBinding(n:String, s:Bool):Void;
    public function initializeBinding<T>(n:String, v:T):Void;
    public function setMutableBinding<T>(n:String, v:T, s:Bool):Void;
    public function getBindingValue(n:String, s:Bool):Any;
    public function deleteBinding(n:String):Bool;
    public function hasThisBinding():Bool;
    public function withBaseObject():Null<{}>;

}