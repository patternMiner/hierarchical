part of selection_event;

/**
 * Mediator between the [GtHierarchicalMenuController] and its clients.
 *
 * The mediation is through [MenuSelectionEvent]s.
 *
 * See [MenuSelectionEvent] for the format and use of the events.
 */
class MenuSelectionEventMediator {
  final StreamController<MenuSelectionEvent> _streamController =
      new StreamController<MenuSelectionEvent>.broadcast();

  void dispose() {
    _streamController.close();
  }

  void post(MenuSelectionEvent event) => _streamController.add(event);

  Stream<MenuSelectionEvent> onSelectionEvent() => _streamController.stream;
}
