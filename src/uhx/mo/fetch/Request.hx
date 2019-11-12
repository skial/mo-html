package uhx.mo.fetch;

import uhx.mo.html.Environment;
import uhx.mo.html.EnvironmentSettings;

/**
    @see https://fetch.spec.whatwg.org/#concept-request
**/
@:forward
@:forwardStatics
abstract Request(RequestImpl) {

    @:from public static function fromUrl(url:String) {
        return null;
    }

}

class RequestImpl {

    public var method:Void->Void;
    public var url:String;
    public var localUrlsOnlyFlag:Bool;
    public var headerList:Array<String>;
    public var unsafeRequestFlag:Bool;
    public var body:Null<String>;
    public var client:Null<EnvironmentSettings>;
    public var reservedClient:Null<Environment>;
    public var replacesClientId:String;
    public var window:String;
    public var keepAliveFlag:Bool;
    public var serviceWorkersMode:String;
    public var initiator:String;
    public var destination:String;
    public var isScriptLike:Bool;
    public var priority:Null<{}>;
    public var origin:String;
    public var referrer:String;
    public var referrerPolicy:String;
    public var synchronousFlag:Bool;
    public var mode:String;
    public var useCorsPreflightFlag:Bool;
    public var credentialsMode:String;
    public var useUrlCredentialsFlag:Bool;
    public var cacheMode:String;
    public var redirectMode:String;
    public var integrityMedadata:String;
    public var cryptographicNonceMetadata:String;
    public var parserMetadata:String;
    public var reloadNavigationFlag:Bool;
    public var historyNavigationFlag:Bool;
    public var taintedOriginFlag:Bool;
    public var urlList:Array<String>;
    public var currentUrl:String;
    public var redirectCount:Int;
    public var responseTainting:String;
    public var preventNoCacheCacheControlHeaderModificationFlag:Bool;
    public var doneFlag:Bool;
    public var subresourceRequest:Request;
    public var potentialNavigationOrSubresourceRequest:Request;
    public var nonSubresourceRequest:Request;
    public var navigationRequest:Request;

    public function new() {}

}