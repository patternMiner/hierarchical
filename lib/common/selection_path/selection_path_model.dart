part of selection_path;

abstract class SelectionPathModel {
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

  TreeSelectionPathModel();

  TreeSelectionPathModel.fromList(List items) {
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

  ListSelectionPathModel();

  ListSelectionPathModel.fromList(List items) {
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

/// A stateful abstraction that can either filter an existing item list,
/// or generate a brand new item list, based on the user input and its
/// mode of operation.
///
/// Can be in one of two modes:
///   1. FILTER_MODE
///   2. SEARCH_MODE
///
abstract class ItemListProvider<T> {
final List<T> _items = new List<T>();
List<T> get items => _items;

/// FILTER_MODE: filterMode = true;
/// SEARCH_MODE: filterMode = false;
bool get filterMode;

void clear() {
  _items.clear();
}

void init(Iterable<T> items) {
  _items.clear();
  _items.addAll(items);
}

int remove(T item) {
  int removalIndex = _items.indexOf(item);
  if (removalIndex != -1) {
    _items.removeAt(removalIndex);
  }
  return removalIndex;
}

void add(T item) {
  if (!_items.contains(item)) {
     _items.add(item);
  }
}

void addAll(Iterable<T> items) {
  for (T item in items) {
    add(item);
  }
}

Future<List<T>> getItems(String inputText);
}

/// An ItemListProvider that works in FILTER_MODE.
class FilterBasedItemListProvider<T> extends ItemListProvider {
final bool filterMode = true;
final Function itemLabelHandler;

FilterBasedItemListProvider(this.itemLabelHandler);

Future<List<T>> getItems(String inputText) {
  return new Future.value(_items);
}

String getItemLabel(T item) =>
    (itemLabelHandler != null) ? itemLabelHandler(item) :
      (item != null) ? item.toString() : '';
}

/// An empty ItemListProvider that works in SEARCH_MODE.
/// Subclasses must set the 'searchForItems' to appropriate
/// Function to perform search based item list generation.
class SearchBasedItemListProvider<T> extends ItemListProvider {
final bool filterMode = false;
final ItemsGetter<T> searchForItems;

SearchBasedItemListProvider(ItemsGetter<T> this.searchForItems);

Future<List<T>> getItems(String inputText) => searchForItems(inputText);
}

typedef Future<List<T>> ItemsGetter<T>(String query);

/// Typically inserts more items to the given list.
typedef Iterable<T> ItemListEnricher<T>(Iterable<T> items);

/// Typically removes items from the given list.
typedef Iterable<T> ItemListFilter<T>(Iterable<T> items);
