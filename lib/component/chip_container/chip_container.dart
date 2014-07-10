library chip_container;

import 'dart:async';
import 'package:angular/angular.dart';

import '../hierarchical_menu_controller/hierarchical_menu_controller.dart';

@Component(
    selector: 'chip-container',
    templateUrl: '/packages/hierarchical/component/chip_container'
                 '/chip_container.html',
    cssUrl: '/packages/hierarchical/component/chip_container'
            '/chip_container.css',
    map: const {
      'selection-mediator': '=>!mediator',
      'get-label-template-markup': '=>!getLabelTemplateMarkup'
    },
    publishAs: 'chips'
)
class ChipContainerComponent implements AttachAware, DetachAware {

  MenuSelectionEventMediator mediator;
  Function getLabelTemplateMarkup = (MenuItem path) =>
      "<div>${path.components.last.toString()}</div>";

  var list = [];
  StreamSubscription<MenuSelectionEvent> _subscription;

  void attach() {
    _cancelSubscription();
    _subscription = mediator.onSelectionEvent().
        listen((MenuSelectionEvent event) {
      switch(event.type) {
        case MenuSelectionEvent.SELECTION_CHANGED:
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
      MenuSelectionEvent curSelectionEvent =
          new MenuSelectionEvent(MenuSelectionEvent.GET_CURRENT_SELECTION, this,
              null, completer);
      mediator.post(curSelectionEvent);
    }
    return completer.future;
  }

  void onDelete(item) {
    if (mediator != null) {
      mediator.post(new MenuSelectionEvent(MenuSelectionEvent.DESELECT, this,
          item, null));
    }
  }
}
