library tree;

import 'dart:collection';
import 'dart:async';

import 'package:angular/angular.dart';
import '../../common/graph/graph.dart';
import '../../common/mediator/selection_mediator.dart';

@NgController(
    selector: 'tree',
    publishAs: 'tree',
    visibility: NgDirective.CHILDREN_VISIBILITY
)
class TreeController implements NgAttachAware, NgDetachAware {
  final Graph<SelectionPath> _graph = new Graph<SelectionPath>();
  final Set _selectionSet = new HashSet();
  final Set _expansionSet = new HashSet();

  @NgOneWayOneTime('selection-mediator')
  SelectionMediator mediator;
  @NgOneWayOneTime('get-template-markup')
  Function getTemplateMarkup;

  @NgOneWayOneTime('selection-enabled')
  bool selectionEnabled;
  @NgOneWayOneTime('items')
  List items = [];

  List roots = [];

  StreamSubscription<SelectionEvent> _subscription;

  void attach() {
    _processList(items, []);
    roots.addAll(_graph.getRoots());
    _cancelSubscription();
    _createSubscription();
  }

  void detach() {
    roots.clear();
    _cancelSubscription();
  }

  void _createSubscription() {
    if (mediator == null) {
      return;
    }
    _subscription = mediator.onSelectionEvent().listen((SelectionEvent event) {
      switch(event.type) {
        case SelectionEvent.DESELECT:
          toggleSelection(event.data);
          return;
        case SelectionEvent.GET_CURRENT_SELECTION:
          if (event.completer != null) {
            event.completer.complete(getSelections());
          }
          return;
      }
    });
  }

  void _cancelSubscription() {
    if (_subscription != null) {
      _subscription.cancel();
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

  SelectionPath _processListItem(item, List parentStack) {
    SelectionPath src = parentStack.isNotEmpty ? parentStack.last : null;
    List pathComponents = src != null ? src.components.toList() : [];
    pathComponents.add(item);
    return addPath(new SelectionPath(pathComponents));
  }

  SelectionPath addPath(SelectionPath path) {
    SelectionPath parent = path.parent;
    if (parent != null) {
      _graph.addEdge(parent, path);
    } else {
      _graph.addNode(path);
    }
    return path;
  }

  bool isSelected(item) => _selectionSet.contains(item);
  bool isExpanded(item) => _expansionSet.contains(item);
  bool toggleExpansion(item) =>
      isExpanded(item) ? _expansionSet.remove(item) : _expansionSet.add(item);
  bool hasParent(item) => _graph.getParents(item).isNotEmpty;
  bool isLeaf(item) => _graph.isLeaf(item);
  Iterable getAncestors(item) => _graph.getAncestors(item);

  void toggleSelection(item) {
    if (isSelected(item)) {
      _selectionSet.remove(item);
      _selectionSet.removeAll(_graph.getDescendants(item));
    } else {
      _selectionSet.add(item);
      _selectionSet.addAll(_graph.getDescendants(item));
    }
    if (mediator != null) {
      mediator.post(new SelectionEvent(SelectionEvent.SELECTION_CHANGED,
          this, getSelections(), null));
    }
  }

  bool isVisible(item) {
    Iterable ancestors = _graph.getAncestors(item);
    if (ancestors.isEmpty) {
      return true;
    }
    return ancestors.every((item) => isExpanded(item));
  }

  Iterable getSelections() {
    List result = [];
    _graph.getRoots().forEach((SelectionPath item) {
      _getSelectedSubtree(item, result);
    });
    return result;
  }

  void _getSelectedSubtree(SelectionPath item, List result) {
    if (isSelected(item)) {
      result.add(item);
    }
    _graph.getChildren(item).forEach((SelectionPath item) {
      _getSelectedSubtree(item, result);
    });
  }

  Iterable children(SelectionPath parent) => _graph.getChildren(parent);
}
