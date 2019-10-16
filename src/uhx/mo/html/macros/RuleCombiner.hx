package uhx.mo.html.macros;

import hxparse.Pattern;
import hxparse.Charset;
import hxparse.CharRange;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.BuildCache;
import tink.macro.BuildCache.BuildContextN;

using tink.CoreApi;
using haxe.macro.Context;
using tink.MacroApi;
using haxe.macro.ExprTools;
using haxe.macro.TypedExprTools;

class RuleCombiner {

    public static var RETURN_TYPE = null;
    public static var BASE_LEXER = macro:hxparse.Lexer;
    public static var MAP_TYPE = macro:haxe.ds.StringMap<Dynamic>;
    public static var RULESET = macro:hxparse.Ruleset<Enum<EnumValue>>;
    public static var mapType = MAP_TYPE.toType().sure();

    public static var ranges:Map<String, CharRange> = [];
    public static var patterns:Map<String, Pattern> = [];
    public static var expressions:Array<{key:String, expr:Expr}> = [];
    public static var knownTypeRules:Map<String, Array<String>> = [];
    public static var ettype:Type = null;
    public static var retType:Type = null;

    private static function isRuleset(ttype:Type):Bool {
        return switch ttype {
            case TInst(_.get() => cls, _): cls.pack[0] == 'hxparse' && cls.name == 'Ruleset';
            case _: false;
        }
    }

    private static function isStringMap(ctype:ComplexType):Bool {
        return (macro ((null:$ctype):$RULESET)).typeof().isSuccess();
    }

    public static function build() {
        return BuildCache.getTypeN('uhx.mo.html.rules.Rules', function(ctx:BuildContextN) {
            var fields:Array<Field> = [];

            for (type in ctx.types) {
                switch type {
                    case TInst(_.get() => cls, _):
                        knownTypeRules.set( 
                            printCls(cls), 
                            cls.statics.get().map( f -> f.name ) 
                        );

                    case _:

                }

            }

            for (type in ctx.types) {
                switch type {
                    case TInst(_.get() => cls, _):
                        for (field in cls.statics.get()) {
                            expressions = [];
                            var fttype = field.type.followWithAbstracts();
                            var fctype = fttype.toComplex();

                            //trace( field.name );
                            //trace( fttype );
                            //trace( fctype );

                            if (isRuleset(fttype)) {
                                /*if (field.meta.has(':value')) {
                                    var ruleExpr = field.meta
                                        .extract(':value')[0].params[0];
                                        
                                    ruleExpr.iter( extractInfo );

                                }*/
                                ettype = null;
                                retType = null;
                                var typedExpr = field.expr();
                                typedExpr.iter( findType );

                            } else {
                                continue;

                            }

                            var eof = macro lexer -> {};
                            for (e in expressions) if (e.key == '') {
                                eof = macro lexer -> $e{e.expr};
                                break;
                            }
                            var cases:Array<Expr> = [];
                            var funcs:Array<Expr> = [];

                            for (e in expressions) {
                                e.expr = e.expr.map( typeReplace.bind(_, ctx) );

                            }
                            
                            var ectype = if (ettype != null) {
                                ettype.followWithAbstracts().toComplexType();
                            } else {
                                macro:hxparse.Lexer;
                            }
                            var retCtype = if (retType != null) {
                                retType.followWithAbstracts().toComplexType();
                            } else {
                                macro:Void;
                            }

                            for (e in expressions) {
                                cases.push(macro $i{patternName(e.key)});
                                var mname = field.name + '_' + methodName(e.key);
                                var _tmp = macro class {
                                    public static function $mname (lexer:$ectype)/*:$retCtype return */$e{e.expr};
                                }
                                fields.push( _tmp.fields[0] );
                                funcs.push(macro cast $i{mname});
                            }

                            var fname = '${field.name}';
                            var _tmp = macro class {
                                public static final $fname =
                                new hxparse.Ruleset<$retCtype>(
                                    new hxparse.LexEngine([$a{cases}]).firstState(),
                                    [$a{funcs}],
                                    cast $eof,
                                    $v{field.name}
                                );
                            }
                            fields.push( _tmp.fields[0] );

                        }
                        
                        //cls.exclude();

                    case _:
                        //
                }


            }

            for (key in patterns.keys()) {
                inlineRanges( patterns.get(key) );
            }

            for (key in patterns.keys()) {
                var pattern = patternExpr( patterns.get(key) );
                var fname = patternName(key);
                var _tmp = macro class {
                    public static final $fname:hxparse.Pattern = $e{pattern};
                }
                
                fields.insert( 0, _tmp.fields[0] );

            }

            for (key in ranges.keys()) {
                var r = ranges.get(key);
                var range = rangeExpr( r );
                var rname = rangeName( r );
                var _tmp = macro class {
                    public static final $rname:hxparse.CharRange = $e{range};
                }

                fields.insert( 0, _tmp.fields[0] );
            }

            var td = macro class {};
            var printer = new haxe.macro.Printer();
            for (field in fields) {
                if (Context.defined('debug')) {
                    trace( field.name );
                    trace(printer.printField( field ));

                }
                
            }
            td.fields = fields;
            td.name = ctx.name;
            return td;
        });
    }

