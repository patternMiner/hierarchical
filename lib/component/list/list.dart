library list;

import 'dart:html';
import 'package:angular/angular.dart';

import '../menu/menu.dart';

@NgComponent(
    selector: 'list',
    templateUrl: '../lib/component/list/list.html',
    cssUrl: '../lib/component/list/list.css',
    applyAuthorStyles: true,
    publishAs: 'list'
)
class ListComponent {

  final Menu _selectionController;

  @NgOneWay('items')
  Iterable items;

  ListComponent(this._selectionController);

  bool isLeaf(item) => _selectionController.isLeaf(item);
  bool hasChildren(item) => getChildren(item).isNotEmpty;
  bool isExpanded(item) => _selectionController.isExpanded(item);
  Iterable getChildren(item) => _selectionController.children(item);

  String getLabelTemplateMarkup(MenuItem item) {
    if (_selectionController.isLinear) {
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
      _selectionController.isActive(item) ? 'list-item-selected' : 'list-item';

  void onMouseEnter(MenuItem item, MouseEvent event) {
    _selectionController.markItemForSelection(item);
  }

  void onMouseLeave(MenuItem item, MouseEvent event) {
    _selectionController.markItemForSelection(null);
  }

  void onMouseClick(MenuItem item, MouseEvent event) {
    if (_selectionController.multiSelect) {
      _selectionController.toggleSelection(item);
    } else {
      if (_selectionController.commitSelection()) {
        return _selectionController.notifySelections();
      }
    }
    event.stopPropagation();
    event.preventDefault();
  }
}
