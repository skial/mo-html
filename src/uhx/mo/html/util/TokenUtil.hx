package uhx.mo.html.util;

class TokenUtil {

    public static function sure<T>(v:Token<T>):T {
        return get(v);
    }

    public static function get<T>(v:Token<T>):Null<T> {
        return switch v {
            case Keyword(t): t;
            case _: null;
        }
    }

    public static function isEOF<T>(v:Token<T>):Bool {
        switch v {
            case EOF: return true;
            case _:
        }
        return false;
    }

}