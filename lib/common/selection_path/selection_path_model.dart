part of selection_path;

abstract class SelectionPathModel {
  String get search;
  void   set search(String inputText);
  bool   get filterMode;
  bool   get showDeselectOption;
  void   set showDeselectOption(bool show);
  Iterable<SelectionPath> get items;
  Iterable<SelectionPath> get filteredItems;
  void init(Iterable<SelectionPath> items);
  void registerUserDefinedFilter(String name,
                                 ItemListFilter<SelectionPath> filter);
  void unregisterUserDefinedFilter(String name,
                                   ItemListFilter<SelectionPath> filter);
  void registerUserDefinedEnricher(String name,
                                   ItemListFilter<SelectionPath> enricher);
  void unregisterUserDefinedEnricher(String name,
                                     ItemListFilter<SelectionPath> enricher);
  int  get height;
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
  void addAll(Iterable<SelectionPath> path);
  SelectionPath remove(SelectionPath path);
  Stream<SelectionPathEvent> onSelectionPathRemoved();
}

abstract class SelectionPathModelMixin {
  final Set<SelectionPath> _filteredItems = new LinkedHashSet<SelectionPath>();
  final List<SelectionPath> _roots = <SelectionPath>[];
  final Map<SelectionPath, List<SelectionPath>> _childrenMap =
      <SelectionPath, List<SelectionPath>>{};
  StreamController<SelectionPathEvent> pathRemovedStreamController;
  String _search;
  ItemListProvider<SelectionPath> itemListProvider =
      new FilterBasedItemListProvider<SelectionPath>();
  List<SelectionPath> filteredItems = [];
  bool _showDeselectOption = false;

  /// User defined filters and enrichers, if any, are applied to the original
  /// item list each time the 'filteredItems' getter is called.  User defined
  /// filters and enrichers can be registered/unregistered by the clients as
  /// appropriate to their needs.
  final Map<String, ItemListFilter<SelectionPath>> _userDefinedFilterMap =
      <String, ItemListFilter<SelectionPath>>{};
  final Map<String, ItemListEnricher<SelectionPath>> _userDefinedEnricherMap =
      <String, ItemListEnricher<SelectionPath>>{};

  bool get showDeselectOption => _showDeselectOption;
  set showDeselectOption(bool show) => _showDeselectOption = show;

  String get search => _search;

  set search(String text) {
    _search = text;
    if (itemListProvider.filterMode) {
      // apply the primary filter
      filter();
    } else { // search mode, get the dynamic item list.
      itemListProvider.getItems(text).then((List provisionedItems) {
        init(provisionedItems);
      });
    }
  }

  bool get filterMode => itemListProvider.filterMode;
  Iterable<SelectionPath> get items;

  _updateFilteredItems() {
    Iterable items = _filteredItems;
    // Apply the userDefinedFilters, if any, on the _filteredItems.
    _userDefinedFilterMap.values
        .forEach((ItemListFilter<SelectionPath> filter) =>
            items = filter(items));
    // Apply the userDefinedEnrichers, if any, on the above results.
    _userDefinedEnricherMap.values
        .forEach((ItemListEnricher<SelectionPath> enricher) =>
            items = enricher(items));
    // Apply the primaryEnricher to the above result and return it.
    filteredItems = _primaryEnricher(items);
  }

  void registerUserDefinedFilter(String name,
                                 ItemListFilter<SelectionPath> filter) {
    _userDefinedFilterMap[name] = filter;
    _updateFilteredItems();
  }

  void unregisterUserDefinedFilter(String name,
                                   ItemListFilter<SelectionPath> filter) {
    _userDefinedFilterMap.remove(name);
    _updateFilteredItems();
  }

  void registerUserDefinedEnricher(String name,
                                   ItemListFilter<SelectionPath> enricher) {
    _userDefinedEnricherMap[name] = enricher;
    _updateFilteredItems();
  }

  void unregisterUserDefinedEnricher(String name,
                                     ItemListFilter<SelectionPath> enricher) {
    _userDefinedEnricherMap.remove(name);
    _updateFilteredItems();
  }

  /// Applies the MenuModel specific filtering to the given item list.
  Iterable<SelectionPath> _primaryFilter (Iterable<SelectionPath> items) {
    if (!itemListProvider.filterMode || search == null || search.isEmpty) {
      // Return the given list as is.
      return items;
    } else {
      // Apply the 'search' text based filter on the given item list and
      // return the result.
      String entry = search.trim().toLowerCase();
      return items.where((item) => item.filter(entry)).toList();
    }
  }

  /// Applies the MenuModel specific enrichments to the given item list.
  Iterable<SelectionPath> _primaryEnricher(Iterable<SelectionPath> items) {
    List<SelectionPath> processedItems = items.toList();
    if (_showDeselectOption) {
      // Add a 'null' item at index 0 to denote 'deselectOption' when
      // client is g-select and 'showDeselectOption' is turned on.
      processedItems.insert(0, null);
    }
    // when the client isn't g-select, return the given item list as is.
    return processedItems;
  }

  void init(Iterable<SelectionPath> paths) {
    clear();
    addAll(paths);
    filter();
  }

  void clear();

  void reset() {
    filter();
  }

