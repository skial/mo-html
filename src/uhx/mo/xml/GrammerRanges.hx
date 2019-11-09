package uhx.mo.xml;

import uhx.sys.seri.Range;
import uhx.sys.seri.Ranges;

class GrammerRanges {

    // @see https://www.w3.org/TR/REC-xml/#NT-Char
    public static final Char:Ranges = new Ranges([
        0x0009, 0x000A, 0x000D, {min:0x0020, max:0xD7FF},
        {min:0xE000, max:0xFFFD}, {min:0x10000, max:0x10FFFF}
    ]);

    // @see https://www.w3.org/TR/xml/#NT-NameStartChar
    public static final NameStartChar:Ranges = new Ranges([
        ':'.code, {min:'A'.code, max:'Z'.code}, '_'.code,
        {min:'a'.code, max:'z'.code}, {min:0x00C0, max:0x00D6},
        {min:0x00D8, max:0x00F6}, {min:0x00F8, max:0x02FF}, 
        {min:0x0370, max:0x037D}, {min:0x037F, max:0x1FFF}, 
        {min:0x200C, max:0x200D}, {min:0x2070, max:0x218F}, 
        {min:0x2C00, max:0x2FEF}, {min:0x3001, max:0xD7FF}, 
        {min:0xF900, max:0xFDCF}, {min:0xFDF0, max:0xFFFD}, 
        {min:0x10000, max:0xEFFFF}
    ]);

    // @see https://www.w3.org/TR/xml/#NT-NameChar
    public static final NameChar:Ranges = Ranges.union( NameStartChar, new Ranges([
        '-'.code, '.'.code, {min:'0'.code, max:'9'.code},
        0x00B7, {min:0x0300, max:0x036F}, {min:0x203F, max:0x2040}
    ]) );

    public static final NC_NameStartChar:Ranges 
    = new Ranges([
        {min:'A'.code, max:'Z'.code}, '_'.code,
        {min:'a'.code, max:'z'.code}, {min:0x00C0, max:0x00D6},
        {min:0x00D8, max:0x00F6}, {min:0x00F8, max:0x02FF}, 
        {min:0x0370, max:0x037D}, {min:0x037F, max:0x1FFF}, 
        {min:0x200C, max:0x200D}, {min:0x2070, max:0x218F}, 
        {min:0x2C00, max:0x2FEF}, {min:0x3001, max:0xD7FF}, 
        {min:0xF900, max:0xFDCF}, {min:0xFDF0, max:0xFFFD}, 
        {min:0x10000, max:0xEFFFF}
    ]);

    public static final NC_NameChar:Ranges = Ranges.union( NC_NameStartChar, new Ranges([
        '-'.code, '.'.code, {min:'0'.code, max:'9'.code},
        0x00B7, {min:0x0300, max:0x036F}, {min:0x203F, max:0x2040}
    ]) );

}