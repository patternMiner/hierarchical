part of hierarchical;

@NgController(
    selector: 'tree',
    publishAs: 'tree',
    visibility: NgDirective.CHILDREN_VISIBILITY
)
class TreeController implements NgAttachAware, NgDetachAware {
  final Expando<_GraphNode> valueMap = new Expando<_GraphNode>();
  final Graph<_GraphNode> _graph = new Graph<_GraphNode>();
  final Set selectionSet = new HashSet();
  final Set expansionSet = new HashSet();
  final List _parentStack = [];
  final AppEventBus _eventBus;

  @NgOneWayOneTime('selection-enabled')
  bool selectionEnabled;

  StreamSubscription<AppEvent> _subscription;

  var _curValue;
  var _parent;

  TreeController(this._eventBus) {
    _subscription = _eventBus.onAppEvent().listen((AppEvent event) {
      switch(event.type) {
        case AppEvent.CHIP_DELETED:
          toggleSelection(event.data);
          return;
        case AppEvent.CURRENT_SELECTION:
          if (event.completer != null) {
            event.completer.complete(getSelections());
          }
          return;
      }
    });
  }

  void attach() {
    _cancelSubscription();
    _subscription = _eventBus.onAppEvent().listen((AppEvent event) {
      switch(event.type) {
        case AppEvent.CHIP_DELETED:
          toggleSelection(event.data);
          return;
        case AppEvent.CURRENT_SELECTION:
          if (event.completer != null) {
            event.completer.complete(getSelections());
          }
          return;
      }
    });
  }

  void detach() {
    _cancelSubscription();
  }

  void _cancelSubscription() {
    if (_subscription != null) {
      _subscription.cancel();
    }
  }

  bool isSelected(value) => selectionSet.contains(value);
  bool isExpanded(value) => expansionSet.contains(value);
  bool toggleExpansion(value) =>
      isExpanded(value) ? expansionSet.remove(value) : expansionSet.add(value);
  bool hasParent(value) => _graph.getParents(_getNode(value)).isNotEmpty;

  void toggleSelection(value) {
    if (isSelected(value)) {
      selectionSet.remove(value);
      selectionSet.removeAll(_graph.getDescendants(_getNode(value))
          .map((_GraphNode node) => node.value));
    } else {
      selectionSet.add(value);
      selectionSet.addAll(_graph.getDescendants(_getNode(value))
          .map((_GraphNode node) => node.value));
    }
    _eventBus.post(new AppEvent(AppEvent.SELECTION_CHANGED,
        getSelections(), null));
  }

  bool isVisible(value) {
    Iterable ancestors = _graph.getAncestors(_getNode(value));
    if (ancestors.isEmpty) {
      return true;
    }
    return ancestors.every((node) => isExpanded(node.value));
  }

  Iterable getSelections() {
    List result = [];
    _graph.getRoots().forEach((_GraphNode node) {
      getSelectedSubtree(node, result);
    });
    return result;
  }

  void getSelectedSubtree(_GraphNode node, List result) {
    if (isSelected(node.value)) {
      result.add(node.value);
    }
    _graph.getChildren(node).forEach((_GraphNode child) {
      getSelectedSubtree(child, result);
    });
  }

  void pushList() {
    if(_curValue != null) {
      _parentStack.add(_curValue);
    }
    _parent = _curValue;
    //print("push list: $_parent");
  }

  void popList() {
    if (_parentStack.isNotEmpty) {
      _parentStack.removeLast();
    }
    _curValue = _parentStack.isNotEmpty ? _parentStack.last : null;
    _parent = _curValue;
    //print("pop list: $_parent");
  }

  void addNode(value) {
    if (_parent != null) {
      //print("add edge: $_parent, $value");
      _graph.addEdge(_getNode(_parent), _getNode(value));
    } else {
      //print("add node: $value");
      _graph.addNode(_getNode(value));
    }
    _curValue = value;
  }

  Iterable children(value) =>
    _graph.getChildren(_getNode(value)).map((_GraphNode node) => node.value);

  _GraphNode _getNode(value) {
    _GraphNode node = valueMap[value];
    if (node == null) {
      node = new _GraphNode(value);
      valueMap[value] = node;
    }
    return node;
  }
}


class _GraphNode {
  final value;

  _GraphNode(this.value);

  bool operator ==(Object other) => other is _GraphNode && other.value == value;
  int get hashCode => value.hashCode;
}