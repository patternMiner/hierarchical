library graph;

import 'dart:collection';

class Graph<T> {
  final Set<T> _vertices = new LinkedHashSet<T>();
  final Map<T, Set<T>> _inEdgeMap = new Map<T, Set<T>>();
  final Map<T, Set<T>> _outEdgeMap =  new Map<T, Set<T>>();

  List<T> get nodes => new List<T>.from(_vertices);

  int get numNodes => _vertices.length;

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

  bool addNode(T node) {
    return _vertices.add(node);
  }

  bool removeNode(T node) {
    _getInEdges(node).forEach((T parent) => _getOutEdges(parent).remove(node));
    _getOutEdges(node).forEach((T child) => removeNode(child));
    _inEdgeMap.remove(node);
    _outEdgeMap.remove(node);
    return _vertices.remove(node);
  }

  bool addEdge(T src, T dst) {
    _vertices.addAll([src, dst]);
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

  List<T> getDescendants(T node) =>
      _getDescendantsInternal(node, new HashSet<T>());

  List<T> getAncestors(T node) =>
      _getAncestorsInternal(node, new HashSet<T>());

  bool isLeaf(T node) => _getOutEdges(node).isEmpty;

  List<T> _getDescendantsInternal(T node, Set<T> visited) {
    visited.add(node);
    Iterable<T> descendants = getChildren(node);
    List<T> result = descendants.toList(growable: true);
    descendants.forEach((T child) {
      if (!visited.contains(child)) {
        result.addAll(_getDescendantsInternal(child, visited));
      }
    });
    return result;
  }

  Iterable<T> _getAncestorsInternal(T node, Set<T> visited) {
    visited.add(node);
    Iterable<T> ancestors = getParents(node);
    List<T> result = ancestors.toList(growable: true);
    ancestors.forEach((T parent) {
      if (!visited.contains(parent)) {
        result.addAll(_getAncestorsInternal(parent, visited));
      }
    });
    return result;
  }

  void printGraph(T root, String indent) {
    _printGraphInternal(root, indent, new Set());
  }

  void _printGraphInternal(T root, String indent, Set<T>visited) {
    print("$indent $root");
    visited.add(root);
    indent = "$indent    ";
    getChildren(root).forEach((T child) {
      if (!visited.contains(child)){
        _printGraphInternal(child, indent, visited);
      }
    });
  }
}
