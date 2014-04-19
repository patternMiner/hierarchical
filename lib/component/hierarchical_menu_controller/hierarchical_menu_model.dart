part of hierarchical_menu_controller;

/**
 * Defines the interface needed to drive the hierarchy as well as its
 * selection/expansion/filter user operations.
 *
 * Linear menus use the 'items' getter as the main source of menu items,
 *
 */
abstract class HierarchicalMenuModel {

  /// The model is linear if all items are leaves.
  bool get isLinear;

  /// The top level items.
  Iterable<MenuItem> get roots;

  /// Searches for items in the backend, or filters the existing items
  /// based on the filter mode and the given text.
  void set search(String inputText);

  /// Adds an empty menu item at the beginning of the item list, so that
  /// the user can select the empty menu item to deselect the previous
  /// selection.
  void set showDeselectOption(bool show);

  /// Initialize the itemListProvider with the given items.
  void init(Iterable<MenuItem> items);

  /// Clears the model to forget the menu items and start from scratch.
  void clear();

  /// Performs a depth-first-search to flatten the hierarchy in to a
  /// linear list.
  void dfs(MenuItem root, Set expansionSet, Function visitor);

  /// Adds the given items to the model.
  void addAll(Iterable<MenuItem> items);

  /// Adds the given items to the model.
  MenuItem add(MenuItem item);

  /// Removes the given items from the model.
  MenuItem remove(MenuItem item);

  /// Determines whether the given item has a parent
  bool hasParent(MenuItem item);

  /// Determines whether the given item is a leaf or has children.
  bool isLeaf(MenuItem item);

  /// Returns all the ancestors of the given item, if any.
  Iterable getAncestors(MenuItem item);

  /// Returns all the descendants of the given item, if any.
  Iterable getDescendants(MenuItem item);

  /// Returns just the immediate children of the given item.
  Iterable getChildren(MenuItem item);

  /// Registers/Unregisters the user defined filters and enrichers.
  void registerUserDefinedFilter(String name,
                                 ItemListFilter<MenuItem> filter);
  void unregisterUserDefinedFilter(String name,
                                   ItemListFilter<MenuItem> filter);
  void registerUserDefinedEnricher(String name,
                                   ItemListFilter<MenuItem> enricher);
  void unregisterUserDefinedEnricher(String name,
                                     ItemListFilter<MenuItem> enricher);

  /// Notifies the menu controller about the model modifications.
  Stream<MenuSelectionEvent> onModelModified();
}

/**
 * Represents the hierarchical path to a business object. The last
 * component of the path is the target business object, and the
 * remaining components represents the ancestry of the target.
 *
 * For example:
 *    The target business object 'Triangle' may have the path:
 *
 *        ['Shape']['Closed shape']['Polygon']['Triangle']
 *
 * Any two instances of [MenuItem] are considered "equal" if and only if
 * their component lists represents the same sequence of business objects.
 */
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

/**
 * Mixin to share the common functionality between the two
 * [HierarchicalMenuModelTreeMenuModel] variations, namely:
 *     1. [TreeMenuModel]
 *     2. [ListMenuModel]
 */
abstract class HierarchicalMenuModelMixin {
  final Set<MenuItem> _filteredItems = new LinkedHashSet<MenuItem>();
  final Set<MenuItem> _unfilteredItems = new LinkedHashSet<MenuItem>();
  final List<MenuItem> _roots = <MenuItem>[];
  final Map<MenuItem, List<MenuItem>> _childrenMap =
      <MenuItem, List<MenuItem>>{};
  StreamController<MenuSelectionEvent> modelModifiedStreamController;
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
    clearSelections();
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

  void clearSelections() {
    if (modelModifiedStreamController != null) {
      modelModifiedStreamController.add(new MenuSelectionEvent
          (MenuSelectionEvent.SET_SELECTION, this,[], null));
    }
  }

  /// Applies the primaryFilter to the original list of items.
  void filter() {
    _filteredItems.clear();
    _filteredItems.addAll(_primaryFilter(_unfilteredItems));
    processFilteredOutItems(_unfilteredItems.difference(_filteredItems));
    processFilteredInItems(_filteredItems);
    _updateFilteredItems();
  }

  processFilteredInItems(Iterable<MenuItem> filteredInItems);
  processFilteredOutItems(Iterable<MenuItem> filteredOutItems);

  Stream<MenuSelectionEvent> onModelModified() {
    if (modelModifiedStreamController == null) {
      modelModifiedStreamController =
          new StreamController<MenuSelectionEvent>.broadcast();
    }
    return modelModifiedStreamController.stream;
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

/**
 * Represents a hierarchy to be selected/expanded non-linearly.
 */
class TreeMenuModel extends Object with HierarchicalMenuModelMixin
    implements HierarchicalMenuModel {
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
  }

  void addAll(Iterable<MenuItem> items) {
    items.forEach((MenuItem item) => _addToGraph(item));
    itemListProvider.addAll(items);
    _unfilteredItems.addAll(items);
   reset();
  }

  MenuItem add(MenuItem item) {
    itemListProvider.add(_addToGraph(item));
    _unfilteredItems.add(item);
    reset();
    return item;
  }

  MenuItem remove(MenuItem item) {
    itemListProvider.remove(_removeFromGraph(item, false));
    _unfilteredItems.remove(item);
    reset();
    return item;
  }

  MenuItem _addToGraph(MenuItem item) {
    MenuItem parent = item.parent;
    if (parent != null) {
      _addToGraph(parent);
      _graph.addEdge(parent, item);
    } else {
      _graph.addNode(item);
    }
    return item;
  }

  MenuItem _removeFromGraph(MenuItem item, bool removeEmptyParent) {
    Iterable<MenuItem> parents = _graph.getParents(item);
    _graph.removeNode(item);
    if (modelModifiedStreamController != null) {
      modelModifiedStreamController.add(new MenuSelectionEvent(
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

  void processFilteredOutItems(Iterable<MenuItem> filteredOutItems) =>
    filteredOutItems.forEach((MenuItem item) => _removeFromGraph(item, true));

  void processFilteredInItems(Iterable<MenuItem> filteredInItems) =>
      filteredInItems.forEach((MenuItem item) => _addToGraph(item));
}

/**
 * Represents a flat list of hierarchical menu items formed by
 * a depth-first tree traversal.
 */
class ListMenuModel extends Object with HierarchicalMenuModelMixin
    implements HierarchicalMenuModel {
  StreamController<MenuSelectionEvent> modelModifiedStreamController;

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
    _filteredItems.clear();
    _unfilteredItems.clear();
    reset();
  }

  void addAll(Iterable<MenuItem> items) {
    itemListProvider.addAll(items);
    _unfilteredItems.addAll(items);
    reset();
  }

  MenuItem add(MenuItem item) {
    itemListProvider.add(item);
    _unfilteredItems.add(item);
    reset();
    return item;
  }

  MenuItem remove(MenuItem item) {
    if (modelModifiedStreamController != null) {
      modelModifiedStreamController.add(new MenuSelectionEvent(
          MenuSelectionEvent.MENU_ITEM_DELETED, this, item, null));
    }
    itemListProvider.remove(item);
    _unfilteredItems.remove(item);
    reset();
    return item;
  }

  void processFilteredOutItems(Iterable<MenuItem> filteredOutItems) {}
  void processFilteredInItems(Iterable<MenuItem> filteredInItems) {}
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
