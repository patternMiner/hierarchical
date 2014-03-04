part of hierarchical;

@NgComponent(
    selector: 'chip-container',
    templateUrl: '../lib/component/chip/chip_container.html',
    cssUrl: '../lib/component/chip/chip_container.css',
    publishAs: 'chips',
    applyAuthorStyles: true
)
class ChipContainerComponent implements NgAttachAware, NgDetachAware {

  var list = [];
  Function getLabel;
  StreamSubscription<AppEvent> _subscription;
  final AppEventBus _eventBus;

  ChipContainerComponent(this._eventBus) {
    _getLabelFunction().then((Function getLabel) => this.getLabel = getLabel);
  }

  void attach() {
    _cancelSubscription();
    _subscription = _eventBus.onAppEvent().listen((AppEvent event) {
      switch(event.type) {
        case AppEvent.CHIP_DELETED:
          list.remove(event.data);
          return;
        case AppEvent.SELECTION_CHANGED:
          list.clear();
          list.addAll(event.data);
          return;
      }
    });
    _loadCurrentSelection().then((List chips) {
      list.clear();
      list.addAll(chips);
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

  Future<List> _loadCurrentSelection() {
    Completer<List> completer = new Completer<List>();
    AppEvent curSelectionEvent = new AppEvent(AppEvent.CURRENT_SELECTION,
        null, completer);
    _eventBus.post(curSelectionEvent);
    return completer.future;
  }

  Future<Function> _getLabelFunction() {
    Completer<Function> completer = new Completer<Function>();
    AppEvent labelFunctionEvent = new AppEvent(AppEvent.LABEL_FUNCTION,
        null, completer);
    _eventBus.post(labelFunctionEvent);
    return completer.future;
  }

}
