
import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:logging/logging.dart';

import 'package:hierarchical/component/chip/chip.dart';
import 'package:hierarchical/component/item_template/item_template.dart';
import 'package:hierarchical/component/menu/menu.dart';
import 'package:hierarchical/component/shell/shell.dart';
import 'package:hierarchical/controller/menu_controller.dart';
import 'package:hierarchical_menu_demo/hierarchical_menu_demo.dart';

class HierarchicalMenuModule extends Module {
  HierarchicalMenuModule() {
    bind(ChipComponent);
    bind(ChipContainerComponent);
    bind(ItemTemplateComponent);
    bind(HierarchicalMenuComponent);
    bind(HierarchicalMenuController);
    bind(MenuShellComponent);
    bind(HierarchicalMenuDemoComponent);
    bind(TreeChipComponent);
  }
}

void main() {
  // Configure logger
  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((LogRecord r) { print(r.message); });

  // Bootstrap Angular
  applicationFactory()
    ..addModule(new HierarchicalMenuModule())
    ..run();
}
