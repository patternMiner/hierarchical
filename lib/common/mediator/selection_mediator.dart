library mediator;

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

  Stream<SelectionEvent> onSelectionEvent() => _streamController.stream;
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
  /// Request for access to the current selection of selection paths.
  /// The listener must complete the completer in the data field with
  /// the requested information.
  static const String GET_CURRENT_SELECTION = 'GET_CURRENT_SELECTION';
  /// Selection has changed. The data field contains the new selection paths.
  static const String SELECTION_CHANGED = 'SELECTION_CHANGED';
  /// Select the given selection paths in the data field.
  static const String SELECT            = 'SELECT';
  /// Deselect the given selection path in the data field.
  static const String DESELECT          = 'DESELECT';

  final String type;
  final dynamic source;
  final dynamic data;
  final Completer completer;

  SelectionEvent(this.type, this.source, this.data, this.completer);
}


class SelectionPath {
  final List components;

  SelectionPath(this.components) {
    assert(this.components != null);
  }

  SelectionPath get parent => components.length < 2 ? null :
      new SelectionPath(components.sublist(0, components.length-1));

  int  get hashCode {
    int hash = 1;
    components.forEach((value) => hash = hash * 31 + value.hashCode);
    return hash;
  }

  bool operator==(SelectionPath other) {
    if (this.components.length == other.components.length) {
      for (int i=0; i<this.components.length; i++) {
        if (this.components[i] != other.components[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}
