library list_item;

import 'dart:html';
import 'package:angular/angular.dart';

import '../menu_controller/menu_controller.dart';

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
  final MenuController _menuController;

  @NgOneWayOneTime('item')
  MenuItem item;

  ListItemComponent(this._menuController);

  bool get selected => _menuController.isSelected(item);
  set selected(bool state) => _menuController.toggleSelection(item);
  bool get expanded => _menuController.isExpanded(item);
  Iterable get children => _menuController.children(item);
  void toggleExpand(MouseEvent event) {
    _menuController.toggleExpansion(item);
    event.stopPropagation();
    event.preventDefault();
  }
  void stopPropagation(MouseEvent event) {
    event.stopPropagation();
  }
  bool get multiSelect => _menuController.multiSelect;
  bool get isLinear => _menuController.isLinear;
  bool get hasChildren => children.isNotEmpty;
  String get expansionState => hasChildren ?
      (expanded ? 'list-item-expanded' : 'list-item-collapsed') :
          'list-item-expand-collapse';
  bool get visible => _menuController.isVisible(item);
  bool get hasParent => _menuController.hasParent(item);
  String get containerClass => hasParent ? 'list-offset' : 'no-list-offset';
  Iterable get ancestors {
    _ancestors.clear();
    _ancestors.addAll(_menuController.getAncestors(item));
    return _ancestors;
  }
}