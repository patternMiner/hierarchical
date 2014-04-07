library chip_container;

import 'dart:async';
import 'package:angular/angular.dart';

import '../../common/selection_path/selection_path.dart';

@NgComponent(
    selector: 'chip-container',
    templateUrl: '../lib/component/chip_container/chip_container.html',
    cssUrl: '../lib/component/chip_container/chip_container.css',
    publishAs: 'chips',
    applyAuthorStyles: true
)
class ChipContainerComponent implements NgAttachAware, NgDetachAware {

  @NgOneWayOneTime('selection-mediator')
  SelectionPathEventMediator mediator;
  @NgOneWayOneTime('get-label-template-markup')
  Function getLabelTemplateMarkup = (SelectionPath path) =>
      "<div>${path.components.last.toString()}</div>";

  var list = [];
  StreamSubscription<SelectionPathEvent> _subscription;

  void attach() {
    _cancelSubscription();
    _subscription = mediator.onSelectionEvent().
        listen((SelectionPathEvent event) {
      switch(event.type) {
        case SelectionPathEvent.SELECTION_CHANGED:
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
    if (mediator != null) {
      SelectionPathEvent curSelectionEvent =
          new SelectionPathEvent(SelectionPathEvent.GET_CURRENT_SELECTION, this,
              null, completer);
      mediator.post(curSelectionEvent);
    }
    return completer.future;
  }

  void onDelete(item) {
    if (mediator != null) {
      mediator.post(new SelectionPathEvent(SelectionPathEvent.DESELECT, this,
          item, null));
    }
  }
}
