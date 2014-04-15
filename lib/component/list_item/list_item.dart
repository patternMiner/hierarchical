library list_item;

import 'dart:html';
import 'package:angular/angular.dart';

import '../menu/menu.dart';

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
  final Menu _selectionController;

  @NgOneWayOneTime('item')
  MenuItem item;

  ListItemComponent(this._selectionController);

  bool get selected => _selectionController.isSelected(item);
  set selected(bool state) => _selectionController.toggleSelection(item);
  bool get expanded => _selectionController.isExpanded(item);
  Iterable get children => _selectionController.children(item);
  void toggleExpand(MouseEvent event) {
    _selectionController.toggleExpansion(item);
    event.stopPropagation();
    event.preventDefault();
  }
  void stopPropagation(MouseEvent event) {
    event.stopPropagation();
  }
  bool get multiSelect => _selectionController.multiSelect;
  bool get isLinear => _selectionController.isLinear;
  bool get hasChildren => children.isNotEmpty;
  String get expansionState => hasChildren ?
      (expanded ? 'list-item-expanded' : 'list-item-collapsed') :
          'list-item-expand-collapse';
  bool get visible => _selectionController.isVisible(item);
  bool get hasParent => _selectionController.hasParent(item);
  String get containerClass => hasParent ? 'list-offset' : 'no-list-offset';
  Iterable get ancestors {
    _ancestors.clear();
    _ancestors.addAll(_selectionController.getAncestors(item));
    return _ancestors;
  }
}