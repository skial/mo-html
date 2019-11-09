package uhx.mo.html;

import uhx.mo.dom.nodes.Document;
import uhx.mo.ecma262.realms.Realm;

/**
    @see https://html.spec.whatwg.org/multipage/webappapis.html#environment-settings-object
**/
class EnvironmentSettings extends Environment {

    public var realmExecutionContext:Realm;
    public var moduleMap:{};
    public var responsibleBrowsingContext:{};
    public var responsibleEventLoop:{};
    public var responsibleDocument:Document;
    public var apiUrlCharacterEncoding:String;
    public var apiBaseUrl:String;
    public var origin:String;
    public var httpsState:String;
    public var referrerPolicy:String;

}