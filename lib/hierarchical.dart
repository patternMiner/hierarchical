library hierarchical;

import 'package:angular/angular.dart';
import 'package:di/di.dart';

import 'common/event/event_bus.dart';
import 'component/chip_container/chip_container.dart';
import 'component/chip/chip.dart';
import 'component/item_placeholder/item_placeholder.dart';
import 'component/list/list.dart';
import 'component/list_item/list_item.dart';
import 'component/tree/tree.dart';
import 'component/tree_chip/tree_chip.dart';

part 'app/hierarchical_app.dart';

class HierarchicalModule extends Module {
  HierarchicalModule() {
    type(EventBus);
    type(ChipComponent);
    type(ChipContainerComponent);
    type(HierarchicalApp);
    type(ItemPlaceholderComponent);
    type(ListComponent);
    type(ListItemComponent);
    type(TreeController);
    type(TreeChipComponent);
  }
}
