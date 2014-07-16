library menu;

import 'package:angular/angular.dart';

import '../../model/menu_model.dart';
import '../../controller/menu_controller.dart';

part 'check_box_model.dart';

/**
 * A recursive menu component to build hierarchical menus.
 *
 * Reacts to the selection/expansion user actions with the help
 * of [HierarchicalMenuController] that gets injected during
 * component construction.
 *
 * Inputs:
 *    items: list of root [MenuItem]s, each representing either
 *           a menu item, or another menu.
 *
 * Sample usage:
 *    <menu-controller
 *        multi-select="ctrl.multiSelect"
 *        selection-mediator="ctrl.mediator"
 *        menu-model="ctrl.model">
 *      <hierarchical-menu items="menuController.roots"></hierarchical-menu>
 *    </menu-controller>
 */
@Component(
    selector: 'linear-single-select-menu',
    templateUrl: 'packages/hierarchical/component/'
                 'menu/linear_single_select.html',
    cssUrl: 'packages/hierarchical/component/menu/menu.css',
    publishAs: 'ctrl',
    map: const {
      'items': '=>items'
    },
    exportExpressions: const ['menuItem.remarks']
)
@Component(
    selector: 'linear-multi-select-menu',
    templateUrl: 'packages/hierarchical/component/'
                 'menu/linear_multi_select.html',
    cssUrl: 'packages/hierarchical/component/menu/menu.css',
    publishAs: 'ctrl',
    map: const {
      'items': '=>items'
    },
    exportExpressions: const ['menuItem.remarks']
)
@Component(
    selector: 'hierarchical-menu',
    templateUrl: 'packages/hierarchical/component/menu/menu.html',
    cssUrl: 'packages/hierarchical/component/menu/menu.css',
    publishAs: 'ctrl',
    map: const {
      'items': '=>items'
    },
    exportExpressions: const ['menuItem.remarks']
)
class HierarchicalMenuComponent {
  final HierarchicalMenuController _menuController;

  Iterable items;
  Map<MenuItem, List<MenuItem>> _ancestorsMap = <MenuItem, List<MenuItem>>{};
  _CheckBoxModel selected;

  HierarchicalMenuComponent(this._menuController) {
    selected = new _CheckBoxModel(_menuController);
  }

  bool isLeaf(MenuItem item) => _menuController.isLeaf(item);
  bool hasChildren(MenuItem item) => getChildren(item).isNotEmpty;
  bool isExpanded(MenuItem item) => _menuController.isExpanded(item);
  String getExpansionState(MenuItem item) => hasChildren(item)?
      (isExpanded(item) ? 'menu-item-expanded' : 'menu-item-collapsed') :
          'menu-item-expand-collapse';
  bool isVisible(MenuItem item) => _menuController.isVisible(item);
  Iterable getChildren(MenuItem item) => _menuController.children(item);
  String getLabelTemplate(MenuItem item) =>
      item.ghost ? _menuController.model.placeholder :
          _menuController.model.makeLabelTemplate(item, false);

  /// Returns the CSS class [item] should have.
  String getStyle(item) =>
      _menuController.isActive(item) ? 'menu-item menu-item-selected'
            : 'menu-item';

  void onMouseEnter(MenuItem item) {
    _menuController.markItemForSelection(item);
  }

  void onMouseLeave(MenuItem item) {
    _menuController.markItemForSelection(null);
  }

  void onMouseClick(MenuItem item) {
    if (_menuController.multiSelect) {
      _menuController.toggleSelection(item);
    } else if (_menuController.commitSelection()) {
      _menuController.notifySelections();
    }
  }

  void toggleExpand(MenuItem item) {
    _menuController.toggleExpansion(item);
  }

  bool get multiSelect => _menuController.selectionModel.multiSelect;

  bool get isLinear => _menuController.isLinear;

  bool hasParent(MenuItem item) => _menuController.hasParent(item);

  Iterable getAncestors(MenuItem item) {
    List<MenuItem> ancestors = _ancestorsMap.putIfAbsent(item, () => []);
    ancestors.clear();
    ancestors.addAll(_menuController.getAncestors(item));
    return ancestors;
  }
}
