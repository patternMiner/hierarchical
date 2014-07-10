library hierarchical_menu_controller;

import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'package:angular/angular.dart';

import '../../common/graph/graph.dart';

part 'hierarchical_menu_model.dart';
part 'menu_selection_event.dart';
part 'menu_selection_event_mediator.dart';

/**
 * A controller to manage and notify selections and expansions
 * of a hierarchical menu componet.
 *
 * The selections are notified through a [MenuSelectionEventMediator].
 *
 * Inputs:
 *    menu-model:
 *        The [HierarchicalMenuModel] that represents the menu hierarchy.
 *
 *    multi-select:
 *        Whether the multiple menu-items can be selected.
 *
 *    selection-mediator:
 *        The [MenuSelectionEventMediator] mediator.
 *
 *  Sample usage:
 *    <hierarchical-menu-controller multi-select="ctrl.multiSelect"
 *                                  selection-mediator="ctrl.mediator"
 *                                  menu-model="ctrl.model">
 *      <hierarchical-menu items="menuController.roots"></hierarchical-menu>
 *    </hierarchical-menu-controller>
 */
@Component(
  selector: 'hierarchical-menu-controller',
  templateUrl: '/packages/hierarchical/component/hierarchical_menu_controller'
               '/hierarchical_menu_controller.html',
  publishAs: 'menuController',
  visibility: Directive.CHILDREN_VISIBILITY,
  map: const {
    'menu-model': '=>!model',
    'multi-select': '=>!multiSelect',
    'selection-mediator': '=>!mediator'
  }
)
class HierarchicalMenuController implements AttachAware, DetachAware {
  final Set _selectionSet = new HashSet();
  final Set _expansionSet = new HashSet();
  final List<MenuItem> _visibleItems = <MenuItem>[];
  MenuItem _markedItem;

  HierarchicalMenuModel _model;
  MenuSelectionEventMediator _mediator;
  bool multiSelect = false;
  bool isInitialized = false;

  final Completer _modelCompleter = new Completer(),
            _mediatorCompleter = new Completer();

  StreamSubscription<MenuSelectionEvent> _mediatorSubscription;
  StreamSubscription<MenuSelectionEvent> _modelSubscription;

  HierarchicalMenuController() {
    Future.wait([_modelCompleter.future, _mediatorCompleter.future]).then((_) {
      _computeVisibleItems();
      _createSubscription();
      isInitialized = true;
    });
  }

  void attach() {
  }

  void detach() {
    _cancelSubscription();
    if (_model != null) {
      _model.clear();
    }
    _selectionSet.clear();
    _expansionSet.clear();
  }

  void set model (HierarchicalMenuModel m) {
    if (m != null) {
      _model = m;
      _modelCompleter.complete();
    }
  }

  HierarchicalMenuModel get model => _model;

  void set mediator (MenuSelectionEventMediator m) {
    if (m != null) {
      _mediator = m;
      _mediatorCompleter.complete();
    }
  }

