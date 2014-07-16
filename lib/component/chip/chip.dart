library chip;

import 'package:angular/angular.dart';

part 'chip_container.dart';

/**
 * ChipComponent.
 *
 * Wraps the given content neatly in a bordered-box, and provides a
 * deselect 'x' button at the right side of the box.
 *
 * The deselct button, when clicked, will call the onDelete function
 * to deselect the item.
 *
 * Sample usage:
 *
 *    <chip
 *      item="item"
 *      on-delete="ctrl.onDelete">
 *      <!-- content of the item goes here -->
 *    </chip>
 *
 */

@Component(
    selector: 'chip',
    templateUrl: 'packages/hierarchical/component/chip/chip.html',
    cssUrl: 'packages/hierarchical/component/chip/chip.css',
    map: const {
      'item': '=>!item',
      'on-delete': '=>!onDelete',
      'show-delete-icon': '=>!showDeleteIcon'
    },
    publishAs: 'ctrl'
)
class ChipComponent {
  var item;
  bool showDeleteIcon = true;
  Function onDelete;

  void delete() => onDelete != null ? onDelete(item) : null;
}
