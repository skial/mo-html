package uhx.mo.html;

import uhx.mo.fetch.Request;
import uhx.mo.html.contexts.BrowsingContext;

/**
    Relevant
    ---
    @see https://html.spec.whatwg.org/multipage/browsing-the-web.html#browsing-the-web
**/
@:using(uhx.mo.html.UserAgent.UserAgrentUtil)
class UserAgent {

    private static var _current:Null<UserAgent>;
    public static var current(get, null):UserAgent;

    private static function get_current() {
        if (_current == null) {
            _current = new UserAgent();
        }

        return _current;
    }

    //

    private function new() {}

}

class UserAgrentUtil {

    /**
        @see https://html.spec.whatwg.org/multipage/browsing-the-web.html#navigate
    **/
    public static function navigate(userAgent:UserAgent, browsingContext:BrowsingContext, resource:Request, exceptionsEnabledFlag:Bool = false) {

    }

}