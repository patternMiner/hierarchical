library tree_chip;

import 'dart:html';
import 'package:angular/angular.dart';
import '../hierarchical_menu_controller/hierarchical_menu_controller.dart';

@Component(
    selector: 'tree-chip',
    templateUrl: '../lib/component/tree_chip/tree_chip.html',
    applyAuthorStyles: true,
    map: const {
      'title': '=>!title',
      'menu-model': '=>!model',
      'multi-select': '=>!multiSelect',
    },
    publishAs: 'ctrl'
)
class TreeChipComponent {

  String title;
  HierarchicalMenuModel _model;
  bool multiSelect = false;

  final MenuSelectionEventMediator mediator = new MenuSelectionEventMediator();

  void set model (HierarchicalMenuModel m) {
    if (m != null) {
      _model = m;
    }
  }

  HierarchicalMenuModel get model => _model;

  void onMouseDown(MouseEvent event) {
    if (isOnScrollbar(event)) {
      print("clicked on the scrollbar");
    }
  }

  bool isOnScrollbar(MouseEvent event) {
    Element element = event.target as Element;
    bool isOverflow = element.scrollWidth > element.clientWidth ||
        element.scrollHeight > element.clientHeight;
    if (isOverflow) {
      int scrollbarWidth = element.offsetWidth - element.clientWidth;
      int scrollbarHeight = element.offsetHeight - element.clientHeight;
      Rectangle bounds = element.getBoundingClientRect();
      Rectangle realBounds =
          new Rectangle(bounds.left, bounds.top,
              bounds.width - scrollbarWidth, bounds.height - scrollbarHeight);
      return !realBounds.containsPoint(event.client);
    }
    return false;
  }
}
