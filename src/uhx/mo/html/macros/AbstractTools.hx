package uhx.mo.html.macros;

#if (eval || macro)
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
#end

class AbstractTools {

    public static macro function asArray<T>(expr:Expr):ExprOf<Array<T>> {
        var pos = expr.pos;
        var asString = expr.toString();
        var results = [];
        var ctype = null;
        var _class = null;
        var type = try {
            // Direct call to `asArray` method.
            Context.followWithAbstracts( Context.getType( asString ) );
        } catch (e:Any) {
            // Get type for `@:this this` expression from `@:using`.
            Context.followWithAbstracts( Context.typeof( expr ) );
        }

        switch type {
            case TAnonymous(_.get() => {status:AClassStatics(_.get() => cls)}):
                _class = cls;

            case TAbstract(_.get() => abs, params):
                if (!abs.meta.has(':enum')) {
                    Context.error('`$asString` is not an Enum Abstract type.', pos);

                }

                ctype = abs.type.toComplexType();
                _class = abs.impl.get();

            case _:
                Context.error('Can not resolve `$asString` to an Enum Abstract type.', pos);

        }

        function getConstant(e:TypedExpr):Any {
            return switch e.expr {
                case TCast(_e, _): getConstant(_e);
                case TConst(TInt(v)): v;
                case TConst(TFloat(v)): Std.parseFloat(v);
                case TConst(TBool(v)): v;
                case TConst(TString(v)): v;
                case _: 
                    Context.error('Only constant values are supported.', pos);
                    null;
            }
        }

        var statics = _class.statics.get();

        if (statics.length == 0) {
            Context.warning('`$asString` has no enum abstract values.', pos);
            return macro @:pos(pos) [];

        }

        for (value in statics) {
            results.push( getConstant( value.expr() ) );

        }

        var r = macro @:pos(pos) $a{results.map( value -> macro $v{value} )};
        if (ctype != null) r = macro @:pos(pos) ($r:Array<$ctype>);

        if (Context.defined('debug')) {
            trace( results );
            trace( r.toString() );
        }

        return r;
    }

}