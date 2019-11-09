package uhx.mo.ecma262.datatypes;

/**
    @see https://tc39.es/ecma262/#sec-list-and-record-specification-type
    ---
    The Record type is used to describe data aggregations within the 
    algorithms of this specification. A Record type value consists of one or 
    more named fields. The value of each field is either an ECMAScript 
    value or an abstract value represented by a name associated with 
    the Record type. Field names are always enclosed in double brackets, 
    for example [[Value]].

    For notational convenience within this specification, an object 
    literal-like syntax can be used to express a Record value. For 
    example, `{ [[Field1]]: 42, [[Field2]]: false, [[Field3]]: empty }` 
    defines a Record value that has three fields, each of which is 
    initialized to a specific value. Field name order is not significant. 
    Any fields that are not explicitly listed are considered to be absent.
**/
typedef Record<T> = T;