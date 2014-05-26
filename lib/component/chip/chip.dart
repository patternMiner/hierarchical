library chip;

import 'package:angular/angular.dart';

@Component(
    selector: 'chip',
    templateUrl: '../lib/component/chip/chip.html',
    cssUrl: '../lib/component/chip/chip.css',
    visibility: Directive.CHILDREN_VISIBILITY,
    publishAs: 'chip',
    applyAuthorStyles: true
)
class ChipComponent {
  @NgOneWayOneTime('item')
  var item;
  @NgOneWayOneTime('on-delete')
  Function onDelete;

  void delete() {
    if (onDelete != null) {
      onDelete(item);
    }
  }
}
