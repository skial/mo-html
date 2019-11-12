package uhx.mo.html;

import uhx.mo.html.Environment;
import uhx.mo.dom.nodes.Element;
import uhx.mo.dom.nodes.Document;
import uhx.mo.ecma262.realms.Realm;
import uhx.mo.ecma262.GlobalObject;

/**
    @see https://html.spec.whatwg.org/multipage/window-object.html#the-window-object
    ---
    In this specification, all JavaScript realms are created with global objects 
    that are either Window or WorkerGlobalScope objects.
**/
class Window extends GlobalObject {

    public var name:String;
    public var status:String;

    // the current browsing context
    public var window(get, null):WindowProxy;

    public inline function get_window() {
        return this;
    }

    public var self(get, null):WindowProxy;

    private inline function get_self() {
        return this;
    }

    public var document(get, null):Document;

    public inline function get_document() {
        return document;
    }
    //public var history(get, null):History;
    //public var location(get, null):Location;
    //public var customElements(get, null):CustomElementRegistry;
    //public var locationbar(get, null):BarProp;
    //public var menubar(get, null):BarProp;
    //public var personalbar(get, null):BarProp;
    //public var scrollbars(get, null):BarProp;
    //public var statusbar(get, null):BarProp;
    //public var toolbar(get, null):BarProp;
    public var closed(get, null):Bool;

    private inline function get_closed():Bool {
        return false;
    }

    public function close():Void {}
    public function stop():Void {}
    public function focus():Void {}
    public function blur():Void {}

    // other browsing contexts
    public var frames(get, null):WindowProxy;

    private inline function get_frames() {
        return this;
    }

    public var length(get, null):Int;

    private inline function get_length() {
        return 0;
    }

    public var top(get, null):Null<WindowProxy>;

    private inline function get_top() {
        return null;
    }

    public var opener:Any;
    public var parent(get, null):Null<WindowProxy>;

    private inline function get_parent() {
        return null;
    }

    public var frameElement(get, null):Null<Element>;

    private inline function get_frameElement() {
        return null;
    }

    public function open(?url:String = '', ?target:String = '_blank', ?features = ''):Null<WindowProxy> {
        return null;
    }
    //getter object (DOMString name);
    // Since this is the global object, the IDL named getter adds a NamedPropertiesObject exotic
    // object on the prototype chain. Indeed, this does not make the global object an exotic object.
    // Indexed access is taken care of by the WindowProxy exotic object.

    // the user agent
    //public var navigator(get, null):Navigator;
    //public var applicationCache(get, null):ApplicationCache;

    // user prompts
    public function alert(?message:Void):Void {}
    public function confirm(?message:String = ''):Bool {
        return false;
    }
    public function prompt(?message:String = '', ?_default:String = ''):Null<String> {
        return null;
    }
    public function print():Void {}

    public function postMessage(message:Any, targetOrigin:String, ?transfer:Array<{}>):Void {}
    //public function postMessage(message:Any, ?WindowPostMessageOptions:{}):Void {}

    //

    public function new () {
        super();
    }

}

class WindowUtil {

    /**
        @see https://html.spec.whatwg.org/multipage/window-object.html#set-up-a-window-environment-settings-object
    **/
    public static function setupWindowEnvironmentSettingsObject(executionContext:{}, ?reservedEnvironment:Environment):EnvironmentSettings {
        
        return null;
    }

}