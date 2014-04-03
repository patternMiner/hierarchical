library chip_container;

import 'dart:async';
import 'package:angular/angular.dart';

import '../../common/mediator/selection_mediator.dart';

@NgComponent(
    selector: 'chip-container',
    templateUrl: '../lib/component/chip_container/chip_container.html',
    cssUrl: '../lib/component/chip_container/chip_container.css',
    publishAs: 'chips',
    applyAuthorStyles: true
)
class ChipContainerComponent implements NgAttachAware, NgDetachAware {

  @NgOneWayOneTime('selection-mediator')
  SelectionMediator mediator;
  @NgOneWayOneTime('get-template-markup')
  Function getTemplateMarkup;

  var list = [];
  StreamSubscription<SelectionEvent> _subscription;


  void attach() {
    _cancelSubscription();
    if (mediator != null) {
      _subscription = mediator.onSelectionEvent().listen((SelectionEvent event) {
        switch(event.type) {
          case SelectionEvent.SELECTION_CHANGED:
            list.clear();
            list.addAll(event.data);
            return;
        }
      });
    }
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
    if (mediator != null) {
      SelectionEvent curSelectionEvent =
          new SelectionEvent(SelectionEvent.GET_CURRENT_SELECTION, this,
              null, completer);
      mediator.post(curSelectionEvent);
    }
    return completer.future;
  }

  void onDelete(item) {
    if (mediator != null) {
      mediator.post(new SelectionEvent(SelectionEvent.DESELECT, this,
          item, null));
    }
  }
}
