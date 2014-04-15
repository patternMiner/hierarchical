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

  @NgOneWay('paths')
  Iterable paths;

  ListComponent(this._selectionController);

  bool isLeaf(path) => _selectionController.isLeaf(path);
  bool hasChildren(path) => getChildren(path).isNotEmpty;
  bool isExpanded(path) => _selectionController.isExpanded(path);
  Iterable getChildren(path) => _selectionController.children(path);

  String getLabelTemplateMarkup(MenuItem path) {
    if (_selectionController.isLinear) {
      return "<div style='display: flex; flex-direction: row; flex: 1 1 auto;'>"
             "<div style='flex: 1 1 auto;'>${getValue(path).toString()}</div>"
             "<div style='flex: none; width: 20px;'>&nbsp;</div>"
             "<div style='flex: none; width: 200px; color: #999999;'>"
                  "${getAncestry(path).toString()}</div>"
             "</div>";
    }
    return "<div>${getValue(path).toString()}</div>";
  }

  static dynamic getValue(MenuItem path) => path.components.last;
  static dynamic getAncestry(MenuItem path) =>
      path.components.reversed.skip(1).join(' > ');

  /// show the active item as active, if any.
  String getStyle(path, index) =>
      _selectionController.isActive(path) ? 'list-item-selected' : 'list-item';

  void onMouseEnter(MenuItem path, MouseEvent event) {
    _selectionController.markPathForSelection(path);
  }

  void onMouseLeave(MenuItem path, MouseEvent event) {
    _selectionController.markPathForSelection(null);
  }

  void onMouseClick(MenuItem path, MouseEvent event) {
    if (_selectionController.multiSelect) {
      _selectionController.toggleSelection(path);
    } else {
      if (_selectionController.commitSelection()) {
        return _selectionController.notifySelections();
      }
    }
    event.stopPropagation();
    event.preventDefault();
  }
}
