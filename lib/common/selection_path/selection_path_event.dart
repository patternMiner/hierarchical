part of selection_path;

/**
 * Encapsulates both requests for selection information by the listeners,
 * and selection notifications to the listeners.
 *
 * For requests for selection information, the requester will include a
 * completer that needs to be completed with appropriate result by the
 * listener.
 */
class SelectionPathEvent {
  /// Request for access to the current selection of selection paths.
  /// The listener must complete the completer of the event with
  /// the requested information.
  static const String GET_CURRENT_SELECTION  = 'GET_CURRENT_SELECTION';
  /// Selection has changed. The data field contains the new selection paths.
  static const String SELECTION_CHANGED      = 'SELECTION_CHANGED';
  /// Select the given selection paths in the data field.
  static const String SET_SELECTION          = 'SET_SELECTION';
  /// Deselect the given selection path in the data field.
  static const String DESELECT               = 'DESELECT';
  /// Model has changed: selection path got deleted.
  static const String SELECTION_PATH_DELETED = 'SELECTION_PATH_DELETED';

  final String type;
  final dynamic source;
  final dynamic data;
  final Completer completer;

  SelectionPathEvent(this.type, this.source, this.data, this.completer);
}
