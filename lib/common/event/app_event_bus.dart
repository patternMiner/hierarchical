part of hierarchical;

@NgController(
    selector: 'app-event-bus',
    publishAs: 'AppEventBus',
    visibility: NgDirective.CHILDREN_VISIBILITY
)
class AppEventBus {
  StreamController<AppEvent> _streamController;

  int _listenerCount = 0;

  AppEventBus() {
    _streamController =
          new StreamController<AppEvent>.broadcast(
              onListen: () => _listenerCount++,
              onCancel: () => _listenerCount--);
  }

  void post(AppEvent event) {
    if (_listenerCount > 0) {
      _streamController.add(event);
    }
  }

  Stream<AppEvent> onAppEvent() => _streamController.stream;
}


class AppEvent {
  static const String SELECTION_CHANGED     = 'SELECTION_CHANGED';
  static const String GET_CURRENT_SELECTION = 'GET_CURRENT_SELECTION';
  static const String GET_LABEL_FUNCTION    = 'GET_LABEL_FUNCTION';
  static const String CHIP_DELETED          = 'CHIP_DELETED';

  final String type;
  final dynamic data;
  final Completer completer;

  AppEvent(this.type, this.data, this.completer);
}
