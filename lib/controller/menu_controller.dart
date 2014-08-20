library menu_controller;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';

import '../model/menu_model.dart';
import '../event/menu_selection_event.dart';

/**
 * A controller to manage and notify selection and expansion state
 * of a hierarchical menu model.
 *
 * The selections can be made either using the [MenuSelectionEvent] messages
 * through the [MenuSelectionEventMediator], or direct calls to methods such
 * as:
 *    - toggleSelection(item)
 *    - toggleExpansion(item)
 *
 * The selections are notified to the subscribers through
 * the [MenuSelectionEventMediator].
 *
 *
 * Inputs:
 *    menu-model:
 *        The [HierarchicalMenuModel] that represents the menu hierarchy.
 *
 *    selection-options:
 *        The [MenuSelectionOptions].
 *
 *    searchable:
 *        Whether to show the search input box. Defaults to false.
 *
 *    popup-mode:
 *        Whether this panel is being used in a popup. Defaults to false.
 *        In popup mode, and multi-select mode combination, the menu includes
 *        a toolbar at the bottom that allows the user to dismiss the popup
 *        by clicking the 'CLOSE' button.
 *
 *  Sample usage:
 *    <div class="notes-panel">
 *      <heading>
 *        <h2>Hierarchical Picker Demo</h2>
 *      </heading>
 *      <div class="card notes-card">
 *        <hierarchical-menu-controller
 *            menu-model="ctrl.menuModel"
 *            selection-model="ctrl.selectionModel"
 *            searchable="true"
 *            popup-mode="false>
 *          <hierarchical-menu
 *              class="flex-column-container"
 *              items="ctrl.menuModel.roots">
 *          </hierarchical-menu>
 *        </hierarchical-menu-controller>
 *      </div>
 *    </div>
 */
@Component(
  selector: 'hierarchical-menu-controller',
  templateUrl: 'packages/hierarchical/controller/'
               'menu_controller.html',
  cssUrl: 'packages/hierarchical/controller/'
          'menu_controller.css',
  publishAs: 'ctrl',
  visibility: Directive.CHILDREN_VISIBILITY,
  map: const {
    'menu-model': '=>!model',
    'selection-model': '=>!selectionModel',
    'searchable': '=>!searchable',
    'popup-mode': '=>popupMode'
  }
)
class HierarchicalMenuController implements AttachAware, DetachAware {
  final Set _selectionSet = new Set();
  final Set _expansionSet = new Set();
  final List<MenuItem> _visibleItems = <MenuItem>[];
  MenuItem _markedItem;

  MenuModel model;
  MenuSelectionModel selectionModel;
  bool searchable = false;
  bool popupMode = false;

  StreamSubscription<MenuSelectionEvent> _mediatorSubscription;
  StreamSubscription<MenuSelectionEvent> _modelSubscription;

  @override
  void attach() {
    _createSubscription();
    _computeVisibleItems();
  }

  @override
  void detach() {
    _cancelSubscription();
    if (selectionModel != null) {
      selectionModel.close();
    }
    _selectionSet.clear();
    _expansionSet.clear();
  }

  MenuSelectionEventMediator get mediator => selectionModel.mediator;

