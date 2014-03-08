library chip;

import 'package:angular/angular.dart';
import '../../common/event/event_bus.dart';

@NgComponent(
    selector: 'chip',
    templateUrl: '../lib/component/chip/chip.html',
    cssUrl: '../lib/component/chip/chip.css',
    visibility: NgDirective.CHILDREN_VISIBILITY,
    publishAs: 'chip',
    applyAuthorStyles: true
)
class ChipComponent {

  @NgOneWayOneTime('item')
  var item;

  final EventBus _eventBus;

  ChipComponent(this._eventBus);

  void delete() {
    _eventBus.post(new Event(Event.CHIP_DELETED, this, item, null));
  }
}
