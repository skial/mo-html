package uhx.mo.dom;

import haxe.ds.Vector;
import be.ds.Consts.*;
import be.ds.Collection;
import be.ds.graphs.IGraph;
import be.ds.edges.EdgeNode;
import be.ds.vertices.Vertex;
import uhx.mo.dom.nodes.Node;

using tink.CoreApi;

// @see https://dom.spec.whatwg.org/#trees
// @see https://en.wikipedia.org/wiki/Tree_(graph_theory)
class Tree implements IGraph<Node, EdgeNode<Int>> {

    public var vertices:Collection<Node>;
    public var edges:Collection<EdgeNode<Int>>;

    public function new() {
        vertices = new Vector<Node>(VectorSize);
        edges = new Vector<EdgeNode<Int>>(VectorSize);
    }

    public inline function add(v:Node):Node {
        return addNode( v );
    }

    public inline function addNode(v:Node):Node {
        return vertices[addVertex( v )];
    }

    public function addVertex(v:Node):Int {
        var idx = -1;
        for (i in 0...vertices.size) if (v.compare(vertices[i])) {
            idx = i;
            break;
        }
        if (idx == -1) idx = vertices.add(v);
        if (vertices.isFull()) resizeVertices();
        return idx;
    }

    public inline function find(v:Node):Null<Node> {
        var result = null;
        var vertex = null;

        for (index in 0...vertices.size) {
            vertex = vertices[index];
            if (vertex.compare(v)) {
                result = vertex;
                break;

            }

        }

        return result;
    }

    public inline function removeVertex(v:Node):Bool {
        var exists = false;

        for (index in 0...vertices.size) {
            var vertex = vertices[index];
            if (exists = vertex != null && vertex.compare(v)) {
                vertices[index] = null;
                break;

            }

        }

        if (exists) for (index in 0...edges.size) {
            switch edges[index] {
                case {a:aa, b:bb} if (aa == v.id || bb == v.id): edges[index] = null;
                case null, _:
            }

        }

        return exists;
    }

    public function addEdge(a:Node, b:Node):Int {
        var idx = -1;
        var exists = false;
        var size = edges.size;
        
        if (size > 0) for (index in 0...size) {
            switch edges[index] {
                case { a:aa, b:bb }: 
                    exists = (aa == a.id && bb == b.id);

                case null, _: continue;
            }
            
            if (exists) {
                idx = index;
                break;
            }

        }

        if (!exists) {
            idx = edges.add( new Pair(a.id, b.id) );
            if (edges.isFull()) resizeEdges();

        }

        return idx;
    }

    public function removeEdge(a:Node, b:Node):Bool {
        for (index in 0...edges.size) {
            switch edges[index] {
                case { a:aa, b:bb } if (aa == a.id && bb == b.id): 
                    edges[index] = null;
                    return true;

                case _:

            }

        }

        return false;
    }

    public function isConnected(a:Node, b:Node):Bool {
        var exists = false;
        var size = edges.size;

        if (size > 0) for (index in 0...size) {
            switch edges[index] {
                case { a:aa, b:bb }: 
                    exists = (aa == a.id && bb == b.id);

                case null, _: continue;
            }

            if (exists) break;

        }

        return exists;
    }

    public inline function iterator():Iterator<Node> {
        return vertices.iterator();
    }

    //

    private function resizeVertices() {
        vertices = vertices.resize( Math.round(vertices.length * 1.25) );
    }

    private inline function resizeEdges() {
        edges = edges.resize( Math.round(edges.length * 1.25) );
    }

}