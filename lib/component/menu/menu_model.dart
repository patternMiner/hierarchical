part of menu;

abstract class MenuModel {
  String get search;
  void   set search(String inputText);
  bool   get filterMode;
  bool   get showDeselectOption;
  void   set showDeselectOption(bool show);
  Iterable<MenuItem> get items;
  Iterable<MenuItem> get filteredItems;
  void init(Iterable<MenuItem> items);
  void registerUserDefinedFilter(String name,
                                 ItemListFilter<MenuItem> filter);
  void unregisterUserDefinedFilter(String name,
                                   ItemListFilter<MenuItem> filter);
  void registerUserDefinedEnricher(String name,
                                   ItemListFilter<MenuItem> enricher);
  void unregisterUserDefinedEnricher(String name,
                                     ItemListFilter<MenuItem> enricher);
  int  get height;
  bool get isLinear;
  bool hasParent(MenuItem path);
  bool isLeaf(MenuItem path);
  Iterable getAncestors(MenuItem path);
  Iterable getDescendants(MenuItem path);
  Iterable getChildren(MenuItem path);
  Iterable get roots;
  void clear();
  void dfs(MenuItem root, Set expansionSet, Function visitor);
  MenuItem add(MenuItem path);
  void addAll(Iterable<MenuItem> path);
  MenuItem remove(MenuItem path);
  Stream<MenuSelectionEvent> onSelectionPathRemoved();
}

class MenuItem {
  final List components;
  String _labelForFiltering;

  MenuItem(this.components) {
    assert(this.components != null);
  }

  MenuItem get parent => components.length < 2 ? null :
      new MenuItem(components.sublist(0, components.length-1));

  int  get hashCode {
    int hash = 1;
    components.forEach((value) => hash = hash * 31 + value.hashCode);
    return hash;
  }

