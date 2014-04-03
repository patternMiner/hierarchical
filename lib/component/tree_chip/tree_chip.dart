library tree_chip;

import 'dart:html';
import 'package:angular/angular.dart';
import '../../common/mediator/selection_mediator.dart';
import '../../component/selection_controller/selection_controller.dart';

@NgComponent(
    selector: 'tree-chip',
    templateUrl: '../lib/component/tree_chip/tree_chip.html',
    applyAuthorStyles: true,
    publishAs: 'ctrl'
)
class TreeChipComponent {

  @NgOneWayOneTime('title')
  String title;
  @NgOneWayOneTime('selection-path-model')
  SelectionPathModel model = new SelectionPathModel();

  final SelectionMediator mediator = new SelectionMediator();

  void onMouseDown(MouseEvent event) {
    if (isOnScrollbar(event)) {
      print("clicked on the scrollbar");
    }
  }

  String getTemplateMarkup(SelectionPath item) {
    return "<div>${getValue(item)}</div>";
  }

  getValue(SelectionPath item) => item.components.last;

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
