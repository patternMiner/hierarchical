part of menu;

/**
 * Encapsulates both requests for selection information by the listeners,
 * and selection notifications to the listeners.
 *
 * For requests for selection information, the requester will include a
 * completer that needs to be completed with appropriate result by the
 * listener.
 */
class MenuSelectionEvent {
  /// Request for access to the current selection of menu items.
  /// The listener must complete the completer of the event with
  /// the requested information.
  static const String GET_CURRENT_SELECTION  = 'GET_CURRENT_SELECTION';
  /// Selection has changed. The data field contains the new menu items.
  static const String SELECTION_CHANGED      = 'SELECTION_CHANGED';
  /// Select the given menu items in the data field.
  static const String SET_SELECTION          = 'SET_SELECTION';
  /// Deselect the given menu item in the data field.
  static const String DESELECT               = 'DESELECT';
  /// Model has changed: menu item got deleted.
  static const String MENU_ITEM_DELETED = 'MENU_ITEM_DELETED';

  final String type;
  final dynamic source;
  final dynamic data;
  final Completer completer;

  MenuSelectionEvent(this.type, this.source, this.data, this.completer);
}