  MenuSelectionEventMediator get mediator => _mediator;

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
          case MenuSelectionEvent.GET_CURRENT_SELECTION:
            if (event.completer != null) {
              event.completer.complete(getSelections());
            }
            return;
          case MenuSelectionEvent.MENU_ITEM_DELETED:
            _selectionSet.remove(event.data);
            _expansionSet.remove(event.data);
            notifySelections();
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
            notifySelections();
            return;
          case MenuSelectionEvent.MENU_ITEM_DELETED:
            _selectionSet.remove(event.data);
            _expansionSet.remove(event.data);
            notifySelections();
            return;
        }
      });
    }
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
    isSelected(item) ? _unselect(item) : _select(item);
    notifySelections();
  }

  void _expandCollapse(MenuItem item, bool collapse) {
    collapse ? _expansionSet.remove(item) : _expansionSet.add(item);
    if (model != null && collapse) {
      model.getDescendants(item).forEach((MenuItem descendant) =>
        _expansionSet.remove(descendant));
    }
  }

  void _computeVisibleItems() {
    _visibleItems.clear();
    roots.forEach((MenuItem root) {
      model.dfs(root, _expansionSet, _visibleItemVisitor);
    });
  }

  void _visibleItemVisitor(MenuItem item) {
    _visibleItems.add(item);
  }

  void notifySelections() {
    if (mediator != null) {
      mediator.post(new MenuSelectionEvent(MenuSelectionEvent.SELECTION_CHANGED,
          this, getSelections(), null));
    }
  }

  /// Sets the initial selection. Does not trigger the SELECTION_CHANGED event.
  void setSelection(Iterable<MenuItem> items) {
    _selectionSet.clear();
    if (items != null) {
      items.forEach((MenuItem item) => _select(item));
    }
  }

  bool _select(MenuItem item) {
    if (!multiSelect) {
      _selectionSet.clear();
    }
    if (isSelected(item)) {
      return false;
    }
    _selectionSet.add(item);
    if (model != null && multiSelect) {
      _selectionSet.addAll(model.getDescendants(item));
      _selectionSet.addAll(model.getAncestors(item));
    }
    return true;
  }

  void _unselect(MenuItem item) {
    _selectionSet.remove(item);
    if (model != null && multiSelect) {
      bool hasSelectedChildren(MenuItem parent) =>
        model.getChildren(parent).firstWhere((MenuItem child) =>
            isSelected(child), orElse: () => null) != null;
      model.getAncestors(item).forEach((MenuItem ancestor) {
        if(!hasSelectedChildren(ancestor)) {
          _selectionSet.remove(ancestor);
        }
      });
      _selectionSet.removeAll(model.getDescendants(item));
    }
  }

  bool isVisible(item) {
    if (model != null && item != null) {
      Iterable ancestors = model.getAncestors(item);
      if (ancestors.isEmpty) {
        return true;
      }
      return ancestors.every((item) => isExpanded(item));
    }
    return false;
  }

  Iterable getSelections() {
    List result = [];
    model.roots.forEach((MenuItem item) {
      _getSelectedSubtree(item, result);
    });
    return result;
  }

  void _getSelectedSubtree(MenuItem item, List result) {
    if (isSelected(item)) {
      result.add(item);
    }
    model.getChildren(item).forEach((MenuItem item) {
      _getSelectedSubtree(item, result);
    });
  }

  void clearSelections() {
    _selectionSet.clear();
  }

  void selectAll(Iterable<MenuItem> visibleItems) =>
    visibleItems.forEach((MenuItem item) => _select(item));

  void selectNone() {
    clearSelections();
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

  void markItemForSelectionByIndex(int index) {
    if (index < _visibleItems.length)
      _markedItem = _visibleItems[index];
  }

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

  bool commitSelection() {
    if (isVisible(_markedItem)) {
      return _select(_markedItem);
    }
    return false;
  }

  bool get isLinear => model.isLinear;

  void onMouseDownInput(MouseEvent event) {
    event.stopPropagation();
    event.preventDefault();
  }

  void onKeyDown(KeyboardEvent event) {
    switch (event.keyCode) {
      case KeyCode.DOWN:
        event.stopPropagation();
        event.preventDefault();
        return;
      case KeyCode.UP:
        event.stopPropagation();
        event.preventDefault();
        return;
      case KeyCode.SPACE:
        event.stopPropagation();
        event.preventDefault();
        return;
   }
  }

  /// do the navigation and also prevent the scrollbar distraction.
  void onKeyUp(KeyboardEvent event) {
    switch (event.keyCode) {
      case KeyCode.DOWN:
        if (_visibleItems.isNotEmpty) {
          int index = getForwardSelectionIndex();
          markItemForSelectionByIndex(index);
        }
        event.stopPropagation();
        event.preventDefault();
        return;
      case KeyCode.UP:
        if (_visibleItems.isNotEmpty) {
          int index = getBackwardSelectionIndex();
          markItemForSelectionByIndex(index);
        }
        event.stopPropagation();
        event.preventDefault();
        return;
      case KeyCode.SPACE:
      case KeyCode.ENTER:
        if (multiSelect) {
          toggleSelection(_markedItem);
        } else {
          if (!isSelected(_markedItem)) {
            if (commitSelection()) {
              notifySelections();
            }
          }
        }
        event.stopPropagation();
        event.preventDefault();
        return;
    }
  }
}
