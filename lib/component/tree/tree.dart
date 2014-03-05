part of hierarchical;

@NgController(
    selector: 'tree',
    publishAs: 'tree',
    visibility: NgDirective.CHILDREN_VISIBILITY
)
class TreeController implements NgAttachAware, NgDetachAware {
  final Graph<_Node> _graph = new Graph<_Node>();
  final Set selectionSet = new HashSet();
  final Set expansionSet = new HashSet();
  final List _parentStack = [];
  final AppEventBus _eventBus;

  @NgOneWayOneTime('selection-enabled')
  bool selectionEnabled;

  @NgOneWayOneTime('items')
  List items;

  StreamSubscription<AppEvent> _subscription;

  TreeController(this._eventBus) {
    _createSubscription();
  }

  void attach() {
    _processList(items, []);
    _cancelSubscription();
    _createSubscription();
  }

  void detach() {
    _cancelSubscription();
  }

  void _createSubscription() {
    _subscription = _eventBus.onAppEvent().listen((AppEvent event) {
      switch(event.type) {
        case AppEvent.CHIP_DELETED:
          toggleSelection(event.data);
          return;
        case AppEvent.GET_CURRENT_SELECTION:
          if (event.completer != null) {
            event.completer.complete(getSelections());
          }
          return;
        case AppEvent.GET_LABEL_FUNCTION:
          if (event.completer != null) {
            event.completer.complete(getLabel);
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

  _Node _processListItem(item, List parentStack) {
    _Node dst = new _Node(item);
    _Node src = parentStack.isNotEmpty ? parentStack.last : null;
    if (src != null) {
      _graph.addEdge(src, dst);
    } else {
      _graph.addNode(dst);
    }
    return dst;
  }

  bool isSelected(item) => selectionSet.contains(item);
  bool isExpanded(item) => expansionSet.contains(item);
  bool toggleExpansion(item) =>
      isExpanded(item) ? expansionSet.remove(item) : expansionSet.add(item);
  bool hasParent(item) => _graph.getParents(item).isNotEmpty;
  bool isLeaf(item) => _graph.isLeaf(item);

  void toggleSelection(item) {
    if (isSelected(item)) {
      selectionSet.remove(item);
      selectionSet.removeAll(_graph.getDescendants(item));
    } else {
      selectionSet.add(item);
      selectionSet.addAll(_graph.getDescendants(item));
    }
    _eventBus.post(new AppEvent(AppEvent.SELECTION_CHANGED,
        getSelections(), null));
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
    _graph.getRoots().forEach((_Node item) {
      _getSelectedSubtree(item, result);
    });
    return result;
  }

  void _getSelectedSubtree(_Node item, List result) {
    if (isSelected(item)) {
      result.add(item);
    }
    _graph.getChildren(item).forEach((_Node item) {
      _getSelectedSubtree(item, result);
    });
  }

  Iterable get roots => _graph.getRoots();
  Iterable children(_Node parent) => _graph.getChildren(parent);
}


class _Node {
  final value;

  _Node(this.value);
}

String getLabel(_Node item) {
  return item.value.toString();
}
