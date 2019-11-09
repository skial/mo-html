package uhx.mo.dom.namespaces;

import uhx.mo.xml.Grammer;

// @see https://dom.spec.whatwg.org/#namespaces
class Namespaces {

    /**
        @see https://dom.spec.whatwg.org/#validate
        To validate a qualifiedName, throw an "InvalidCharacterError" 
        DOMException if qualifiedName does not match the Name or QName 
        production.
    **/
    public static function validate(qualifiedName:String):Bool {
        if (!Grammer.Name.match(qualifiedName) || !Grammer.QName.match(qualifiedName)) {
            throw 'InvalidCharacterError';
        }

        return true;
    }

    /**
        @see https://dom.spec.whatwg.org/#validate-and-extract
    **/
    public static function validateAndExtract(namespace:Null<String>, qualifiedName:String) {
        if (namespace == '') namespace = null;
        validate(qualifiedName);
        var prefix = null;
        var localName = qualifiedName;

        if (qualifiedName.indexOf(':') > -1) {
            var parts = qualifiedName.split(':');
            prefix = parts[0];
            localName = parts[1];

        }

        if (prefix != null && namespace == null) {
            throw 'NamespaceError';
        }

        if (prefix == 'xml' && namespace != uhx.mo.infra.Namespaces.XML) {
            throw 'NamespaceError';
        }

        if ((qualifiedName == 'xmlns' || prefix == 'xmlns' && namespace != uhx.mo.infra.Namespaces.XMLNS)) {
            throw 'NamespaceError';
        }

        if (namespace == uhx.mo.infra.Namespaces.XMLNS && (qualifiedName != 'xmlns' || prefix != 'xmlns')) {
            throw 'NamespaceError';
        }

        return {
            namespace:namespace,
            prefix:prefix,
            localName:localName
        }
    }

}