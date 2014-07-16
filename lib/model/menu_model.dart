library menu_model;

import 'dart:async';

import '../graph/graph.dart';
import '../event/menu_selection_event.dart';

part 'menu_selection_model.dart';

/// Returns the label template for the [item] for the [selected] mode.
typedef String LabelTemplateMaker(MenuItem item, bool selected);

/// Returns the label string for the [component].
typedef String LabelMaker<T>(T component);

/// Performs search based item list generation.
typedef Future<Map<T, T>> ItemsGetter<T>(String query);

/// Typically inserts more items to the given list.
typedef Iterable<T> ItemListEnricher<T>(Iterable<T> items);

/// Typically removes items from the given list.
typedef Iterable<T> ItemListFilter<T>(Iterable<T> items);

String defaultLabelMaker(component) => component.toString();

class MenuModelFactory<T> {
  MenuModel<T> createModel({bool linear: false, bool dynamic: false,
    LabelMaker labelMaker: defaultLabelMaker}) =>
        new MenuModel(linear: linear, dynamic: dynamic,
            labelMaker: labelMaker);

  MenuModel<T>
    createStaticTreeModel({LabelMaker labelMaker: defaultLabelMaker}) =>
        new MenuModel(linear: false, dynamic: false,
            labelMaker: labelMaker);

  MenuModel<T>
    createDynamicTreeModel({LabelMaker labelMaker: defaultLabelMaker}) =>
        new MenuModel(linear: false, dynamic: true,
            labelMaker: labelMaker);

  MenuModel<T>
    createStaticListModel({LabelMaker labelMaker: defaultLabelMaker}) =>
        new MenuModel(linear: true, dynamic: false,
            labelMaker: labelMaker);

  MenuModel<T>
    createDynamicListModel({LabelMaker labelMaker: defaultLabelMaker}) =>
        new MenuModel(linear: true, dynamic: true,
            labelMaker: labelMaker);
}

List<String> getAncestry(MenuItem item) {
  List<String> ancestry = <String>[];
  MenuItem curNode = item._parent;
  while (curNode != null) {
    ancestry.add(curNode.label);
    curNode = curNode._parent;
  }
  return ancestry;
}

String getAncestryString(MenuItem item) =>
  getAncestry(item).reversed.join(' &gt; ');

/**
 * Defines the interface needed to drive the hierarchy as well as its
 * selection/expansion/filter user operations.
 */
abstract class MenuModel<T> {
  /// Returns the label for the [item].
  LabelTemplateMaker get makeLabelTemplate;

  /// The placeholder text.
  String placeholder;

  /// Whether all items are leaves.
  bool get isLinear;

  /// The top level items.
  Iterable<MenuItem<T>> get roots;
  Iterable<MenuItem<T>> get filteredItems;

  MenuItem<T> getMenuItem(T component);

  /// Searches for items in the backend, or filters the existing items
  /// based on the filter mode and the given text.
  void set search(String inputText);

  /// Adds an empty menu item at the beginning of the item list, so that
  /// the user can select the empty menu item to deselect the previous
  /// selection.
  bool showDeselectOption;

  /// Initialize the hierarchy according to the [child, parent] map
  /// represented by [childToParentMap].
  void init(Map<T, T> childToParentMap);

  /// Applies the standard and user defined filters and enrichers on the
  /// master list of items and builds the filtered items from scratch.
  void reset();

  /// Clears the menu items.
  void clear();

  /// Applies the [visitor] to the root, and recurses down to root's children
  /// if the expansionSet contains the root.
  void visitExpandedNodes(MenuItem<T> root, Set<MenuItem<T>> expansionSet,
                          Function visitor);

  /// Determines whether the given item has a parent
  bool hasParent(MenuItem<T> item);

  /// Determines whether the given item is a leaf or has children.
  bool isLeaf(MenuItem<T> item);

  /// Returns the proper ancestors of [item].
  Iterable getAncestors(MenuItem<T> item);

  /// Returns the proper descendants of [item].
  Iterable getDescendants(MenuItem<T> item);

  /// Returns the immediate children of [item].
  Iterable getChildren(MenuItem<T> item);

  /// Registers/Unregisters the user defined filters and enrichers.
  void registerUserDefinedFilter(String name,
                                 ItemListFilter<MenuItem<T>> filter);
  void unregisterUserDefinedFilter(String name,
                                   ItemListFilter<MenuItem<T>> filter);
  void registerUserDefinedEnricher(String name,
                                   ItemListFilter<MenuItem<T>> enricher);
  void unregisterUserDefinedEnricher(String name,
                                     ItemListFilter<MenuItem<T>> enricher);

