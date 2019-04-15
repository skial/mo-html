package uhx.mo.html;

import haxe.ds.Vector;
import be.ds.Consts.*;
import be.ds.Collection;
import be.ds.edges.EdgeNode;
import be.ds.vertices.Vertex;
import be.ds.graphs.IGraphUX;

import uhx.mo.html.Lexer.Ref as HtmlVertex;

using tink.CoreApi;

#if generic @:generic #end
class HtmlGraph<V> implements IGraphUX<V, HtmlVertex<V>, EdgeNode<Int>> {

    public var vertices:Collection<HtmlVertex<V>>;
    public var edges:Collection<EdgeNode<Int>>;

    public function new() {
        vertices = new Vector<HtmlVertex<V>>(VectorSize);
        edges = new Vector<EdgeNode<Int>>(VectorSize);
    }

    public inline function add(v:V):HtmlVertex<V> {
        return addVertex( new HtmlVertex<V>(v) );
    }

    public inline function addVertex(v:HtmlVertex<V>):HtmlVertex<V> {
        if (find(v.value) == null) vertices.add(v);
        if (vertices.isFull()) resizeVertices();
        return v;
    }

    public inline function find(v:V):Null<HtmlVertex<V>> {
        var result = null;
        var vertex = null;

        for (index in 0...vertices.size) {
            vertex = vertices[index];
            if (vertex.value == v) {
                result = vertex;
                break;

            }

        }

        return result;
    }

    public inline function removeVertex(v:HtmlVertex<V>):HtmlGraph<V> {
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

    public function addEdge(a:HtmlVertex<V>, b:HtmlVertex<V>):HtmlGraph<V> {
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

    public function removeEdge(a:HtmlVertex<V>, b:HtmlVertex<V>):HtmlGraph<V> {
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

    public function isConnected(a:HtmlVertex<V>, b:HtmlVertex<V>):Bool {
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

    public inline function iterator():Iterator<HtmlVertex<V>> {
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