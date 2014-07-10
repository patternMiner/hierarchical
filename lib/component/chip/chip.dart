library chip;

import 'package:angular/angular.dart';

@Component(
    selector: 'chip',
    templateUrl: '/packages/hierarchical/component/chip/chip.html',
    cssUrl: '/packages/hierarchical/component/chip/chip.css',
    visibility: Directive.CHILDREN_VISIBILITY,
    publishAs: 'chip',
    map: const {
      'item': '=>!item',
      'on-delete': '=>!onDelete'
    }
)
class ChipComponent {
  var item;
  Function onDelete;

  void delete() {
    if (onDelete != null) {
      onDelete(item);
    }
  }
}
