part of selection_path;

abstract class SelectionPathModel {
  Function get getLabelTemplateMarkup;
  set getLabelTemplateMarkup(Function f);
  int get height;
  bool get isLinear;
  bool hasParent(SelectionPath path);
  bool isLeaf(SelectionPath path);
  Iterable getAncestors(SelectionPath path);
  Iterable getDescendants(SelectionPath path);
  Iterable getChildren(SelectionPath path);
  Iterable get roots;
  void clear();
  void dfs(SelectionPath root, Set expansionSet, Function visitor);
  SelectionPath add(SelectionPath path);
  SelectionPath remove(SelectionPath path);
  Stream<SelectionPathEvent> onSelectionPathRemoved();
}

class TreeSelectionPathModel implements SelectionPathModel {
  final Graph<SelectionPath> _graph = new Graph<SelectionPath>();
  final List<SelectionPath> _roots = <SelectionPath>[];
  final Map<SelectionPath, List<SelectionPath>> _childrenMap =
      <SelectionPath, List<SelectionPath>>{};
  StreamController<SelectionPathEvent> pathRemovedStreamController;
  Function getLabelTemplateMarkup;

  TreeSelectionPathModel(this.getLabelTemplateMarkup) {
    assert(this.getLabelTemplateMarkup != null);
  }

  TreeSelectionPathModel.fromList(List items,
      this.getLabelTemplateMarkup) {
    assert(this.getLabelTemplateMarkup != null);
    _processList(items, []);
  }

  int get height {
    int height = 1;
    _graph.nodes.forEach((SelectionPath path) => height =
        height < path.components.length ? path.components.length : height);
    return height;
  }

  Stream<SelectionPathEvent> onSelectionPathRemoved() {
    if (pathRemovedStreamController == null) {
      pathRemovedStreamController =
          new StreamController<SelectionPathEvent>.broadcast();
    }
    return pathRemovedStreamController.stream;
  }

  bool get isLinear => height == 1;
  bool hasParent(SelectionPath path) => _graph.getParents(path).isNotEmpty;
  bool isLeaf(SelectionPath path) => _graph.isLeaf(path);
  Iterable getAncestors(SelectionPath path) => _graph.getAncestors(path);
  Iterable getDescendants(SelectionPath path) => _graph.getDescendants(path);
  Iterable getChildren(SelectionPath path) {
    List children = _childrenMap[path];
    if (children == null) {
      children = <SelectionPath>[];
      _childrenMap[path] = children;
    }
    children.clear();
    children.addAll(_graph.getChildren(path));
    return children;
  }

  Iterable get roots {
    _roots.clear();
    _roots.addAll(_graph.getRoots());
    return _roots;
  }

  void clear() {
    _childrenMap.clear();
    _roots.clear();
    _graph.clear();
  }

  void dfs(SelectionPath root, Set expansionSet, Function visitor) {
    visitor(root);
    if (expansionSet.contains(root)) {
      getChildren(root).forEach((SelectionPath child) =>
        dfs(child, expansionSet, visitor));
    }
  }

  SelectionPath add(SelectionPath path) {
    SelectionPath parent = path.parent;
    if (parent != null) {
      _graph.addEdge(parent, path);
    } else {
      _graph.addNode(path);
    }
    return path;
  }

  SelectionPath remove(SelectionPath path) {
    _graph.removeNode(path);
    if (pathRemovedStreamController != null) {
      pathRemovedStreamController.add(new SelectionPathEvent(
          SelectionPathEvent.SELECTION_PATH_DELETED, this, path, null));
    }
    return path;
  }

  void _processList(List paths, List parentStack) {
    var curNode = null;
    paths.forEach((path) {
      if (path is List) {
        if (curNode != null) {
          parentStack.add(curNode);
        }
        _processList(path, parentStack);
        if (parentStack.isNotEmpty) {
          parentStack.removeLast();
        }
      } else {
        curNode = _processListItem(path, parentStack);
      }
    });
  }

  SelectionPath _processListItem(path, List parentStack) {
    SelectionPath src = parentStack.isNotEmpty ? parentStack.last : null;
    List pathComponents = src != null ? src.components.toList() : [];
    pathComponents.add(path);
    return add(new SelectionPath(pathComponents));
  }
}

class ListSelectionPathModel implements SelectionPathModel {
  final List<SelectionPath> _roots = <SelectionPath>[];
  StreamController<SelectionPathEvent> pathRemovedStreamController;
  Function getLabelTemplateMarkup;

  ListSelectionPathModel(this.getLabelTemplateMarkup) {
    assert(this.getLabelTemplateMarkup != null);
  }

  ListSelectionPathModel.fromList(List items,
      this.getLabelTemplateMarkup) {
    assert(this.getLabelTemplateMarkup != null);
    _processList(items, []);
  }

  int get height => 1;
  bool get isLinear => true;

  Stream<SelectionPathEvent> onSelectionPathRemoved() {
    if (pathRemovedStreamController == null) {
      pathRemovedStreamController =
          new StreamController<SelectionPathEvent>.broadcast();
    }
    return pathRemovedStreamController.stream;
  }

  bool hasParent(SelectionPath path) => false;
  bool isLeaf(SelectionPath path) => true;
  Iterable getAncestors(SelectionPath path) => const[];
  Iterable getDescendants(SelectionPath path) => const[];
  Iterable getChildren(SelectionPath path) => const[];

  Iterable get roots => _roots;

  void clear() {
    _roots.clear();
  }

  void dfs(SelectionPath root, Set expansionSet, Function visitor) {
    visitor(root);
    if (expansionSet.contains(root)) {
      getChildren(root).forEach((SelectionPath child) =>
        dfs(child, expansionSet, visitor));
    }
  }

  SelectionPath add(SelectionPath path) {
    if (!_roots.contains(path)) {
      _roots.add(path);
    }
    return path;
  }

  SelectionPath remove(SelectionPath path) {
    _roots.remove(path);
    if (pathRemovedStreamController != null) {
      pathRemovedStreamController.add(new SelectionPathEvent(
          SelectionPathEvent.SELECTION_PATH_DELETED, this, path, null));
    }
    return path;
  }

  void _processList(List paths, List parentStack) {
    var curNode = null;
    paths.forEach((path) {
      if (path is List) {
        if (curNode != null) {
          parentStack.add(curNode);
        }
        _processList(path, parentStack);
        if (parentStack.isNotEmpty) {
          parentStack.removeLast();
        }
      } else {
        curNode = _processListItem(path, parentStack);
      }
    });
  }

  SelectionPath _processListItem(path, List parentStack) {
    SelectionPath src = parentStack.isNotEmpty ? parentStack.last : null;
    List pathComponents = src != null ? src.components.toList() : [];
    pathComponents.add(path);
    return add(new SelectionPath(pathComponents));
  }
}
