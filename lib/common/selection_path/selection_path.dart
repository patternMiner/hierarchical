library selection_path;

import 'dart:async';
import 'dart:collection';
import '../graph/graph.dart';

part 'selection_path_model.dart';
part 'selection_path_event.dart';
part 'selection_path_event_mediator.dart';

class SelectionPath {
  final List components;
  String _labelForFiltering;

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

  String _getLabelForFiltering() {
    if (_labelForFiltering == null) {
      _labelForFiltering = components.last.toString().toLowerCase();
    }
    return _labelForFiltering;
  }

  bool filter(String trimmedLowerCaseString) =>
      _getLabelForFiltering().contains(trimmedLowerCaseString);

  String toString() => _getLabelForFiltering();
}
