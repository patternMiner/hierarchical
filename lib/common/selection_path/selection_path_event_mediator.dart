part of selection_path;

class SelectionPathEventMediator {
  StreamController<SelectionPathEvent> _streamController;

  int _listenerCount = 0;

  SelectionPathEventMediator() {
    _streamController =
          new StreamController<SelectionPathEvent>.broadcast(
              onListen: () => _listenerCount++,
              onCancel: () => _listenerCount--);
  }

  void post(SelectionPathEvent event) {
    if (_listenerCount > 0) {
      _streamController.add(event);
    }
  }

  Stream<SelectionPathEvent> onSelectionEvent() => _streamController.stream;
}
