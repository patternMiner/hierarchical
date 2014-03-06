library hierarchical;

import 'dart:html';
import 'dart:async';
import 'dart:collection';
import 'package:angular/angular.dart';
import 'package:di/di.dart';

part 'app/hierarchical_app.dart';
part 'common/graph/graph.dart';
part 'common/event/app_event_bus.dart';
part 'component/chip/chip.dart';
part 'component/chip/chip_container.dart';
part 'component/item_placeholder/item_placeholder.dart';
part 'component/list/list.dart';
part 'component/list/list_item.dart';
part 'component/tree/tree.dart';
part 'component/tree_chip/tree_chip.dart';

class HierarchicalModule extends Module {
  HierarchicalModule() {
    type(AppEventBus);
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
