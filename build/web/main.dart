import 'package:angular/application_factory.dart';
import 'package:logging/logging.dart';

import '../lib/hierarchical.dart';

void main() {
  // Configure logger
  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((LogRecord r) { print(r.message); });

  // Bootstrap Angular
  applicationFactory()
    ..addModule(new HierarchicalModule())
    ..run();
}