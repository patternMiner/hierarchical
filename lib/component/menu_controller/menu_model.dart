part of menu_controller;

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
  bool hasParent(MenuItem item);
  bool isLeaf(MenuItem item);
  Iterable getAncestors(MenuItem item);
  Iterable getDescendants(MenuItem item);
  Iterable getChildren(MenuItem item);
  Iterable get roots;
  void clear();
  void dfs(MenuItem root, Set expansionSet, Function visitor);
  MenuItem add(MenuItem item);
  void addAll(Iterable<MenuItem> item);
  MenuItem remove(MenuItem item);
  Stream<MenuSelectionEvent> onSelectionItemRemoved();
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
  StreamController<MenuSelectionEvent> itemRemovedStreamController;
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

  void init(Iterable<MenuItem> items) {
    clear();
    addAll(items);
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
    _updateFilteredItems();
  }

  processFilteredInItems(Iterable<MenuItem> filteredInItems);
  processFilteredOutItems(Iterable<MenuItem> filteredOutItems);

  Stream<MenuSelectionEvent> onSelectionItemRemoved() {
    if (itemRemovedStreamController == null) {
      itemRemovedStreamController =
          new StreamController<MenuSelectionEvent>.broadcast();
    }
    return itemRemovedStreamController.stream;
  }

  Iterable getChildren(MenuItem item);
  bool isLeaf(MenuItem item);
  MenuItem add(MenuItem item);
  void addAll(Iterable<MenuItem> item);

  void dfs(MenuItem root, Set expansionSet, Function visitor) {
    visitor(root);
    if (expansionSet.contains(root)) {
      getChildren(root).forEach((MenuItem child) =>
        dfs(child, expansionSet, visitor));
    }
  }

  void _processList(List items, List parentStack) {
    var curNode = null;
    items.forEach((item) {
      if (item is List) {
        if (curNode != null) {
          parentStack.add(curNode);
        }
        _processList(item, parentStack);
        if (parentStack.isNotEmpty) {
          parentStack.removeLast();
        }
      } else {
        curNode = _processListItem(item, parentStack);
      }
    });
  }

  MenuItem _processListItem(item, List parentStack) {
    MenuItem src = parentStack.isNotEmpty ? parentStack.last : null;
    List itemComponents = src != null ? src.components.toList() : [];
    itemComponents.add(item);
    return add(new MenuItem(itemComponents));
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
    itemListProvider.items.where((MenuItem item) => _graph.isLeaf(item));

  int get height {
    int height = 1;
    _graph.nodes.forEach((MenuItem item) => height =
        height < item.components.length ? item.components.length : height);
    return height;
  }

  bool get isLinear => height == 1;
  bool hasParent(MenuItem item) => _graph.getParents(item).isNotEmpty;
  bool isLeaf(MenuItem item) => _graph.isLeaf(item);
  Iterable getAncestors(MenuItem item) => _graph.getAncestors(item);
  Iterable getDescendants(MenuItem item) => _graph.getDescendants(item);
  Iterable getChildren(MenuItem item) {
    List children = _childrenMap[item];
    if (children == null) {
      children = <MenuItem>[];
      _childrenMap[item] = children;
    }
    children.clear();
    children.addAll(_graph.getChildren(item));
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

  void addAll(Iterable<MenuItem> items) {
    items.forEach((MenuItem item) => _addToGraph(item));
    itemListProvider.addAll(items);
    filteredItems.addAll(items);
    _updateFilteredItems();
  }

  MenuItem add(MenuItem item) {
    itemListProvider.add(_addToGraph(item));
    filteredItems.add(item);
    _updateFilteredItems();
    return item;
  }

  MenuItem remove(MenuItem item) {
    itemListProvider.remove(_removeFromGraph(item, false));
    filteredItems.remove(item);
    _updateFilteredItems();
    return item;
  }

  MenuItem _addToGraph(MenuItem item) {
    MenuItem parent = item.parent;
    if (parent != null) {
      _graph.addEdge(parent, item);
    } else {
      _graph.addNode(item);
    }
    return item;
  }

  MenuItem _removeFromGraph(MenuItem item, bool removeEmptyParent) {
    Iterable<MenuItem> parents = _graph.getParents(item);
    _graph.removeNode(item);
    if (itemRemovedStreamController != null) {
      itemRemovedStreamController.add(new MenuSelectionEvent(
          MenuSelectionEvent.MENU_ITEM_DELETED, this, item, null));
    }
    if (removeEmptyParent) {
      parents.forEach((MenuItem parent) {
        if(_graph.isLeaf(parent)) {
          _removeFromGraph(parent, removeEmptyParent);
        }
      });
    }
    return item;
  }
}

class ListMenuModel extends Object with MenuModelMixin
    implements MenuModel {
  StreamController<MenuSelectionEvent> itemRemovedStreamController;

  ListMenuModel();

  ListMenuModel.fromList(List items) {
    _processList(items, []);
    init(itemListProvider.items.toList());
  }

  Iterable<MenuItem> get items => itemListProvider.items;

  int get height => 1;
  bool get isLinear => true;

  bool hasParent(MenuItem item) => false;
  bool isLeaf(MenuItem item) => true;
  Iterable getAncestors(MenuItem item) => const[];
  Iterable getDescendants(MenuItem item) => const[];
  Iterable getChildren(MenuItem item) => const[];

  Iterable get roots => filteredItems;

  void clear() {
    itemListProvider.clear();
    _childrenMap.clear();
    _roots.clear();
    reset();
    _updateFilteredItems();
  }

  void addAll(Iterable<MenuItem> items) {
    itemListProvider.addAll(items);
    filteredItems.addAll(items);
    _updateFilteredItems();
  }

  MenuItem add(MenuItem item) {
    itemListProvider.add(item);
    filteredItems.add(item);
    _updateFilteredItems();
    return item;
  }

  MenuItem remove(MenuItem item) {
    if (itemRemovedStreamController != null) {
      itemRemovedStreamController.add(new MenuSelectionEvent(
          MenuSelectionEvent.MENU_ITEM_DELETED, this, item, null));
    }
    itemListProvider.remove(item);
    filteredItems.remove(item);
    _updateFilteredItems();
    return item;
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
