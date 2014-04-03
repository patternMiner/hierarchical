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
  final SelectionController _treeController;

  @NgOneWay('items')
  Iterable items;

  ListComponent(this._treeController);

  bool isLeaf(item) => _treeController.isLeaf(item);
  bool hasChildren(item) => getChildren(item).isNotEmpty;
  bool isExpanded(item) => _treeController.isExpanded(item);
  Iterable getChildren(item) => _treeController.children(item);
  String getTemplateMarkup(item) => _treeController.getTemplateMarkup(item);
}