    private static var key:Null<String> = null;

    private static function fix(key:String):String {
        var regex = new EReg("\\0", "g");
        if (regex.match(key)) {
            key = regex.replace(key, '__NUL__');
        }
        return key;
    }

    private static function rangeName(range:CharRange):String {
        return 'range${range.min}${range.max}';
    }

    private static function patternName(key:String):String {
        var sig = Context.signature(key);
        sig = sig.substring(sig.length-6, sig.length);
        return 'pattern$sig';
    }

    private static function methodName(key:String):String {
        var sig = Context.signature(key);
        sig = sig.substring(sig.length-6, sig.length);
        return 'method$sig';
    }

    private static function printCls(cls:ClassType):String {
        var result = cls.pack.length > 0 ? cls.pack.join('.') + '.' : '';
        return result + cls.name;
    }

    private static function findType(e:TypedExpr):Void {
        switch e.expr {
            case TObjectDecl(fields):
                for (field in fields) {
                    switch field.expr.expr {
                        case TConst(TString(v)) if (field.name == 'rule' && key == null):
                            key = fix(v);

                            if (!patterns.exists(key)) {
                                var _pattern = hxparse.LexEngine.parse(v);
                                patterns.set( key, _pattern );
                            }

                        case TFunction(func) if (field.name == 'func' && key != null):
                            var args = func.args.filter( a -> a.v.name == 'lexer' );
                            if (args.length > 0) {
                                ettype = args[0].v.t;
                            }
                            retType = func.t;
                            expressions.push( { key: key, expr: Context.getTypedExpr(func.expr) } );
                            key = null;
                            //trace( @:privateAccess Context.sExpr(e, true) );

                        case _:

                    }
                }

            case _:
                e.iter( findType );
        }
    }

    private static function extractInfo(e:Expr):Void {
        switch e {
            case macro $value => $block:
                var svalue = value.toString();

                key = fix(svalue);

                if (!patterns.exists(key)) {
                    var _pattern = hxparse.LexEngine.parse(svalue);
                    patterns.set( key, _pattern );
                }

                expressions.push( { key: key, expr: block } );

            case _:
                e.iter( extractInfo );

        }

    }

    private static function inlineRanges(pattern:Pattern):Void {
        switch pattern {
            case Match(values):
                for (value in values) {
                    var key = value.min + ':' + value.max;

                    if (!ranges.exists(key)) {
                        ranges.set(key, value);

                    }

                }

            case Star(p), Plus(p), Group(p):
                inlineRanges(p);

            case Next(a, b), Choice(a, b):
                inlineRanges(a);
                inlineRanges(b);

            case _:

        }
    }

    private static function rangeExpr(range:CharRange):Expr {
        return macro { min:$v{range.min}, max:$v{range.max} };
    }

    private static function patternExpr(pattern:Pattern):Expr {
        return switch pattern {
            case Empty: 
                macro hxparse.Pattern.Empty;

            case Match(c): 
                var array = [for (v in c) macro $i{rangeName(v)}];
                macro hxparse.Pattern.Match([$a{ array }]);

            case Star(p): 
                macro hxparse.Pattern.Star($e{patternExpr(p)});

            case Plus(p): 
                macro hxparse.Pattern.Plus($e{patternExpr(p)});

            case Group(p): 
                macro hxparse.Pattern.Group($e{patternExpr(p)});

            case Next(p1, p2): 
                macro hxparse.Pattern.Next($e{patternExpr(p1)}, $e{patternExpr(p2)});

            case Choice(p1, p2): 
                macro hxparse.Pattern.Choice($e{patternExpr(p1)}, $e{patternExpr(p2)});

        }
    }

    private static function typeReplace(e:Expr, ctx:BuildContextN) {
        return switch e {
            case macro $path.$field:
                var spath = path.toString();
                var sfield = field.toString();
                //trace(spath);
                //trace(sfield);
                if (knownTypeRules.exists(spath)) { 
                    var fields = knownTypeRules.get(spath);

                    if (fields.indexOf(sfield) > -1) {
                        var name = ctx.name;
                        var result = macro @:pos(e.pos) $i{name}.$sfield;
                        return result;

                    }

                }

                e.map( typeReplace.bind(_, ctx) );

            case _:
                e.map( typeReplace.bind(_, ctx) );

        }
    }

}