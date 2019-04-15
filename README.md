# mo-html

[Mo](https://github.com/skial/mo)'s html lexer & parser.

### Notes

- `#Comments` contain leading and trailing `--` characters.
- Unknown elements `<randomNodeName/>` are treated as normal elements.

## Installation

1. [hxparse] - `https://github.com/Simn/hxparse development src`
2. [mo] - `haxelib git mo https://github.com/skial/mo master src`
3. mo-html - `haxelib git mo-html https://github.com/skial/mo-html master src`

[mo]: https://github.com/skial/mo "Mo's base lexer and parser utilities based on hxparse."
[hxparse]: http://github.com/simn/hxparse "Haxe Lexer and Parser Library."