library selection_controller;

import 'dart:collection';
import 'dart:async';
import 'package:angular/angular.dart';
import '../../common/graph/graph.dart';
import '../../common/mediator/selection_mediator.dart';

@NgController(
  selector: 'selection-controller',
  publishAs: 'selectionController',
  visibility: NgDirective.CHILDREN_VISIBILITY
)
class SelectionController implements NgAttachAware, NgDetachAware{
  final Set _selectionSet = new HashSet();
  final Set _expansionSet = new HashSet();

  @NgOneWayOneTime('selection-path-model')
  SelectionPathModel model;

  bool selectionEnabled = true;
  StreamSubscription<SelectionEvent> _subscription;

  void attach() {
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
    if (model == null) {
      return;
    }
    _subscription = model.mediator.onSelectionEvent()
        .listen((SelectionEvent event) {
      switch(event.type) {
        case SelectionEvent.SET_SELECTION:
          setSelection(event.data);
          return;
        case SelectionEvent.DESELECT:
          toggleSelection(event.data);
          return;
        case SelectionEvent.GET_LABEL_TEMPLATE_MARKUP_FUNCTION:
          if (event.completer != null) {
            event.completer.complete(model.getLabelTemplateMarkup);
          }
          return;
        case SelectionEvent.GET_CURRENT_SELECTION:
          if (event.completer != null) {
            event.completer.complete(getSelections());
          }
          return;
        case SelectionEvent.SELECTION_PATH_DELETED:
          _selectionSet.remove(event.data);
          _expansionSet.remove(event.data);
          return;
      }
    });
  }

  void _cancelSubscription() {
    if (_subscription != null) {
      _subscription.cancel();
    }
  }

  bool isSelected(path) => _selectionSet.contains(path);
  bool isExpanded(path) => _expansionSet.contains(path);
  bool toggleExpansion(path) =>
      isExpanded(path) ? _expansionSet.remove(path) : _expansionSet.add(path);

  void toggleSelection(path) {
    if (isSelected(path)) {
      _selectionSet.remove(path);
      if (model != null) {
        _selectionSet.removeAll(model.getDescendants(path));
      }
    } else {
      _selectionSet.add(path);
      if (model != null) {
        _selectionSet.addAll(model.getDescendants(path));
      }
    }
    if (model != null) {
      model.mediator.post(new SelectionEvent(SelectionEvent.SELECTION_CHANGED,
          this, getSelections(), null));
    }
  }

  /// Sets the initial selection. Does not trigger the SELECTION_CHANGED event.
  void setSelection(Iterable<SelectionPath> paths) {
    if (paths != null) {
      paths.forEach((SelectionPath path) => select(path));
    }
  }

  void select(SelectionPath path) {
    _selectionSet.add(path);
    if (model != null) {
      _selectionSet.addAll(model.getDescendants(path));
    }
  }

  bool isVisible(path) {
    if (model != null) {
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
  Iterable get roots {
    return model != null ? model.roots : const[];
  }
}

class SelectionPathModel {
  final Graph<SelectionPath> _graph = new Graph<SelectionPath>();
  final List<SelectionPath> _roots = <SelectionPath>[];
  final Map<SelectionPath, List<SelectionPath>> _childrenMap =
      <SelectionPath, List<SelectionPath>>{};
  final Function getLabelTemplateMarkup;
  final SelectionMediator mediator = new SelectionMediator();

  SelectionPathModel(this.getLabelTemplateMarkup) {
    assert(this.getLabelTemplateMarkup != null);
  }

  SelectionPathModel.fromList(List items, this.getLabelTemplateMarkup) {
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
    mediator.post(new SelectionEvent(SelectionEvent.SELECTION_PATH_DELETED,
        this, path, null));
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