  /// Notifies the menu controller about the model modifications.
  /// Menu controller, which keeps track of the selection and expansion
  /// states of the items, updates its book keeping data structures while
  /// reacting to model changes.
  Stream<MenuSelectionEvent> onModelModified();

  /// Factory constructors
  factory MenuModel({bool linear: true, bool dynamic: true,
        LabelMaker labelMaker: defaultLabelMaker}) {
      HierarchicalItemListProvider<T> itemListProvider = dynamic ?
          new _SearchBasedHierarchicalItemListProvider<T>(labelMaker) :
              new _FilterBasedHierarchicalItemListProvider<T>(labelMaker);
      MenuModel menuModel;
      if (linear) {
        menuModel = new _ListMenuModel<T>(itemListProvider);
      } else {
        menuModel = new _TreeMenuModel<T>(itemListProvider);
      }
      return menuModel;
  }
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
 *
 * To create a menu item for 'Triangle':
 *    MenuItem item =
 *       new MenuItem(['Shape','Closed shape','Polygon','Triangle']);
 *
 * To add the menu item to the HierarchicalMenuModel:
 *    model.add(item);
 */
class MenuItem<T> implements Comparable {
  /// MenuItem that can be used to deselect the existing selection.
  static final MenuItem GHOST_ITEM =
      new MenuItem([''], (_) => '').._ghost = true;

  T _component;
  MenuItem<T> _parent;

  final String _label;
  int _ordinal = 0;

  /// User remarks text, collected during the selection process if
  /// the [collectRemarks] flag is set.  Useful for menu items that
  /// represent generic options such as "Other" or "None of the above",
  /// that usually accompany a user entered free form text as a remark.
  /// Basically, the remarks field will be used as an 'ng-model' for
  /// the input text box to collect user text.
  String remarks = '';
  bool collectRemarks = false;

  /// Does not contribute to selected items. Meant for deselection.
  bool _ghost = false;

  MenuItem(List<T> components, LabelMaker getLabel) :
    this._label = getLabel(components.last) {
    assert(components != null && components.isNotEmpty);
    _component = components.last;
    _parent = components.length < 2 ? null :
        new MenuItem(components.sublist(0, components.length-1), getLabel);
  }

  int get hashCode {
    int hash = 17;
    hash = hash * 37 + _component.hashCode;
    if (_parent != null) {
      hash = hash * 37 + _parent.hashCode;
    }
    return hash;
  }

  bool operator==(MenuItem<T> other) => other != null &&
      _component == other._component && _parent == other._parent;

  T get component => _component;

  int get depth => (_parent == null) ? 1 : _parent.depth + 1;

  bool get ghost => _ghost;

  String get label => _label;

  bool filter(String trimmedLowerCaseString) =>
      label.toLowerCase().contains(trimmedLowerCaseString);

  String toString() => label;

  int compareTo(MenuItem other) => _ordinal.compareTo(other._ordinal);
}

/**
 * Mixin to share the common functionality between the two
 * [MenuModel] variations, namely:
 *     1. [TreeMenuModel]
 *     2. [ListMenuModel]
 */
abstract class MenuModelMixin<T> {
  final Graph<MenuItem<T>> _graph = new Graph<MenuItem<T>>();
  final Set<MenuItem<T>> _filteredItems = new Set<MenuItem<T>>();
  final List<MenuItem<T>> _roots = <MenuItem<T>>[];
  final Map<MenuItem<T>, List<MenuItem<T>>> _childrenMap =
      <MenuItem<T>, List<MenuItem<T>>>{};
  final HierarchicalItemListProvider<T> _itemListProvider;
  StreamController<MenuSelectionEvent> modelModifiedStreamController;
  String _search;
  List<MenuItem<T>> filteredItems = [];
  bool showDeselectOption = false;
  String placeholder;
  bool _searchInProgress = false;

  /// User defined filters and enrichers, if any, are applied to the original
  /// item list each time the 'filteredItems' getter is called.  User defined
  /// filters and enrichers can be registered/unregistered by the clients as
  /// appropriate to their needs.
  final Map<String, ItemListFilter<MenuItem<T>>> _userDefinedFilterMap =
      <String, ItemListFilter<MenuItem<T>>>{};
  final Map<String, ItemListEnricher<MenuItem<T>>> _userDefinedEnricherMap =
      <String, ItemListEnricher<MenuItem<T>>>{};

  MenuModelMixin(this._itemListProvider);

