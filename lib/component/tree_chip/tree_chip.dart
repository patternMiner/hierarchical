library tree_chip;

import 'dart:html';
import 'package:angular/angular.dart';

@NgComponent(
    selector: 'tree-chip',
    templateUrl: '../lib/component/tree_chip/tree_chip.html',
    applyAuthorStyles: true,
    publishAs: 'ctrl'
)
class TreeChipComponent {

  @NgOneWayOneTime('title')
  String title;

  @NgOneWayOneTime('items')
  Iterable items;

  void onMouseDown(MouseEvent event) {
    Element element = event.target as Element;
    bool isOverflow = element.scrollWidth > element.clientWidth ||
        element.scrollHeight > element.clientHeight;
    if (isOverflow) {
      int scrollbarWidth = element.offsetWidth - element.clientWidth;
      Rectangle bounds = element.getBoundingClientRect();

      double maxX = bounds.left + bounds.width;
      double minX = maxX - scrollbarWidth;
      int clientX = event.clientX;
      if (clientX >= minX && clientX <= maxX) {
        print("clicked on the scrollbar");
      }
    }
  }
}
