library hierarchical;

import 'package:angular/angular.dart';
import 'package:di/di.dart';

import 'component/chip_container/chip_container.dart';
import 'component/chip/chip.dart';
import 'component/item_placeholder/item_placeholder.dart';
import 'component/list/list.dart';
import 'component/list_item/list_item.dart';
import 'component/selection_controller/selection_controller.dart';
import 'component/tree_chip/tree_chip.dart';

part 'app/hierarchical_app.dart';

class HierarchicalModule extends Module {
  HierarchicalModule() {
    type(ChipComponent);
    type(ChipContainerComponent);
    type(HierarchicalApp);
    type(ItemPlaceholderComponent);
    type(ListComponent);
    type(ListItemComponent);
    type(SelectionController);
    type(TreeChipComponent);
  }
}