  String get search => _search;

  /// If the itemListProvider is in filterMode, then apply
  /// the given text as a filter. Otherwise, apply the given
  /// text as a search string to fetch new items.
  set search(String text) {
    _search = text;
    clearSelections();
    if (_searchInProgress) {
      return;
    }
    if (_itemListProvider._filterMode) {
      // apply the primary filter
      filter();
    } else {
      _searchInProgress = true;
      // search mode, get the dynamic item list.
      _itemListProvider.getItems(text).then(init).then((_) {
          _searchInProgress = false;
          // Do the search again on any user text that has been
          // entered during the previous search operation.
          if (_search != text) {
            search = _search;
          }
      });
    }
  }

  void dispose() {
    if (modelModifiedStreamController != null) {
      modelModifiedStreamController.close();
    }
  }

  _updateFilteredItems() {
    Iterable<MenuItem<T>> items = _filteredItems;

    // Apply the userDefinedFilters, if any, on the _filteredItems.
    _userDefinedFilterMap.values
        .forEach((ItemListFilter<MenuItem<T>> filter) =>
            items = filter(items));

    // Apply the userDefinedEnrichers, if any, on the above results.
    _userDefinedEnricherMap.values
        .forEach((ItemListEnricher<MenuItem<T>> enricher) =>
            items = enricher(items));

    // Apply depth first search order to the items.
    Iterable<MenuItem<T>> sortedItems = _preorderSort(items);

    // Apply the primaryEnricher to the sorted items and update the
    // filteredItems with the result.
    filteredItems = _primaryEnricher(sortedItems);
  }

  void registerUserDefinedFilter(String name,
                                 ItemListFilter<MenuItem<T>> filter) {
    _userDefinedFilterMap[name] = filter;
    _updateFilteredItems();
  }

  void unregisterUserDefinedFilter(String name,
                                   ItemListFilter<MenuItem<T>> filter) {
    _userDefinedFilterMap.remove(name);
    _updateFilteredItems();
  }

  void registerUserDefinedEnricher(String name,
                                   ItemListFilter<MenuItem<T>> enricher) {
    _userDefinedEnricherMap[name] = enricher;
    _updateFilteredItems();
  }

  void unregisterUserDefinedEnricher(String name,
                                     ItemListFilter<MenuItem<T>> enricher) {
    _userDefinedEnricherMap.remove(name);
    _updateFilteredItems();
  }

