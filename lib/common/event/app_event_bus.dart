part of hierarchical;

@NgController(
    selector: 'app-event-bus',
    publishAs: 'AppEventBus',
    visibility: NgDirective.CHILDREN_VISIBILITY
)
class AppEventBus implements NgAttachAware, NgDetachAware {
  StreamController<AppEvent> _streamController;
  StreamSubscription<AppEvent> _subscription;

  int _listenerCount = 0;

  AppEventBus() {
    _streamController =
          new StreamController<AppEvent>.broadcast(
              onListen: () => _listenerCount++,
              onCancel: () => _listenerCount--);
    _subscription = onAppEvent().listen((AppEvent event) {
      if (event.type == AppEvent.LABEL_FUNCTION) {
        if (event.completer != null) {
          event.completer.complete(getLabel);
        }
      }
    });
  }

  void attach() {
    _cancelSubscription();
    _subscription = onAppEvent().listen((AppEvent event) {
      if (event.type == AppEvent.LABEL_FUNCTION) {
        if (event.completer != null) {
          event.completer.complete(getLabel);
        }
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

  void post(AppEvent event) {
    if (_listenerCount > 0) {
      _streamController.add(event);
    }
  }

  Stream<AppEvent> onAppEvent() => _streamController.stream;
}


String getLabel(item) {
  return item.value;
}

class AppEvent {
  static const String SELECTION_CHANGED = 'SELECTION_CHANGED';
  static const String CURRENT_SELECTION = 'CURRENT_SELECTION';
  static const String LABEL_FUNCTION    = 'LABEL_FUNCTION';
  static const String CHIP_DELETED      = 'CHIP_DELETED';

  final String type;
  final dynamic data;
  final Completer completer;

  AppEvent(this.type, this.data, this.completer);
}
