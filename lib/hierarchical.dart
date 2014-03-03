library hierarchical;

import 'dart:async';
import 'dart:collection';
import 'package:angular/angular.dart';
import 'package:di/di.dart';

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(
    targets: const ['tree', 'list', 'list_end', 'list_item'],
    override: '*')
import 'dart:mirrors';

part 'common/graph/graph.dart';
part 'common/event/app_event_bus.dart';
part 'component/list/list.dart';
part 'component/list/list_end.dart';
part 'component/list/list_item.dart';
part 'component/tree/tree.dart';

class HierarchicalModule extends Module {
  HierarchicalModule() {
    type(AppEventBus);
    type(TreeController);
    type(ListComponent);
    type(ListEndController);
    type(ListItemComponent);
  }
}