  /// Applies the MenuModel specific filtering to the given item list.
  Iterable<MenuItem<T>> _primaryFilter (Iterable<MenuItem<T>> items) {
    if (!_itemListProvider._filterMode || search == null || search.isEmpty) {
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
  Iterable<MenuItem<T>> _primaryEnricher(Iterable<MenuItem<T>> items) {
    List<MenuItem<T>> processedItems = items.toList();
    if (showDeselectOption) {
      // Add a 'ghost' item at index 0 to denote 'deselectOption' when
      // 'showDeselectOption' is turned on.
      processedItems.insert(0, MenuItem.GHOST_ITEM);
    }
    return processedItems;
  }

  void clear() {
    _itemListProvider._clear();
    _childrenMap.clear();
    _roots.clear();
    _graph.clear();
    _filteredItems.clear();
    reset();
  }

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
    Iterable<MenuItem<T>> unfilteredItems = _itemListProvider._items;
    _filteredItems.clear();
    _filteredItems.addAll(_primaryFilter(unfilteredItems));
    _updateFilteredItems();
  }

  Stream<MenuSelectionEvent> onModelModified() {
    if (modelModifiedStreamController == null) {
      modelModifiedStreamController =
          new StreamController<MenuSelectionEvent>.broadcast();
    }
    return modelModifiedStreamController.stream;
  }

  Iterable getChildren(MenuItem<T> item);

  /// Initialize the hierarchy according to the [child, parent] map
  /// represented by [childToParentMap]..
  void init(Map<T, T> childToParentMap) {
    clear();
    _itemListProvider.init(childToParentMap);
    _addAll(_itemListProvider._items);
    reset();
  }

  void _addAll(Iterable<MenuItem<T>> items) => items.forEach(_add);

  MenuItem<T> _add(MenuItem<T> item) {
    _addToGraph(item);
    return item;
  }

  MenuItem<T> _addToGraph(MenuItem<T> item) {
    MenuItem<T> parent = item._parent;
    if (parent != null) {
      _graph.addEdge(parent, item);
    } else {
      _graph.addNode(item);
    }
    return item;
  }

  MenuItem<T> _removeFromGraph(MenuItem<T> item) {
    Iterable<MenuItem<T>> parents = _graph.getParents(item);
    _graph.removeNode(item);
    if (modelModifiedStreamController != null) {
      modelModifiedStreamController.add(new MenuSelectionEvent(
          MenuSelectionEvent.MENU_ITEM_DELETED, this, item, null));
    }
    return item;
  }

  /// Applies the depth first search order to the [items].
  Iterable<MenuItem<T>> _preorderSort(Iterable<MenuItem<T>> items) {
    List<MenuItem<T>> sortedItems = <MenuItem<T>>[];
    _graph.getRoots().forEach((MenuItem<T> root) {
      if (items.contains(root)) {
        sortedItems.add(root);
      }
      sortedItems.addAll(_graph.getDescendants(root).where(items.contains));
    });

    // Update the ordinal value of each item for sorting of the selections.
    int ordinal = 0;
    sortedItems.forEach((MenuItem<T> item) => item._ordinal = ordinal++);
    return sortedItems;
  }

  /// Applies the [visitor] to the root, and recurses down to root's children
  /// if the expansionSet contains the root.
  void visitExpandedNodes(MenuItem<T> root, Set<MenuItem<T>> expansionSet,
                          Function visitor) {
    visitor(root);
    if (expansionSet.contains(root)) {
      getChildren(root).forEach((MenuItem<T> child) =>
        visitExpandedNodes(child, expansionSet, visitor));
    }
  }

  MenuItem getMenuItem(T component) => _itemListProvider.getMenuItem(component);
}

/**
 * Represents a hierarchy to be selected/expanded non-linearly.
 */
class _TreeMenuModel<T> extends MenuModelMixin
    implements MenuModel<T> {
  LabelTemplateMaker _makeLabelTemplate;

  _TreeMenuModel(HierarchicalItemListProvider ilp) : super(ilp) {
    // Default template
    _makeLabelTemplate = (MenuItem<T> item, bool selected) =>
        '<span class="menu-item-container">'
          '<span class="menu-item-name text-not-selectable">'
            '${item.label}'
          '</span>'
        '</span>';
    registerUserDefinedEnricher('includeAncestors', includeAncestors);
  }

  _TreeMenuModel.withItemLabelMaker(HierarchicalItemListProvider ilp,
      this._makeLabelTemplate) : super(ilp) {
    registerUserDefinedEnricher('includeAncestors', includeAncestors);
  }

  LabelTemplateMaker get makeLabelTemplate => _makeLabelTemplate;
  set makeLabelTemplate (LabelTemplateMaker templateMaker) =>
      _makeLabelTemplate = templateMaker;

  int get depth =>
    _graph.nodes.fold(1, (int prev, MenuItem<T> item) =>
        prev < item.depth ? item.depth : prev);

  bool get isLinear => depth == 1;

  bool hasParent(MenuItem<T> item) => _graph.getParents(item).isNotEmpty;

  bool isLeaf(MenuItem<T> item) => _graph.isLeaf(item);

  Iterable<MenuItem<T>> getAncestors(MenuItem<T> item) =>
      _graph.getAncestors(item);

  Iterable<MenuItem<T>> getDescendants(MenuItem<T> item) =>
      _graph.getDescendants(item);

  Iterable<MenuItem<T>> getChildren(MenuItem<T> item) {
    List children = _childrenMap[item];
    if (children == null) {
      children = <MenuItem<T>>[];
      _childrenMap[item] = children;
    }
    children.clear();
    children.addAll(_graph.getChildren(item).where(filteredItems.contains));
    return children;
  }

  Iterable<MenuItem<T>> get roots {
    _roots.clear();
    _roots.addAll(_graph.getRoots().where(filteredItems.contains));
    return _roots;
  }

  Iterable<MenuItem<T>> includeAncestors(Iterable<MenuItem<T>> items) {
    Set<MenuItem<T>> result = new Set<MenuItem<T>>();
    items.forEach((MenuItem<T> item){
      result.addAll(_graph.getAncestors(item));
      result.add(item);
    });
    return result;
  }
}

/**
 * Represents a flat list of hierarchical menu items formed by
 * a depth-first tree traversal.
 */
class _ListMenuModel<T> extends MenuModelMixin
    implements MenuModel<T> {
  LabelTemplateMaker _makeLabelTemplate;

  _ListMenuModel(HierarchicalItemListProvider ilp) : super(ilp) {
    // Default template.
    _makeLabelTemplate = (MenuItem<T> item, bool selected) =>
        '<span class="menu-item-container">'
        +
          '<span class="menu-item-name  text-not-selectable">'
            '${item.label} </span>'
        + (getAncestry(item).isNotEmpty ?
          '<span class="menu-item-ancestry text-not-selectable">'
            '${getAncestryString(item)}</span>' : '')
        +
        '</span>';
  }

  _ListMenuModel.withItemLabelMaker(HierarchicalItemListProvider ilp,
      this._makeLabelTemplate) : super(ilp);

  LabelTemplateMaker get makeLabelTemplate => _makeLabelTemplate;

  int get depth => 1;

  bool get isLinear => true;

  bool hasParent(MenuItem<T> item) => false;

  bool isLeaf(MenuItem<T> item) => true;

  Iterable<MenuItem<T>> getAncestors(MenuItem<T> item) => const [];

  Iterable<MenuItem<T>> getDescendants(MenuItem<T> item) => const [];

  Iterable<MenuItem<T>> getChildren(MenuItem<T> item) => const [];

  Iterable<MenuItem<T>> get roots => filteredItems;
}

/// A stateful abstraction that can either filter an existing item list,
/// or generate a brand new item list, based on the user input and its
/// mode of operation.
abstract class HierarchicalItemListProvider<T> {
  final List<MenuItem<T>> _items = <MenuItem<T>>[];
  final Map<T, MenuItem<T>> _componentToMenuItem = <T, MenuItem<T>>{};
  final LabelMaker<T> _getLabel;

