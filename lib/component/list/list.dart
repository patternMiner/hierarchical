library list;

import 'dart:html';
import 'package:angular/angular.dart';

import '../menu_controller/menu_controller.dart';

@NgComponent(
    selector: 'list',
    templateUrl: '../lib/component/list/list.html',
    cssUrl: '../lib/component/list/list.css',
    applyAuthorStyles: true,
    publishAs: 'list'
)
class ListComponent {

  final MenuController _menuController;

  @NgOneWay('items')
  Iterable items;

  ListComponent(this._menuController);

  bool isLeaf(item) => _menuController.isLeaf(item);
  bool hasChildren(item) => getChildren(item).isNotEmpty;
  bool isExpanded(item) => _menuController.isExpanded(item);
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

  static dynamic getValue(MenuItem item) => item.components.last;
  static dynamic getAncestry(MenuItem item) =>
      item.components.reversed.skip(1).join(' > ');

  /// show the active item as active, if any.
  String getStyle(item, index) =>
      _menuController.isActive(item) ? 'list-item-selected' : 'list-item';

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
