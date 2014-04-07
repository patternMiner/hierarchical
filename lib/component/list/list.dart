library list;

import 'dart:html';
import 'package:angular/angular.dart';

import '../../common/selection_path/selection_path.dart';
import '../../component/selection_controller/selection_controller.dart';

@NgComponent(
    selector: 'list',
    templateUrl: '../lib/component/list/list.html',
    cssUrl: '../lib/component/list/list.css',
    applyAuthorStyles: true,
    publishAs: 'list'
)
class ListComponent {

  final SelectionController _selectionController;

  @NgOneWay('paths')
  Iterable paths;

  ListComponent(this._selectionController);

  bool isLeaf(path) => _selectionController.isLeaf(path);
  bool hasChildren(path) => getChildren(path).isNotEmpty;
  bool isExpanded(path) => _selectionController.isExpanded(path);
  Iterable getChildren(path) => _selectionController.children(path);
  String getLabelTemplateMarkup(path) =>
      _selectionController.getLabelTemplateMarkup(path);

  /// show the active item as active, if any.
  String getStyle(path, index) =>
      _selectionController.isActive(path) ? 'list-item-selected' : 'list-item';

  void onMouseEnter(SelectionPath path, MouseEvent event) {
    _selectionController.markPathForSelection(path);
  }

  void onMouseLeave(SelectionPath path, MouseEvent event) {
    _selectionController.markPathForSelection(null);
  }

  void onMouseClick(SelectionPath path, MouseEvent event) {
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
