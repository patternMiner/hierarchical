part of hierarchical;

@NgController(
    selector: 'app-event-bus',
    publishAs: 'AppEventBus',
    visibility: NgDirective.CHILDREN_VISIBILITY
)
class AppEventBus {
  final StreamController<AppEvent> _streamController =
      new StreamController<AppEvent>();
}


class AppEvent {
}
