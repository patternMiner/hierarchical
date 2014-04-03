library selection_mediator;

import 'dart:async';

class SelectionMediator {
  StreamController<SelectionEvent> _streamController;

  int _listenerCount = 0;

  SelectionMediator() {
    _streamController =
          new StreamController<SelectionEvent>.broadcast(
              onListen: () => _listenerCount++,
              onCancel: () => _listenerCount--);
  }

  void post(SelectionEvent event) {
    if (_listenerCount > 0) {
      _streamController.add(event);
    }
  }

  Stream<SelectionEvent> onAppEvent() => _streamController.stream;
}

/**
 * Encapsulates both requests for selection information by the listeners,
 * and selection notifications to the listeners.
 *
 * For requests for selection information, the requester will include a
 * completer that needs to be completed with appropriate result by the
 * listener.
 */
class SelectionEvent {
  /// Queries that require the listener to respond through the completer.
  static const String GET_CURRENT_SELECTION = 'GET_CURRENT_SELECTION';
  static const String GET_VALUE_FUNCTION    = 'GET_VALUE_FUNCTION';
  static const String GET_TEMPLATE_MARKUP_FUNCTION =
                                              'GET_TEMPLATE_MARKUP_FUNCTION';

  /// Notifications to the listeners. No response required.
  static const String SELECTION_CHANGED = 'SELECTION_CHANGED';
  static const String SELECT            = 'SELECT';
  static const String DESELECT          = 'DESELECT';

  final String type;
  final dynamic source;
  final dynamic data;
  final Completer completer;

  SelectionEvent(this.type, this.source, this.data, this.completer);
}
