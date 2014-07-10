library hierarchical_menu;

import 'dart:html';
import 'package:angular/angular.dart';

import '../hierarchical_menu_controller/hierarchical_menu_controller.dart';

/**
 * A recursive menu component to build hierarchical menu items.
 *
 * Reacts to the selection/expansion user actions with the help
 * of [HierarchicalMenuController] menu controller that gets
 * injected during component construction.
 *
 * Inputs:
 *    items: list of [MenuItem] items each representing either
 *           a menu item, or another menu.
 *
 * Sample usage:
 *    <hierarchical-menu-controller multi-select="ctrl.multiSelect"
 *                                  selection-mediator="ctrl.mediator"
 *                                  menu-model="ctrl.model">
 *      <hierarchical-menu items="menuController.roots"></hierarchical-menu>
 *    </hierarchical-menu-controller>
 */
@Component(
    selector: 'hierarchical-menu',
    templateUrl: '/packages/hierarchical/component/hierarchical_menu'
                 '/hierarchical_menu.html',
    cssUrl: '/packages/hierarchical/component/hierarchical_menu'
            '/hierarchical_menu.css',
    map: const {
      'items': '=>!items'
    },
    publishAs: 'menu'
)
class HierarchicalMenuComponent {
  final HierarchicalMenuController _menuController;

  Iterable items;

  HierarchicalMenuComponent(this._menuController);

  bool isLeaf(item)          => _menuController.isLeaf(item);
  bool hasChildren(item)     => getChildren(item).isNotEmpty;
  bool isExpanded(item)      => _menuController.isExpanded(item);
  Iterable getChildren(item) => _menuController.children(item);

  String getLabelTemplateMarkup(MenuItem item) {
    if (_menuController.isLinear) {
      return "<div style='display: flex; flex-direction: row; flex: 1 1 auto;'>"
             "<div style='flex: 1 1 auto;'>${getValue(item).toString()}</div>"
             "<div style='flex: none; width: 20px;'>&nbsp;</div>"
             "<div style='flex: none; width: 200px; color: #999999;'>"
                  "${getAncestry(item).toString()}</div>"
             "</div>";
    }
    return "<div>${getValue(item).toString()}</div>";
  }

  static dynamic getValue(MenuItem item)    => item.components.last;
  static dynamic getAncestry(MenuItem item) =>
      item.components.reversed.skip(1).join(' > ');

  /// show the active item as active, if any.
  String getStyle(item, index) =>
      _menuController.isActive(item) ? 'menu-item-selected' : 'menu-item';

  void onMouseEnter(MenuItem item, MouseEvent event) {
    _menuController.markItemForSelection(item);
  }

  void onMouseLeave(MenuItem item, MouseEvent event) {
    _menuController.markItemForSelection(null);
  }

  void onMouseClick(MenuItem item, MouseEvent event) {
    if (_menuController.multiSelect) {
      _menuController.toggleSelection(item);
    } else {
      if (_menuController.commitSelection()) {
        return _menuController.notifySelections();
      }
    }
    event.stopPropagation();
    event.preventDefault();
  }
}