  void _createSubscription() {
    if (mediator != null) {
      _mediatorSubscription = mediator.onSelectionEvent()
          .listen((MenuSelectionEvent event) {
        switch(event.type) {
          case MenuSelectionEvent.SET_SELECTION:
            setSelection(event.data);
            return;
          case MenuSelectionEvent.DESELECT:
            toggleSelection(event.data);
            return;
          case MenuSelectionEvent.MENU_ITEM_DELETED:
            _selectionSet.remove(event.data);
            _expansionSet.remove(event.data);
            notifySelections();
            return;
          case MenuSelectionEvent.MARK_NEXT_MENU_ITEM:
            if (_visibleItems.isNotEmpty) {
              markItemForSelectionByIndex(getForwardSelectionIndex());
            }
            return;
          case MenuSelectionEvent.MARK_PREV_MENU_ITEM:
            if (_visibleItems.isNotEmpty) {
              markItemForSelectionByIndex(getBackwardSelectionIndex());
            }
            return;
          case MenuSelectionEvent.SELECT_MARKED_MENU_ITEM:
            if (multiSelect) {
              toggleSelection(_markedItem);
            } else if (!isSelected(_markedItem) && commitSelection()) {
              notifySelections();
            }
            return;
        }
      });
    }
    if (model != null) {
      _modelSubscription = model.onModelModified()
          .listen((MenuSelectionEvent event) {
        switch(event.type) {
          case MenuSelectionEvent.SET_SELECTION:
            setSelection(event.data);
            return;
          case MenuSelectionEvent.MENU_ITEM_DELETED:
            _selectionSet.remove(event.data);
            _expansionSet.remove(event.data);
            notifySelections();
            return;
        }
      });
    }

    Completer<Iterable<MenuItem>> completer = new Completer();
    completer.future.then((Iterable<MenuItem> selection){
      setSelection(selection);
    });

    mediator.post(new MenuSelectionEvent(
        MenuSelectionEvent.GET_CURRENT_SELECTION, this, null, completer));
  }

  void _cancelSubscription() {
    if (_mediatorSubscription != null) {
      _mediatorSubscription.cancel();
    }
    if (_modelSubscription != null) {
      _modelSubscription.cancel();
    }
  }

  bool isSelected(item) => _selectionSet.contains(item);
  bool isExpanded(item) => _expansionSet.contains(item);

  void toggleExpansion(item) {
    _expandCollapse(item, isExpanded(item));
    _computeVisibleItems();
  }

  void toggleSelection(item) {
    setSelectedState(item, !isSelected(item));
  }

  void setSelectedState(item, bool state) {
    if (state == true) {
      _select(item);
    } else {
      _unselect(item);
    }
    notifySelections();
  }

  void _expandCollapse(MenuItem item, bool collapse) {
    collapse ? _expansionSet.remove(item) : _expansionSet.add(item);
    if (model != null && collapse) {
      _expansionSet.removeAll(model.getDescendants(item));
    }
  }

  void _computeVisibleItems() {
    _visibleItems.clear();
    roots.forEach((MenuItem root) {
      model.visitExpandedNodes(root, _expansionSet, _visibleItemVisitor);
    });
  }

  void _visibleItemVisitor(MenuItem item) {
    _visibleItems.add(item);
  }

  void notifySelections() {
    mediator.post(new MenuSelectionEvent(MenuSelectionEvent.SELECTION_CHANGED,
        this, getSelections(), null));
  }

  void _computeSelectedItems() {
    _visibleItems.clear();
    roots.forEach((MenuItem root) {
      model.visitExpandedNodes(root, _expansionSet, _visibleItemVisitor);
    });
  }

  /// Sets the initial selection. Does not trigger the SELECTION_CHANGED event.
  void setSelection(Iterable<MenuItem> items) {
    _selectionSet.clear();
    if (items != null) {
      items.forEach(_select);
    }
  }

  bool _select(MenuItem item) {
    if (!selectionModel.multiSelect) {
      _selectionSet.clear();
    }
    if (isSelected(item)) {
      return false;
    }
    // Ghost item is used to 'deselect' previous selection.
    // So, return true without actually adding it to the
    // selection set.
    if (item.ghost) {
      return true;
    }
    _selectionSet.add(item);

    /// Select the whole subtree if the subtreeSelection is enabled.
    if (selectionModel.subtreeSelection) {
      _selectionSet.addAll(model.getDescendants(item));
    }
    return true;
  }

  void _unselect(MenuItem item) {
    _selectionSet.remove(item);
    /// Unselect the whole subtree if the subtreeSelection is enabled.
    if (selectionModel.subtreeSelection) {
      _selectionSet.removeAll(model.getDescendants(item));
    }
  }

  bool isVisible(item) => model != null && item != null &&
      model.getAncestors(item).every(isExpanded);

