package uhx.mo.xml;

import rxpattern.RxPattern;

class Grammer {

    public static final NameStartChar 
    = new RxPattern(GrammerConsts.NameStartChar, Atom).build();

    public static final NameChar
    = new RxPattern(GrammerConsts.NameChar, Atom).build();

    public static final Name
    = new RxPattern(GrammerConsts.Name, Atom).build();

    public static final Names
    = new RxPattern(GrammerConsts.Names, Atom).build();

    public static final NmToken
    = new RxPattern(GrammerConsts.NmToken, Atom).build();

    public static final NmTokens
    = new RxPattern(GrammerConsts.NmTokens, Atom).build();

    public static final NCName
    = new RxPattern(GrammerConsts.NCName, Atom).build();

    public static final Prefix 
    = new RxPattern(GrammerConsts.Prefix, Atom).build();

    public static final LocalPart 
    = new RxPattern(GrammerConsts.LocalPart, Atom).build();

    public static final UnprefixedName 
    = new RxPattern(GrammerConsts.UnprefixedName, Atom).build();

    public static final PrefixedName 
    = new RxPattern(GrammerConsts.PrefixedName, Atom).build();

    public static final QName 
    = new RxPattern(GrammerConsts.QName, Atom).build();

}