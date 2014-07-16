part of hierarchical_menu_demo;

@Component(
    selector: 'tree-chip',
    templateUrl: 'packages/hierarchical/component/demo/tree_chip.html',
    cssUrl: 'hierarchical.css',
    map: const {
      'title': '=>!title',
      'menu-model': '=>!model',
      'multi-select': '=>!multiSelect',
    },
    publishAs: 'ctrl'
)
class TreeChipComponent implements AttachAware, DetachAware {

  String title;
  MenuModel _model;

  final MenuSelectionModel selectionModel =
      new MenuSelectionModel(new MenuSelectionEventMediator())
      ..includeSelectAll = true
      ..showDeselectOption = true;

  final List<MenuItem> selectedItems = <MenuItem>[];
  StreamSubscription<MenuSelectionEvent> _streamSubscription;

  @override
  void attach() {
    _streamSubscription = selectionModel.mediator.onSelectionEvent()
        .listen((MenuSelectionEvent event) {
      switch(event.type) {
        case MenuSelectionEvent.SELECTION_CHANGED:
          if (event.data != null) {
            selectedItems.clear();
            selectedItems.addAll(event.data);
          }
          return;
        case MenuSelectionEvent.DESELECT:
          selectedItems.remove(event.data);
          return;
        case MenuSelectionEvent.SELECTION_ENDED:
          return;
      }
    });
  }

  @override
  void detach() {
    if (_streamSubscription != null) {
      _streamSubscription.cancel();
      _streamSubscription = null;
    }
  }

  void deleteItem(MenuItem item) {
    selectionModel.mediator.post(new MenuSelectionEvent(
        MenuSelectionEvent.DESELECT, this, item, null));
  }

  void set model (MenuModel m) {
    if (m != null) {
      _model = m;
    }
  }
  MenuModel get model => _model;

  set multiSelect(bool flag) => selectionModel.multiSelect = flag;
  bool get multiSelect => selectionModel.multiSelect;

  void onMouseDown(MouseEvent event) {
    if (isOnScrollbar(event)) {
      print("clicked on the scrollbar");
    }
  }

  bool isOnScrollbar(MouseEvent event) {
    Element element = event.target as Element;
    bool isOverflow = element.scrollWidth > element.clientWidth ||
        element.scrollHeight > element.clientHeight;
    if (isOverflow) {
      int scrollbarWidth = element.offsetWidth - element.clientWidth;
      int scrollbarHeight = element.offsetHeight - element.clientHeight;
      Rectangle bounds = element.getBoundingClientRect();
      Rectangle realBounds =
          new Rectangle(bounds.left, bounds.top,
              bounds.width - scrollbarWidth, bounds.height - scrollbarHeight);
      return !realBounds.containsPoint(event.client);
    }
    return false;
  }
}
