
import'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:logging/logging.dart';

import 'package:hierarchical/hierarchical.dart';
import 'package:hierarchical_menu_demo/hierarchical_menu_demo.dart';

class HierarchicalMenuDemoModule extends Module {
  HierarchicalMenuDemoModule() {
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
    ..addModule(new HierarchicalMenuDemoModule())
    ..run();
}