  Iterable getSelections() {
    List<MenuItem> result = _selectionSet.toList();
    result.sort();
    return result;
  }

  void clearSelections() {
    _selectionSet.clear();
  }

  void selectAll() {
      if (_visibleItems.isEmpty) {
        _computeVisibleItems();
      }
    _visibleItems.forEach((MenuItem item) => _select(item));
    notifySelections();
  }

  void selectNone() {
    clearSelections();
    notifySelections();
  }

  bool hasParent(MenuItem item) => model != null ?
      model.hasParent(item) : false;

  bool isLeaf(MenuItem item) => model != null ? model.isLeaf(item) :
      false;

  Iterable getAncestors(MenuItem item) => model != null ?
      model.getAncestors(item) : const[];

  Iterable children(MenuItem parent) => model != null ?
      model.getChildren(parent) : const[];

  Iterable get roots => model != null ? model.roots : const[];

  markItemForSelection(MenuItem item) => _markedItem = item;

  bool isActive (MenuItem item) => _markedItem == item;

  bool get multiSelect => selectionModel != null && selectionModel.multiSelect;

  void markItemForSelectionByIndex(int index) {
    if (index < _visibleItems.length) {
      _markedItem = _visibleItems[index];
    }
  }

  /// Returns the index of the item in the menu that gets selected if the user
  /// navigates 'forward' in the list using the down arrow key.
  int getForwardSelectionIndex() {
    int index = _visibleItems.indexOf(_markedItem);
    if (index < 0) {
      return 0;
    }
    index++;
    if (index >= _visibleItems.length) {
      index = _visibleItems.length -1;
    }
    return index;
  }

  /// Returns the index of the item in the menu that gets selected if the user
  /// navigates 'backward' in the list using the up arrow key.
  int getBackwardSelectionIndex() {
    int index = _visibleItems.indexOf(_markedItem);
    if (index < 0) {
      return 0;
    }
    index--;
    if (index < 0 || index >= _visibleItems.length) {
      index = 0;
    }
    return index;
  }

  /// Commits the currently marked item as 'selected' item, and returns whether
  /// there was a currently marked item.
  bool commitSelection() => isVisible(_markedItem) && _select(_markedItem);

  bool get isLinear => model != null && model.isLinear;
  bool get showSelectAll => selectionModel != null &&
      selectionModel.multiSelect && selectionModel.includeSelectAll &&
      model != null && model.roots.isNotEmpty;
  bool get showFooter => popupMode && selectionModel != null &&
      selectionModel.multiSelect;

  void onMouseDownInput(MouseEvent event) {
    event.stopPropagation();
    event.preventDefault();
  }

  void onKeyDown(KeyboardEvent event) {
    if (_visibleItems.isEmpty) {
      _computeVisibleItems();
    }
    switch (event.keyCode) {
      case KeyCode.DOWN:
      case KeyCode.UP:
        event.stopPropagation();
        event.preventDefault();
        return;
      case KeyCode.ESC:
        close();
        return;
   }
  }

  /// Navigate and also prevent the scrollbar from processing the key press,
  /// which would distract by moving the viewport.
  void onKeyUp(KeyboardEvent event) {
    switch (event.keyCode) {
      case KeyCode.DOWN:
        if (_visibleItems.isNotEmpty) {
          markItemForSelectionByIndex(getForwardSelectionIndex());
        }
        event.stopPropagation();
        event.preventDefault();
        return;
      case KeyCode.UP:
        if (_visibleItems.isNotEmpty) {
          markItemForSelectionByIndex(getBackwardSelectionIndex());
        }
        event.stopPropagation();
        event.preventDefault();
        return;
      case KeyCode.ENTER:
        event.stopPropagation();
        event.preventDefault();
        if (multiSelect) {
          toggleSelection(_markedItem);
        } else if (!isSelected(_markedItem) && commitSelection()) {
          notifySelections();
        }
      }
  }

  void close() {
    mediator.post(new MenuSelectionEvent(
        MenuSelectionEvent.SELECTION_ENDED, this, null, null));
  }
}
