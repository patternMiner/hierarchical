library selection_controller;

import 'dart:html';
import 'dart:collection';
import 'dart:async';
import 'package:angular/angular.dart';
import '../../common/selection_path/selection_path.dart';


@NgController(
  selector: 'selection-controller',
  publishAs: 'selectionController',
  visibility: NgDirective.CHILDREN_VISIBILITY
)
class SelectionController implements NgAttachAware, NgDetachAware {
  final Set _selectionSet = new HashSet();
  final Set _expansionSet = new HashSet();
  final List<SelectionPath> _visiblePaths = <SelectionPath>[];
  SelectionPath _markedPath;

  @NgOneWayOneTime('selection-path-model')
  SelectionPathModel model;
  @NgOneWayOneTime('multi-select')
  bool multiSelect = false;
  @NgOneWayOneTime('selection-mediator')
  SelectionPathEventMediator mediator;

  StreamSubscription<SelectionPathEvent> _mediatorSubscription;
  StreamSubscription<SelectionPathEvent> _modelSubscription;

  void attach() {
    _computeVisiblePaths();
    _createSubscription();
  }

  void detach() {
    _cancelSubscription();
    if (model != null) {
      model.clear();
    }
    _selectionSet.clear();
    _expansionSet.clear();
  }

  void _createSubscription() {
    if (mediator != null) {
      _mediatorSubscription = mediator.onSelectionEvent()
          .listen((SelectionPathEvent event) {
        switch(event.type) {
          case SelectionPathEvent.SET_SELECTION:
            setSelection(event.data);
            return;
          case SelectionPathEvent.DESELECT:
            toggleSelection(event.data);
            return;
          case SelectionPathEvent.GET_LABEL_TEMPLATE_MARKUP_FUNCTION:
            if (event.completer != null) {
              event.completer.complete(model.getLabelTemplateMarkup);
            }
            return;
          case SelectionPathEvent.GET_CURRENT_SELECTION:
            if (event.completer != null) {
              event.completer.complete(getSelections());
            }
            return;
          case SelectionPathEvent.SELECTION_PATH_DELETED:
            _selectionSet.remove(event.data);
            _expansionSet.remove(event.data);
            return;
        }
      });
    }
    if (model != null) {
      _modelSubscription = model.onSelectionPathRemoved()
          .listen((SelectionPathEvent event) {
        _selectionSet.remove(event.data);
        _expansionSet.remove(event.data);
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

  bool isSelected(path) => _selectionSet.contains(path);
  bool isExpanded(path) => _expansionSet.contains(path);

  void toggleExpansion(path) {
    _expandCollapse(path, isExpanded(path));
    _computeVisiblePaths();
  }

  void toggleSelection(path) {
    isSelected(path) ? _unselect(path) : _select(path);
    notifySelections();
  }

  void _expandCollapse(SelectionPath path, bool collapse) {
    collapse ? _expansionSet.remove(path) : _expansionSet.add(path);
    if (model != null && collapse) {
      model.getDescendants(path).forEach((SelectionPath descendant) =>
        _expansionSet.remove(descendant));
    }
  }

  void _computeVisiblePaths() {
    _visiblePaths.clear();
    roots.forEach((SelectionPath root) {
      model.dfs(root, _expansionSet, _visiblePathVisitor);
    });
  }

  void _visiblePathVisitor(SelectionPath path) {
    _visiblePaths.add(path);
  }

  void notifySelections() {
    if (mediator != null) {
      mediator.post(new SelectionPathEvent(SelectionPathEvent.SELECTION_CHANGED,
          this, getSelections(), null));
    }
  }

  /// Sets the initial selection. Does not trigger the SELECTION_CHANGED event.
  void setSelection(Iterable<SelectionPath> paths) {
    if (paths != null) {
      paths.forEach((SelectionPath path) => _select(path));
    }
  }

  bool _select(SelectionPath path) {
    if (!multiSelect) {
      _selectionSet.clear();
    }
    if (isSelected(path)) {
      return false;
    }
    _selectionSet.add(path);
    if (model != null && multiSelect) {
      _selectionSet.addAll(model.getDescendants(path));
      _selectionSet.addAll(model.getAncestors(path));
    }
    return true;
  }

  void _unselect(SelectionPath path) {
    _selectionSet.remove(path);
    if (model != null && multiSelect) {
      bool hasSelectedChildren(SelectionPath parent) =>
        model.getChildren(parent).firstWhere((SelectionPath child) =>
            isSelected(child), orElse: () => null) != null;
      model.getAncestors(path).forEach((SelectionPath ancestor) {
        if(!hasSelectedChildren(ancestor)) {
          _selectionSet.remove(ancestor);
        }
      });
      _selectionSet.removeAll(model.getDescendants(path));
    }
  }

  bool isVisible(path) {
    if (model != null && path != null) {
      Iterable ancestors = model.getAncestors(path);
      if (ancestors.isEmpty) {
        return true;
      }
      return ancestors.every((path) => isExpanded(path));
    }
    return false;
  }

  Iterable getSelections() {
    List result = [];
    model.roots.forEach((SelectionPath path) {
      _getSelectedSubtree(path, result);
    });
    return result;
  }

  void _getSelectedSubtree(SelectionPath path, List result) {
    if (isSelected(path)) {
      result.add(path);
    }
    model.getChildren(path).forEach((SelectionPath path) {
      _getSelectedSubtree(path, result);
    });
  }

  void clearSelections() {
    _selectionSet.clear();
  }

  void selectAll(Iterable<SelectionPath> visiblePaths) =>
    visiblePaths.forEach((SelectionPath path) => _select(path));

  void selectNone() {
    clearSelections();
  }

  String getLabelTemplateMarkup(SelectionPath path) => model != null ?
      model.getLabelTemplateMarkup(path) : null;

  bool hasParent(SelectionPath path) => model != null ?
      model.hasParent(path) : false;

  bool isLeaf(SelectionPath path) => model != null ? model.isLeaf(path) :
      false;

  Iterable getAncestors(SelectionPath path) => model != null ?
      model.getAncestors(path) : const[];

  Iterable children(SelectionPath parent) => model != null ?
      model.getChildren(parent) : const[];

  Iterable get roots => model != null ? model.roots : const[];

  markPathForSelection(SelectionPath path) => _markedPath = path;

  bool isActive (SelectionPath path) => _markedPath == path;

  void markPathForSelectionByIndex(int index) {
    if (index < _visiblePaths.length)
      _markedPath = _visiblePaths[index];
  }

  int getForwardSelectionIndex() {
    int index = _visiblePaths.indexOf(_markedPath);
    if (index < 0) {
      return 0;
    }
    index++;
    if (index >= _visiblePaths.length) {
      index = _visiblePaths.length -1;
    }
    return index;
  }

  int getBackwardSelectionIndex() {
    int index = _visiblePaths.indexOf(_markedPath);
    if (index < 0) {
      return 0;
    }
    index--;
    if (index < 0 || index >= _visiblePaths.length) {
      index = 0;
    }
    return index;
  }

  bool commitSelection() {
    if (isVisible(_markedPath)) {
      return _select(_markedPath);
    }
    return false;
  }

  int get height => model.height;
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
        if (_visiblePaths.isNotEmpty) {
          int index = getForwardSelectionIndex();
          markPathForSelectionByIndex(index);
        }
        event.stopPropagation();
        event.preventDefault();
        return;
      case KeyCode.UP:
        if (_visiblePaths.isNotEmpty) {
          int index = getBackwardSelectionIndex();
          markPathForSelectionByIndex(index);
        }
        event.stopPropagation();
        event.preventDefault();
        return;
      case KeyCode.SPACE:
      case KeyCode.ENTER:
        if (multiSelect) {
          toggleSelection(_markedPath);
        } else {
          if (!isSelected(_markedPath)) {
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
