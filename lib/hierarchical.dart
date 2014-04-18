library hierarchical;

import 'package:angular/angular.dart';
import 'package:di/di.dart';

import 'component/chip_container/chip_container.dart';
import 'component/chip/chip.dart';
import 'component/item_placeholder/item_placeholder.dart';
import 'component/hierarchical_menu/hierarchical_menu.dart';
import 'component/hierarchical_menu_item/hierarchical_menu_item.dart';
import 'component/tree_chip/tree_chip.dart';
import 'component/hierarchical_menu_controller/hierarchical_menu_controller.dart';

part 'app/hierarchical_app.dart';

class HierarchicalModule extends Module {
  HierarchicalModule() {
    type(ChipComponent);
    type(ChipContainerComponent);
    type(HierarchicalApp);
    type(ItemPlaceholderComponent);
    type(HierarchicalMenuComponent);
    type(HierarchicalMenuItemComponent);
    type(HierarchicalMenuController);
    type(TreeChipComponent);
  }
}
