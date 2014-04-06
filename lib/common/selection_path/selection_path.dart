library selection_path;

import 'dart:async';
import '../graph/graph.dart';

part 'selection_path_model.dart';
part 'selection_path_event.dart';
part 'selection_path_mediator.dart';

class SelectionPath {
  final List components;

  SelectionPath(this.components) {
    assert(this.components != null);
  }

  SelectionPath get parent => components.length < 2 ? null :
      new SelectionPath(components.sublist(0, components.length-1));

  int  get hashCode {
    int hash = 1;
    components.forEach((value) => hash = hash * 31 + value.hashCode);
    return hash;
  }

  bool operator==(SelectionPath other) {
    if (this.components.length == other.components.length) {
      for (int i=0; i<this.components.length; i++) {
        if (this.components[i] != other.components[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}
