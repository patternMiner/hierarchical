library app_event_bus;

import 'dart:async';
import 'package:angular/angular.dart';

@NgController(
    selector: 'event-bus',
    publishAs: 'eventBus',
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

/**
 * Encapsulates both requests for information from the listeners, and
 * notifications to the listeners.
 *
 * For requests for information, the requester will include a completer
 * that needs to be completed with appropriate result by the listener.
 */
class AppEvent {
  /// Queries that require the listener to respond through the completer.
  static const String GET_CURRENT_SELECTION = 'GET_CURRENT_SELECTION';
  static const String GET_TEMPLATE_MARKUP_FUNCTION =
                                              'GET_TEMPLATE_MARKUP_FUNCTION';

  /// Notifications to the listeners. No response required.
  static const String SELECTION_CHANGED = 'SELECTION_CHANGED';
  static const String CHIP_DELETED      = 'CHIP_DELETED';

  final String type;
  final dynamic source;
  final dynamic data;
  final Completer completer;

  AppEvent(this.type, this.source, this.data, this.completer);
}
