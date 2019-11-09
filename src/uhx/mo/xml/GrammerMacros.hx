package uhx.mo.xml;

#if (eval || macro)
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
#end

import uhx.sys.seri.Range;
import uhx.sys.seri.Ranges;
import rxpattern.internal.RangeUtil;

#if macro
using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
#end

class GrammerMacros {

    public static macro function asString(ranges:ExprOf<Ranges>):ExprOf<String> {
        var str = RangeUtil.printRanges( fromTypedExpr( Context.typeExpr(ranges) ), false).get();
        //trace( str );
        return macro @:pos(ranges.pos) $v{str};
    }

    #if macro

    static final RANGE_CTX:ComplexType = (macro:uhx.sys.seri.Range);
    static final RANGE_TYPE:Type = RANGE_CTX.toType();

    static final RANGES_CTX:ComplexType = (macro:uhx.sys.seri.Ranges);
    static final RANGES_TYPE:Type = RANGES_CTX.toType();

    private static function fromTypedExpr(expr:TypedExpr):Ranges {
        var values = new Ranges([]);

        switch expr {
            // From using `asString()`.
            case { expr:_ => TField(_expr, FStatic(typeRef, fieldRef)), t:type }:
                //trace( fieldRef.get().meta.extract(':value') ); // contains expr.hx value
               values = fromTypedExpr( fieldRef.get().expr() );

            case { expr:TNew(clsRef, typeParams, args), t:type } if (Context.unify(type, RANGES_TYPE)):
                for (value in fromTypedExpr( args[0] ).values) {
                    values.add( value );

                }

            case { expr:TArrayDecl(elements), t:type }:
                for (element in elements) {
                    for (value in fromTypedExpr( element ).values) {
                        values.add( value );

                    }

                }

            case _.expr => TMeta(_, _.expr => TCast(_expr, module)):
                for (value in fromTypedExpr( _expr ).values) {
                    values.add( value );

                }

            case { expr:TBlock(exprs), t:type }:
                for (expr in exprs) {
                    for (value in fromTypedExpr( expr ).values) {
                        values.add( value );

                    }

                }

            case { expr:TNew(clsRef, typeParams, [_.expr => TConst(TInt(min)), _.expr => TConst(TInt(max))]), t:type } if (Context.unify(type, RANGE_TYPE)):
                values.add( new Range(min, max) );

            case { expr:TCall({ expr:TField(_, FStatic(_, fieldRef)) }, args), t:type } if (Context.unify(type, RANGES_TYPE)):

                switch fieldRef.get().name {
                    case 'union':
                        var a = fromTypedExpr( args[0] );
                        var b = fromTypedExpr( args[1] );
                        values = Ranges.union( a, b );

                    case x:
                        throw 'Unsupported method Ranges.$x.';

                }

            case _:
                trace ( expr );

        }

        return values;
    }
    #end

}