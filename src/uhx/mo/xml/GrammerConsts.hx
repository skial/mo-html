package uhx.mo.xml;

using uhx.mo.xml.GrammerMacros;
using rxpattern.UnicodePatternUtil;

class GrammerConsts {

    // @see https://www.w3.org/TR/REC-xml/#NT-Char
    public static final Char:String 
    /*= '\u0009|\u000A|\u000D|[\u0020-\uD7FF]|[\uE000-\uFFFD]|[\u10000-\u10FFFF]'
    .translate();*/
    = GrammerRanges.Char.asString();

    // @see https://www.w3.org/TR/xml/#NT-NameStartChar
    public static final NameStartChar:String 
    /*= ":|[A-Z]|_|[a-z]|[\u00C0-\u00D6]|[\u00D8-\u00F6]|[\u00F8-\u02FF]|[\u0370-\u037D]|[\u037F-\u1FFF]|[\u200C-\u200D]|[\u2070-\u218F]|[\u2C00-\u2FEF]|[\u3001-\uD7FF]|[\uF900-\uFDCF]|[\uFDF0-\uFFFD]|[\u10000-\uEFFFF]"
    .translate();*/
    = GrammerRanges.NameStartChar.asString();

    // @see https://www.w3.org/TR/xml/#NT-NameChar
    public static final NameChar:String
    //= NameStartChar + "|-|.|[0-9]|\u00B7|[\u0300-\u036F]|[\u203F-\u2040]".translate();
    = GrammerRanges.NameChar.asString();

    // @see https://www.w3.org/TR/xml/#NT-Name
    public static final Name:String = NameStartChar + '($NameChar)*';

    public static final Names:String = Name + '(' + '\u0020'.translate() + Name + ')*';

    public static final NmToken:String  = '($NameChar)+';

    public static final NmTokens:String = NmToken + '(' + '\u0020'.translate() + NmToken + ')*';

    private static final NC_NameChar:String
    = GrammerRanges.NC_NameChar.asString();
    private static final NC_NameStartChar:String =
    GrammerRanges.NC_NameStartChar.asString();
    private static final NC_Name:String = NC_NameStartChar + '($NC_NameChar)*';

    /**
        @see https://www.w3.org/TR/xml-names/#NT-NCName
        Name - (Char* ':' Char*)	An XML Name, minus the ":"
    **/
    public static final NCName:String
    = '($NC_Name)(($Char)*:($Char)*)';

    // @see https://www.w3.org/TR/xml-names/#NT-Prefix
    public static final Prefix:String = NCName;

    // @see https://www.w3.org/TR/xml-names/#NT-LocalPart
    public static final LocalPart:String = NCName;

    // @see https://www.w3.org/TR/xml-names/#NT-UnprefixedName
    public static final UnprefixedName:String = LocalPart;

    // @see https://www.w3.org/TR/xml-names/#NT-PrefixedName
    public static final PrefixedName:String = Prefix + ':' + LocalPart;

    // @see https://www.w3.org/TR/xml-names/#NT-QName
    public static final QName:String = PrefixedName + '|' + UnprefixedName;

}