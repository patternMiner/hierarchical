library list_item;

import 'dart:html';
import 'package:angular/angular.dart';

import '../../common/selection_path/selection_path.dart';
import '../../component/selection_controller/selection_controller.dart';

@NgComponent(
    selector: 'list-item',
    templateUrl: '../lib/component/list_item/list_item.html',
    cssUrl: '../lib/component/list_item/list_item.css',
    publishAs: 'ctrl',
    applyAuthorStyles: true,
    visibility: NgDirective.CHILDREN_VISIBILITY
)
class ListItemComponent {

  final List _ancestors = [];
  final SelectionController _selectionController;

  @NgOneWayOneTime('path')
  SelectionPath path;

  ListItemComponent(this._selectionController);

  bool get selected => _selectionController.isSelected(path);
  set selected(bool state) => _selectionController.toggleSelection(path);
  bool get expanded => _selectionController.isExpanded(path);
  Iterable get children => _selectionController.children(path);
  void toggleExpand(MouseEvent event) {
    _selectionController.toggleExpansion(path);
    event.stopPropagation();
    event.preventDefault();
  }
  void stopPropagation(MouseEvent event) {
    event.stopPropagation();
  }
  bool get hasChildren => children.isNotEmpty;
  String get expansionState => hasChildren ?
      (expanded ? 'list-item-expanded' : 'list-item-collapsed') :
          'list-item-expand-collapse';
  bool get visible => _selectionController.isVisible(path);
  bool get hasParent => _selectionController.hasParent(path);
  String get containerClass => hasParent ? 'list-offset' : 'no-list-offset';
  Iterable get ancestors {
    _ancestors.clear();
    _ancestors.addAll(_selectionController.getAncestors(path));
    return _ancestors;
  }
}