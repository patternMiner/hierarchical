library list;

import 'package:angular/angular.dart';

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

  @NgOneWay('items')
  Iterable items;

  ListComponent(this._selectionController);

  bool isLeaf(item) => _selectionController.isLeaf(item);
  bool hasChildren(item) => getChildren(item).isNotEmpty;
  bool isExpanded(item) => _selectionController.isExpanded(item);
  Iterable getChildren(item) => _selectionController.children(item);
  String getLabelTemplateMarkup(item) =>
      _selectionController.getLabelTemplateMarkup(item);
}
