library graph;

import 'dart:collection';

/**
 * Simple implementation of a directed graph.
 */
class Graph<T> {
  final Set<T> _vertices = new LinkedHashSet<T>();
  final Map<T, Set<T>> _inEdgeMap = new Map<T, Set<T>>();
  final Map<T, Set<T>> _outEdgeMap =  new Map<T, Set<T>>();

  Graph<T> clone() {
    Graph<T> other = new Graph<T>();
    _vertices.forEach((T src) {
      other.addNode(src);
      getChildren(src).forEach((T dst) => other.addEdge(src, dst));
    });
    return other;
  }

  Set<T> get nodes => _vertices.toSet();

  int get numNodes => _vertices.length;

  /// The number of edges.  Takes time O(|V| + |E|) so don't call too often.
  int get numEdges {
    int size = 0;
    for (T node in _vertices) {
      size += _getOutEdges(node).length;
    }
    return size;
  }

  void clear() {
    _vertices.clear();
    _inEdgeMap.clear();
    _outEdgeMap.clear();
  }

  bool addNode(T node) => _vertices.add(node);

  bool removeNode(T node) {
    _getInEdges(node).forEach((T parent) =>
        _getOutEdges(parent).remove(node));
    getChildren(node).forEach((T child) => removeNode(child));
    _inEdgeMap.remove(node);
    _outEdgeMap.remove(node);
    return _vertices.remove(node);
  }

  bool addEdge(T src, T dst) {
    if (src == dst || getAncestors(src).contains(dst)) {
      throw new ArgumentError('cycle detected with edge: ($src, $dst)');
    }
    _vertices..add(src)..add(dst);
    _getInEdges(dst).add(src);
    return _getOutEdges(src).add(dst);
  }

  bool removeEdge(T src, T dst) =>
      (_getInEdges(dst).remove(src) && _getOutEdges(src).remove(dst));

  Set<T> _getInEdges(T node) =>
      _inEdgeMap.putIfAbsent(node, () => new LinkedHashSet<T>());

  Set<T> _getOutEdges(T node) =>
      _outEdgeMap.putIfAbsent(node, () => new LinkedHashSet<T>());

  List<T> getRoots() =>
    _vertices.where((T node) => _getInEdges(node).isEmpty).toList();

  List<T> getChildren(T node) => _getOutEdges(node).toList();

  List<T> getParents(T node) => _getInEdges(node).toList();

  Set<T> getDescendants(T node) {
    var visited = new Set<T>();
    void _visitDescendants(T node) {
      visited.add(node);
      _getOutEdges(node).forEach((T child) {
        if (!visited.contains(child)) {
          _visitDescendants(child);
        }
      });
    }
    _visitDescendants(node);
    return visited..remove(node);
  }

  Set<T> getAncestors(T node) {
    var visited = new Set<T>();
    void _visitAncestors(T node) {
      visited.add(node);
      _getInEdges(node).forEach((T parent) {
        if (!visited.contains(parent)) {
          _visitAncestors(parent);
        }
      });
    }
    _visitAncestors(node);
    return visited..remove(node);
  }

  bool isLeaf(T node) => _getOutEdges(node).isEmpty;
}
