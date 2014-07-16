library hierarchical;

import 'package:angular/angular.dart';

import 'component/chip/chip.dart';
import 'component/item_template/item_template.dart';
import 'component/menu/menu.dart';
import 'component/shell/shell.dart';
import 'component/demo/hierarchical_menu_demo.dart'; // demo component
import 'controller/menu_controller.dart';

class HierarchicalMenuModule extends Module {
  HierarchicalMenuModule() {
    bind(ChipComponent);
    bind(ChipContainerComponent);
    bind(ItemTemplateComponent);
    bind(HierarchicalMenuComponent);
    bind(HierarchicalMenuController);
    bind(MenuShellComponent);
    bind(HierarchicalMenuDemoComponent);
    bind(TreeChipComponent); // demo component
  }
}
