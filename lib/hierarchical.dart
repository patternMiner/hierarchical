library hierarchical;

import 'dart:async';
import 'dart:collection';
import 'package:angular/angular.dart';
import 'package:di/di.dart';

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(
    targets: const ['tree', 'list', 'list_end', 'list_item', 'hierarchical_app'],
    override: '*')
import 'dart:mirrors';

part 'app/hierarchical_app.dart';
part 'common/graph/graph.dart';
part 'common/event/app_event_bus.dart';
part 'component/chip/chip.dart';
part 'component/chip/chip_container.dart';
part 'component/list/list.dart';
part 'component/list/list_item.dart';
part 'component/tree/tree.dart';

class HierarchicalModule extends Module {
  HierarchicalModule() {
    type(HierarchicalApp);
    type(AppEventBus);
    type(TreeController);
    type(ListComponent);
    type(ListItemComponent);
    type(ChipComponent);
    type(ChipContainerComponent);
  }
}
