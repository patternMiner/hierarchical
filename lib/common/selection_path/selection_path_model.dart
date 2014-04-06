part of selection_path;

abstract class SelectionPathModel {
  Function get getLabelTemplateMarkup;
  set getLabelTemplateMarkup(Function f);
  SelectionPathMediator get mediator;
  set mediator(SelectionPathMediator m);
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
}

class TreeSelectionPathModel implements SelectionPathModel {
  final Graph<SelectionPath> _graph = new Graph<SelectionPath>();
  final List<SelectionPath> _roots = <SelectionPath>[];
  final Map<SelectionPath, List<SelectionPath>> _childrenMap =
      <SelectionPath, List<SelectionPath>>{};
  Function getLabelTemplateMarkup;
  SelectionPathMediator mediator;

  TreeSelectionPathModel(this.getLabelTemplateMarkup) {
    assert(this.getLabelTemplateMarkup != null);
  }

  TreeSelectionPathModel.fromList(List items,
      this.getLabelTemplateMarkup) {
    assert(this.getLabelTemplateMarkup != null);
    _processList(items, []);
  }

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
    if (mediator != null) {
      mediator.post(new SelectionPathEvent(
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
  Function getLabelTemplateMarkup;
  SelectionPathMediator mediator;

  ListSelectionPathModel(this.getLabelTemplateMarkup) {
    assert(this.getLabelTemplateMarkup != null);
  }

  ListSelectionPathModel.fromList(List items,
      this.getLabelTemplateMarkup) {
    assert(this.getLabelTemplateMarkup != null);
    _processList(items, []);
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
    _roots.add(path);
    return path;
  }

  SelectionPath remove(SelectionPath path) {
    _roots.remove(path);
    if (mediator != null) {
      mediator.post(new SelectionPathEvent(
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