  /// Applies the primaryFilter to the original list of items.
  void filter() {
    _filteredItems.clear();
    _filteredItems.addAll(_primaryFilter(items));
    processFilteredOutPaths(items.toSet().difference(_filteredItems));
    _updateFilteredItems();
  }

  processFilteredOutPaths(Iterable<SelectionPath> filteredOutPaths);

  Stream<SelectionPathEvent> onSelectionPathRemoved() {
    if (pathRemovedStreamController == null) {
      pathRemovedStreamController =
          new StreamController<SelectionPathEvent>.broadcast();
    }
    return pathRemovedStreamController.stream;
  }

  Iterable getChildren(SelectionPath path);
  SelectionPath add(SelectionPath path);
  void addAll(Iterable<SelectionPath> path);

  void dfs(SelectionPath root, Set expansionSet, Function visitor) {
    visitor(root);
    if (expansionSet.contains(root)) {
      getChildren(root).forEach((SelectionPath child) =>
        dfs(child, expansionSet, visitor));
    }
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

class TreeSelectionPathModel extends Object with SelectionPathModelMixin
    implements SelectionPathModel {
  final Graph<SelectionPath> _graph = new Graph<SelectionPath>();

  TreeSelectionPathModel();

  TreeSelectionPathModel.fromList(List items) {
    _processList(items, []);
    init(itemListProvider.items.toList());
  }

  Iterable<SelectionPath> get items =>
    itemListProvider.items.where((SelectionPath path) => _graph.isLeaf(path));

  int get height {
    int height = 1;
    _graph.nodes.forEach((SelectionPath path) => height =
        height < path.components.length ? path.components.length : height);
    return height;
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
    itemListProvider.clear();
    _childrenMap.clear();
    _roots.clear();
    _graph.clear();
    reset();
    _updateFilteredItems();
  }

  void addAll(Iterable<SelectionPath> paths) {
    paths.forEach((SelectionPath path) => _addToGraph(path));
    itemListProvider.addAll(paths);
    filteredItems.addAll(paths);
    _updateFilteredItems();
  }

  SelectionPath add(SelectionPath path) {
    itemListProvider.add(_addToGraph(path));
    filteredItems.add(path);
    _updateFilteredItems();
    return path;
  }

  SelectionPath remove(SelectionPath path) {
    itemListProvider.remove(_removeFromGraph(path, false));
    filteredItems.remove(path);
    _updateFilteredItems();
    return path;
  }

  SelectionPath _addToGraph(SelectionPath path) {
    SelectionPath parent = path.parent;
    if (parent != null) {
      _graph.addEdge(parent, path);
    } else {
      _graph.addNode(path);
    }
    return path;
  }

  SelectionPath _removeFromGraph(SelectionPath path, bool removeEmptyParent) {
    Iterable<SelectionPath> parents = _graph.getParents(path);
    _graph.removeNode(path);
    if (pathRemovedStreamController != null) {
      pathRemovedStreamController.add(new SelectionPathEvent(
          SelectionPathEvent.SELECTION_PATH_DELETED, this, path, null));
    }
    if (removeEmptyParent) {
      parents.forEach((SelectionPath parent) {
        if(_graph.isLeaf(parent)) {
          _removeFromGraph(parent, removeEmptyParent);
        }
      });
    }
    return path;
  }

  void processFilteredOutPaths(Iterable<SelectionPath> filteredOutPaths) {
      filteredOutPaths.forEach((SelectionPath path) =>
          _removeFromGraph(path, true));
  }
}

class ListSelectionPathModel extends Object with SelectionPathModelMixin
    implements SelectionPathModel {
  StreamController<SelectionPathEvent> pathRemovedStreamController;

  ListSelectionPathModel();

  ListSelectionPathModel.fromList(List items) {
    _processList(items, []);
    init(itemListProvider.items.toList());
  }

  Iterable<SelectionPath> get items => itemListProvider.items;

  int get height => 1;
  bool get isLinear => true;

  bool hasParent(SelectionPath path) => false;
  bool isLeaf(SelectionPath path) => true;
  Iterable getAncestors(SelectionPath path) => const[];
  Iterable getDescendants(SelectionPath path) => const[];
  Iterable getChildren(SelectionPath path) => const[];

  Iterable get roots => filteredItems;

  void clear() {
    itemListProvider.clear();
    _childrenMap.clear();
    _roots.clear();
    reset();
    _updateFilteredItems();
  }

  void addAll(Iterable<SelectionPath> paths) {
    itemListProvider.addAll(paths);
    filteredItems.addAll(paths);
    _updateFilteredItems();
  }

  SelectionPath add(SelectionPath path) {
    itemListProvider.add(path);
    filteredItems.add(path);
    _updateFilteredItems();
    return path;
  }

  SelectionPath remove(SelectionPath path) {
    if (pathRemovedStreamController != null) {
      pathRemovedStreamController.add(new SelectionPathEvent(
          SelectionPathEvent.SELECTION_PATH_DELETED, this, path, null));
    }
    itemListProvider.remove(path);
    filteredItems.remove(path);
    _updateFilteredItems();
    return path;
  }

  void processFilteredOutPaths(Iterable<SelectionPath> filteredOutPaths) {
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

  FilterBasedItemListProvider();

  Future<List<T>> getItems(String inputText) {
    return new Future.value(_items);
  }
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
