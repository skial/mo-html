package uhx.mo.html;

import haxe.ds.Vector;
import be.ds.Consts.*;
import be.ds.Collection;
import be.ds.edges.EdgeNode;
import be.ds.vertices.Vertex;
import be.ds.graphs.IGraph;
import be.ds.graphs.IGraphUX;

import uhx.mo.html.internal.*;

using tink.CoreApi;

#if generic @:generic #end
class NodeGraph implements IGraph<Node, EdgeNode<Int>> {

    public var vertices:Collection<Node>;
    public var edges:Collection<EdgeNode<Int>>;

    public function new() {
        vertices = new Vector<Node>(VectorSize);
        edges = new Vector<EdgeNode<Int>>(VectorSize);
    }

    public inline function add(v:Node):Node {
        return addVertex( v );
    }

    public inline function addVertex(v:Node):Node {
        if (find(v) == null) vertices.add(v);
        if (vertices.isFull()) resizeVertices();
        return v;
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

    public inline function removeVertex(v:Node):NodeGraph {
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

        return this;
    }

    public function addEdge(a:Node, b:Node):NodeGraph {
        var exists = false;
        var size = edges.size;
        
        if (size > 0) for (index in 0...size) {
            switch edges[index] {
                case { a:aa, b:bb }: exists = (aa == a.id && bb == b.id);
                case null, _: continue;
            }
            
            if (exists) break;

        }

        if (!exists) {
            edges.add( new Pair(a.id, b.id) );
            if (edges.isFull()) resizeEdges();

        }

        return this;
    }

    public function removeEdge(a:Node, b:Node):NodeGraph {
        for (index in 0...edges.size) {
            switch edges[index] {
                case { a:aa, b:bb } if (aa == a.id && bb == b.id): 
                    edges[index] = null;
                    break;

                case _:

            }

        }

        return this;
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