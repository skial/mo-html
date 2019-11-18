package uhx.mo.html.macros;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ExprTools;

class InsertionRulesTools {

    public static function build() {
        var pos = Context.currentPos();
        var fields = Context.getBuildFields();
        if (Context.defined('display')) return fields;

        var module = Context.getModule('uhx.mo.html.parsing.InsertionMode');
        var modes = switch module[1] {
            case TInst(_.get() => cls, params):
                cls.statics.get().map( f -> f.name.toLowerCase() );

            case _:
                Context.error('Can not find or access `uhx.mo.html.parsing.InsertionMode`.', pos);

        }

        for (field in fields) {
            switch field.kind {
                case FFun(method) if (field.access.indexOf(APublic) > -1 && modes.indexOf(field.name.toLowerCase()) > -1):
                    
                    switch method.expr {
                        case _.expr => EBlock(exprs):
                            for (expr in exprs) {
                                switch expr {
                                    case _.expr => ESwitch(e, cases, edef):
                                        for (c in cases) if (c.expr != null && c.values.length > 0) switch c.values {
                                            case [macro _]:
                                                var name = '${field.name}_anythingElse';
                                                var newField = (macro class {
                                                    public function $name():Void {
                                                        @:pos(c.expr.pos) $e{c.expr};
                                                    }
                                                }).fields[0];
                                                switch newField.kind {
                                                    case FFun(m):
                                                        m.args = method.args;
                                                        newField.kind = FFun({args:method.args, ret:m.ret, expr:m.expr, params:m.params});

                                                    case _:
                                                }

                                                fields.push( newField );
                                                
                                                //trace( new haxe.macro.Printer().printField( newField ) );
                                                c.expr = macro @:pos(c.expr.pos) $i{name}($a{method.args.map(a -> macro $i{a.name})});

                                            case _:

                                        }

                                    case _:
                                        if (Context.defined('debug')) {
                                            trace( expr );
                                            trace( expr.toString() );

                                        }
                                        break;

                                }
                            }
                        case _:
                            if (Context.defined('debug')) {
                                trace(method.expr);
                                trace(method.expr.toString());
                                
                            }
                            break;
                    }

                case _:
                    continue;
            }
        }

        return fields;
    }

}