library chip_container;

import 'dart:async';
import 'package:angular/angular.dart';

import '../../common/event/app_event_bus.dart';

@NgComponent(
    selector: 'chip-container',
    templateUrl: '../lib/component/chip_container/chip_container.html',
    cssUrl: '../lib/component/chip_container/chip_container.css',
    publishAs: 'chips',
    applyAuthorStyles: true
)
class ChipContainerComponent implements NgAttachAware, NgDetachAware {

  var list = [];
  Function getTemplateMarkup;
  StreamSubscription<AppEvent> _subscription;
  final AppEventBus _eventBus;

  ChipContainerComponent(this._eventBus) {
    _getTemplateMarkupFunction().then((Function getTemplateMarkup) =>
        this.getTemplateMarkup = getTemplateMarkup);
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
    AppEvent curSelectionEvent = new AppEvent(AppEvent.GET_CURRENT_SELECTION,
        this, null, completer);
    _eventBus.post(curSelectionEvent);
    return completer.future;
  }

  Future<Function> _getTemplateMarkupFunction() {
    Completer<Function> completer = new Completer<Function>();
    AppEvent templateMarkupFunctionEvent =
        new AppEvent(AppEvent.GET_TEMPLATE_MARKUP_FUNCTION, 
            this, null, completer);
    _eventBus.post(templateMarkupFunctionEvent);
    return completer.future;
  }

}
