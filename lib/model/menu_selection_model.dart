part of menu_model;

/**
 * Keeps track of the menu selection options and the selected items
 * by reacting to the menu selection events through the mediator.
 */
class MenuSelectionModel<T> {
  bool showDeselectOption = false;
  bool multiSelect = false;
  bool includeSelectAll = false;
  /// Cascades the select operation to select the whole subtree
  /// upon selection of a non-terminal item.
  bool _subtreeSelection = true;
  String placeholder = '-';

  final List<MenuItem<T>> _selectedItems = <MenuItem<T>>[];
  final MenuSelectionEventMediator mediator;
  StreamSubscription<MenuSelectionEvent> _streamSubscription;

  MenuSelectionModel(this.mediator) {
    _streamSubscription =
        mediator.onSelectionEvent().listen((MenuSelectionEvent event){
      switch(event.type) {
        case MenuSelectionEvent.SELECTION_CHANGED:
        case MenuSelectionEvent.SET_SELECTION:
          _setSelection(event.data);
          return;
        case MenuSelectionEvent.DESELECT:
          _selectedItems.remove(event.data);
          return;
        case MenuSelectionEvent.GET_CURRENT_SELECTION:
          if (event.completer != null) {
            event.completer.complete(_selectedItems.toList());
          }
          return;
      }
    });
  }

  bool get subtreeSelection => _subtreeSelection && multiSelect;
  set subtreeSelection(bool flag) => _subtreeSelection = flag;

  void _setSelection(Iterable<MenuItem> selection) {
    _selectedItems.clear();
    if (selection != null) {
      _selectedItems.addAll(selection);
    }
  }

  void close() {
    if (_streamSubscription != null) {
      _streamSubscription.cancel();
      _streamSubscription = null;
    }
  }
}


