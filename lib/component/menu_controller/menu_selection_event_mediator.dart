part of menu_controller;

class MenuSelectionEventMediator {
  StreamController<MenuSelectionEvent> _streamController;

  int _listenerCount = 0;

  MenuSelectionEventMediator() {
    _streamController =
          new StreamController<MenuSelectionEvent>.broadcast(
              onListen: () => _listenerCount++,
              onCancel: () => _listenerCount--);
  }

  void post(MenuSelectionEvent event) {
    if (_listenerCount > 0) {
      _streamController.add(event);
    }
  }

  Stream<MenuSelectionEvent> onSelectionEvent() => _streamController.stream;
}
