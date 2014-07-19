library hierarchical;

import 'package:angular/angular.dart';
import 'package:hierarchical/component/chip/chip.dart';
import 'package:hierarchical/component/item_template/item_template.dart';
import 'package:hierarchical/component/menu/menu.dart';
import 'package:hierarchical/component/shell/shell.dart';
import 'package:hierarchical/controller/menu_controller.dart';

class HierarchicalMenuModule extends Module {
  HierarchicalMenuModule() {
    bind(ChipComponent);
    bind(ChipContainerComponent);
    bind(ItemTemplateComponent);
    bind(HierarchicalMenuComponent);
    bind(HierarchicalMenuController);
    bind(MenuShellComponent);
  }
}
