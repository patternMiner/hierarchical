library hierarchical_menu_item;

import 'dart:html';
import 'package:angular/angular.dart';

import '../hierarchical_menu_controller/hierarchical_menu_controller.dart';

/**
 * A recursive menu-item component to build hierarchical menu items.
 *
 * Reacts to the selection/expansion user actions with the help
 * of [HierarchicalMenuController] menu controller that gets
 * injected during component construction.
 *
 * Inputs:
 *    item: a [MenuItem] item representing a menu item.
 *
 * Sample usage:
 *   <hierarchical-menu-item
 *       ng-class="menu.getStyle(menuItem, $index)"
 *       ng-mouseenter="menu.onMouseEnter(menuItem, $event)"
 *       ng-mouseleave="menu.onMouseLeave(menuItem, $event)"
 *       ng-click="menu.onMouseClick(menuItem, $event)"
 *       item="menuItem">
 *     <item-placeholder style="flex: 1 1 auto;"
 *         template-markup="menu.getLabelTemplateMarkup(menuItem)">
 *     </item-placeholder>
 *   </hierarchical-menu-item>
 */
@Component(
    selector: 'hierarchical-menu-item',
    templateUrl: '/packages/hierarchical/component/hierarchical_menu_item'
                 '/hierarchical_menu_item.html',
    cssUrl: '/packages/hierarchical/component/hierarchical_menu_item'
            '/hierarchical_menu_item.css',
    publishAs: 'ctrl',
    map: const {
      'item': '=>!item'
    },
    visibility: Directive.CHILDREN_VISIBILITY
)
class HierarchicalMenuItemComponent {

  final List _ancestors = [];
  final HierarchicalMenuController _menuController;

  MenuItem item;

  HierarchicalMenuItemComponent(this._menuController);

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
      (expanded ? 'menu-item-expanded' : 'menu-item-collapsed') :
          'menu-item-expand-collapse';
  bool get visible => _menuController.isVisible(item);
  bool get hasParent => _menuController.hasParent(item);
  String get containerClass => hasParent ? 'menu-offset' : 'no-menu-offset';
  Iterable get ancestors {
    _ancestors.clear();
    _ancestors.addAll(_menuController.getAncestors(item));
    return _ancestors;
  }
}