  bool operator==(MenuItem other) {
    if (this.components.length == other.components.length) {
      for (int i=0; i<this.components.length; i++) {
        if (this.components[i] != other.components[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  String _getLabelForFiltering() {
    if (_labelForFiltering == null) {
      _labelForFiltering = components.last.toString().toLowerCase();
    }
    return _labelForFiltering;
  }

  bool filter(String trimmedLowerCaseString) =>
      _getLabelForFiltering().contains(trimmedLowerCaseString);

  String toString() => _getLabelForFiltering();
}

abstract class MenuModelMixin {
  final Set<MenuItem> _filteredItems = new LinkedHashSet<MenuItem>();
  final List<MenuItem> _roots = <MenuItem>[];
  final Map<MenuItem, List<MenuItem>> _childrenMap =
      <MenuItem, List<MenuItem>>{};
  StreamController<MenuSelectionEvent> pathRemovedStreamController;
  String _search;
  ItemListProvider<MenuItem> itemListProvider =
      new FilterBasedItemListProvider<MenuItem>();
  List<MenuItem> filteredItems = [];
  bool _showDeselectOption = false;

  /// User defined filters and enrichers, if any, are applied to the original
  /// item list each time the 'filteredItems' getter is called.  User defined
  /// filters and enrichers can be registered/unregistered by the clients as
  /// appropriate to their needs.
  final Map<String, ItemListFilter<MenuItem>> _userDefinedFilterMap =
      <String, ItemListFilter<MenuItem>>{};
  final Map<String, ItemListEnricher<MenuItem>> _userDefinedEnricherMap =
      <String, ItemListEnricher<MenuItem>>{};

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
  Iterable<MenuItem> get items;

  _updateFilteredItems() {
    Iterable items = _filteredItems;
    // Apply the userDefinedFilters, if any, on the _filteredItems.
    _userDefinedFilterMap.values
        .forEach((ItemListFilter<MenuItem> filter) =>
            items = filter(items));
    // Apply the userDefinedEnrichers, if any, on the above results.
    _userDefinedEnricherMap.values
        .forEach((ItemListEnricher<MenuItem> enricher) =>
            items = enricher(items));
    // Apply the primaryEnricher to the above result and return it.
    filteredItems = _primaryEnricher(items);
  }

  void registerUserDefinedFilter(String name,
                                 ItemListFilter<MenuItem> filter) {
    _userDefinedFilterMap[name] = filter;
    _updateFilteredItems();
  }

  void unregisterUserDefinedFilter(String name,
                                   ItemListFilter<MenuItem> filter) {
    _userDefinedFilterMap.remove(name);
    _updateFilteredItems();
  }

  void registerUserDefinedEnricher(String name,
                                   ItemListFilter<MenuItem> enricher) {
    _userDefinedEnricherMap[name] = enricher;
    _updateFilteredItems();
  }

  void unregisterUserDefinedEnricher(String name,
                                     ItemListFilter<MenuItem> enricher) {
    _userDefinedEnricherMap.remove(name);
    _updateFilteredItems();
  }

  /// Applies the MenuModel specific filtering to the given item list.
  Iterable<MenuItem> _primaryFilter (Iterable<MenuItem> items) {
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
  Iterable<MenuItem> _primaryEnricher(Iterable<MenuItem> items) {
    List<MenuItem> processedItems = items.toList();
    if (_showDeselectOption) {
      // Add a 'null' item at index 0 to denote 'deselectOption' when
      // client is g-select and 'showDeselectOption' is turned on.
      processedItems.insert(0, null);
    }
    // when the client isn't g-select, return the given item list as is.
    return processedItems;
  }

  void init(Iterable<MenuItem> paths) {
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
    processFilteredInPaths(_filteredItems);
    _updateFilteredItems();
  }

  processFilteredOutPaths(Iterable<MenuItem> filteredOutPaths);
  processFilteredInPaths(Iterable<MenuItem> filteredInPaths);

  Stream<MenuSelectionEvent> onSelectionPathRemoved() {
    if (pathRemovedStreamController == null) {
      pathRemovedStreamController =
          new StreamController<MenuSelectionEvent>.broadcast();
    }
    return pathRemovedStreamController.stream;
  }

  Iterable getChildren(MenuItem path);
  MenuItem add(MenuItem path);
  void addAll(Iterable<MenuItem> path);

  void dfs(MenuItem root, Set expansionSet, Function visitor) {
    visitor(root);
    if (expansionSet.contains(root)) {
      getChildren(root).forEach((MenuItem child) =>
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

  MenuItem _processListItem(path, List parentStack) {
    MenuItem src = parentStack.isNotEmpty ? parentStack.last : null;
    List pathComponents = src != null ? src.components.toList() : [];
    pathComponents.add(path);
    return add(new MenuItem(pathComponents));
  }
}

class TreeMenuModel extends Object with MenuModelMixin
    implements MenuModel {
  final Graph<MenuItem> _graph = new Graph<MenuItem>();

  TreeMenuModel();

  TreeMenuModel.fromList(List items) {
    _processList(items, []);
    init(itemListProvider.items.toList());
  }

  Iterable<MenuItem> get items =>
    itemListProvider.items.where((MenuItem path) => _graph.isLeaf(path));

  int get height {
    int height = 1;
    _graph.nodes.forEach((MenuItem path) => height =
        height < path.components.length ? path.components.length : height);
    return height;
  }

  bool get isLinear => height == 1;
  bool hasParent(MenuItem path) => _graph.getParents(path).isNotEmpty;
  bool isLeaf(MenuItem path) => _graph.isLeaf(path);
  Iterable getAncestors(MenuItem path) => _graph.getAncestors(path);
  Iterable getDescendants(MenuItem path) => _graph.getDescendants(path);
  Iterable getChildren(MenuItem path) {
    List children = _childrenMap[path];
    if (children == null) {
      children = <MenuItem>[];
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

  void addAll(Iterable<MenuItem> paths) {
    paths.forEach((MenuItem path) => _addToGraph(path));
    itemListProvider.addAll(paths);
    filteredItems.addAll(paths);
    _updateFilteredItems();
  }

  MenuItem add(MenuItem path) {
    itemListProvider.add(_addToGraph(path));
    filteredItems.add(path);
    _updateFilteredItems();
    return path;
  }

  MenuItem remove(MenuItem path) {
    itemListProvider.remove(_removeFromGraph(path, false));
    filteredItems.remove(path);
    _updateFilteredItems();
    return path;
  }

  MenuItem _addToGraph(MenuItem path) {
    MenuItem parent = path.parent;
    if (parent != null) {
      _graph.addEdge(parent, path);
    } else {
      _graph.addNode(path);
    }
    return path;
  }

  MenuItem _removeFromGraph(MenuItem path, bool removeEmptyParent) {
    Iterable<MenuItem> parents = _graph.getParents(path);
    _graph.removeNode(path);
    if (pathRemovedStreamController != null) {
      pathRemovedStreamController.add(new MenuSelectionEvent(
          MenuSelectionEvent.MENU_ITEM_DELETED, this, path, null));
    }
    if (removeEmptyParent) {
      parents.forEach((MenuItem parent) {
        if(_graph.isLeaf(parent)) {
          _removeFromGraph(parent, removeEmptyParent);
        }
      });
    }
    return path;
  }

  void processFilteredOutPaths(Iterable<MenuItem> filteredOutPaths) {
      filteredOutPaths.forEach((MenuItem path) =>
          _removeFromGraph(path, true));
  }

  void processFilteredInPaths(Iterable<MenuItem> filteredInPaths) {
      filteredInPaths.forEach((MenuItem path) =>
          _addToGraph(path));
  }
}

class ListMenuModel extends Object with MenuModelMixin
    implements MenuModel {
  StreamController<MenuSelectionEvent> pathRemovedStreamController;

  ListMenuModel();

  ListMenuModel.fromList(List items) {
    _processList(items, []);
    init(itemListProvider.items.toList());
  }

  Iterable<MenuItem> get items => itemListProvider.items;

  int get height => 1;
  bool get isLinear => true;

  bool hasParent(MenuItem path) => false;
  bool isLeaf(MenuItem path) => true;
  Iterable getAncestors(MenuItem path) => const[];
  Iterable getDescendants(MenuItem path) => const[];
  Iterable getChildren(MenuItem path) => const[];

  Iterable get roots => filteredItems;

  void clear() {
    itemListProvider.clear();
    _childrenMap.clear();
    _roots.clear();
    reset();
    _updateFilteredItems();
  }

  void addAll(Iterable<MenuItem> paths) {
    itemListProvider.addAll(paths);
    filteredItems.addAll(paths);
    _updateFilteredItems();
  }

  MenuItem add(MenuItem path) {
    itemListProvider.add(path);
    filteredItems.add(path);
    _updateFilteredItems();
    return path;
  }

  MenuItem remove(MenuItem path) {
    if (pathRemovedStreamController != null) {
      pathRemovedStreamController.add(new MenuSelectionEvent(
          MenuSelectionEvent.MENU_ITEM_DELETED, this, path, null));
    }
    itemListProvider.remove(path);
    filteredItems.remove(path);
    _updateFilteredItems();
    return path;
  }

  void processFilteredOutPaths(Iterable<MenuItem> filteredOutPaths) {
  }

  void processFilteredInPaths(Iterable<MenuItem> filteredInPaths) {
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
