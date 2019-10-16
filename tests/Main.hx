package ;

import tink.unit.TestBatch;
import uhx.mo.html.NewLexer;
import tink.testrunner.Runner;

//import uhx.mo.html.rules.ALL;

class Main {

    public static function main() {
        //trace( NewLexer );
        /*Runner.run(TestBatch.make([
            new NewHtmlSpec().testFoo(),
        ])).handle( Runner.exit );*/
        new NewHtmlSpec().testFoo();
    }

}