  HierarchicalItemListProvider.withLabelMaker(this._getLabel);

  bool get _filterMode;

  void _clear() {
    _items.clear();
  }

  /// Initialize the hierarchy according to the [child, parent] map
  /// represented by [childToParentMap].
  void init(Map<T, T> childToParentMap) {
    void _getAncestry(T item, List<T> ancestors) {
      T parent = childToParentMap[item];
      if (parent != null) {
        _getAncestry(parent, ancestors);
      }
      ancestors.add(item);
    }
    _clear();
    childToParentMap.forEach((T child, T parent) {
      List<T> components = <T>[];
      _getAncestry(child, components);
      MenuItem item = new MenuItem<T>(components, _getLabel);
      _componentToMenuItem[item.component] = item;
      _add(item);
    });
  }

  int _remove(MenuItem<T> item) {
    int removalIndex = _items.indexOf(item);
    if (removalIndex != -1) {
      _items.removeAt(removalIndex);
    }
    return removalIndex;
  }

  void _add(MenuItem<T> item) {
    if (!_items.contains(item)) {
       _items.add(item);
    }
  }

  void _addAll(Iterable<MenuItem<T>> items) {
    for (MenuItem<T> item in items) {
      _add(item);
    }
  }

  Future<Map<T, T>> getItems(String inputText);

  Iterable<MenuItem<T>> getMenuItems(Iterable<T> components) =>
    components.map((T component) => _componentToMenuItem[component]);

  MenuItem<T> getMenuItem(T component) => _componentToMenuItem[component];

  /// Factory constructor
  factory HierarchicalItemListProvider({bool dynamic: false,
    LabelMaker labelMaker: null}) => dynamic ?
        new _SearchBasedHierarchicalItemListProvider<T>(labelMaker) :
            new _FilterBasedHierarchicalItemListProvider<T>(labelMaker);

}

/// An ItemListProvider that works in FILTER_MODE.
class _FilterBasedHierarchicalItemListProvider<T>
    extends HierarchicalItemListProvider {
  final bool _filterMode = true;

  _FilterBasedHierarchicalItemListProvider(LabelMaker getLabel) :
    super.withLabelMaker(getLabel);

  Future<Map<T, T>> getItems(String inputText) {
    return new Future.value(_items.map((MenuItem item) => item.component));
  }
}

/// An empty ItemListProvider that works in SEARCH_MODE.
/// Subclasses must set the 'searchForItems' to appropriate
/// Function to perform search based item list generation.
class _SearchBasedHierarchicalItemListProvider<T>
    extends HierarchicalItemListProvider {
  final bool _filterMode = false;
  ItemsGetter<T> _searchForItems;

  _SearchBasedHierarchicalItemListProvider(LabelMaker getLabel) :
    super.withLabelMaker(getLabel);

  set itemsGetter(ItemsGetter<T> getter) => _searchForItems = getter;

  Future<Map<T, T>> getItems(String inputText) =>
      _searchForItems == null ? new Future.value(<T, T>{}) :
        _searchForItems(inputText);
}
