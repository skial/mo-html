package uhx.mo.html.contexts;

import uhx.mo.dom.nodes.Document;

/**
    @see https://html.spec.whatwg.org/multipage/browsers.html#windows
**/
class BrowsingContext {

    public var window:WindowProxy;
    public var openerBrowsingContext:Null<BrowsingContext> = null;
    public var disowned:Bool = false;
    public var isClosing:Bool = false;
    public var sessionHistory:Array<Document> = [];
    public var activeDocument:Document;

    /**
        @see https://html.spec.whatwg.org/multipage/browsers.html#creator-origin
    **/
    public var creatorOrigin:Null<String> = null;

    /**
        @see https://html.spec.whatwg.org/multipage/browsers.html#creator-url
    **/
    public var creatorUrl:Null<String> = null;

    /**
        @see https://html.spec.whatwg.org/multipage/browsers.html#creator-base-url
    **/
    public var creatorBaseUrl:Null<String> = null;


    /**
        @see https://html.spec.whatwg.org/multipage/browsers.html#creating-a-new-browsing-context
    **/
    public function new(creator:Null<Document>, group:Array<BrowsingContext>) {
        if (creator != null) {
            creatorOrigin = creator.origin;
            creatorUrl = creator.url;
            //creatorBaseUrl = creator.baseUrl; // TODO

        }

        var sandboxFlags = null;
        var origin = null;
        var featurePolicy = null;
        var agent = null;
        var realmExecutionContext = null;
        var settingsObject = null;
        // TODO determing these features
        // steps 3-8.

        // 9.
        var document = new Document();
        document.contentType = 'text/html';
        document.origin = origin;
        // TODO set `document` fields based on values determined from TODO above.
        activeDocument = document;
        // TODO step 12-13
        sessionHistory.push( document );
        // 15. Return `browsingContext`
        // DONE
    }

}