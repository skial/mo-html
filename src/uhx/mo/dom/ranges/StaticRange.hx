package uhx.mo.dom.ranges;

typedef StaticRangeInit = {
    startContainer:Node, 
    startOffset:Int, 
    endContainer:Node, 
    endOffset:Int
}

/**
    @see https://dom.spec.whatwg.org/#staticrange
**/
class StaticRange extends BaseRange {
    
    /**
        @see https://dom.spec.whatwg.org/#dom-staticrange-staticrange
    **/
    public function new(init:StaticRangeInit) {
        if (init.startContainer.nodeType == NodeType.DocumentType || 
            init.startContainer.nodeType == Node.Attr ||
            init.endContainer.nodeType == NodeType.DocumentType || 
            init.endContainer.nodeType == Node.Attr) {
            throw 'InvalidNodeTypeError';
        }

        start = { node:init.startContainer, offset:init.startOffset };
        end = { node:init.endContainer, offset:init.endOffset };
    }

}