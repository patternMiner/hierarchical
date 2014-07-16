library selection_event;

import 'dart:async';

part 'menu_selection_event_mediator.dart';


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
  static const String GET_CURRENT_SELECTION = 'GET_CURRENT_SELECTION';
  /// Selection has changed. The data field contains the new menu items.
  static const String SELECTION_CHANGED = 'SELECTION_CHANGED';
  /// Marks the end of multi-selection process.
  static const String SELECTION_ENDED = 'SELECTION_ENDED';
  /// Select the given menu items in the data field.
  static const String SET_SELECTION = 'SET_SELECTION';
  /// Deselect the given menu item in the data field.
  static const String DESELECT = 'DESELECT';
  /// Model has changed: menu item got deleted.
  static const String MENU_ITEM_DELETED = 'MENU_ITEM_DELETED';
  /// Mark the next item for selection.
  static const String MARK_NEXT_MENU_ITEM = 'MARK_NEXT_MENU_ITEM';
  /// Mark the previous item for selection.
  static const String MARK_PREV_MENU_ITEM = 'MARK_PREV_MENU_ITEM';
  /// Select the currently marked item for selection.
  static const String SELECT_MARKED_MENU_ITEM = 'SELECT_MARKED_MENU_ITEM';

  final String type;
  final dynamic source;
  final dynamic data;
  final Completer completer;

  MenuSelectionEvent(this.type, this.source, this.data, this.completer);
}
