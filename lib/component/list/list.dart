library list;

import 'package:angular/angular.dart';

import '../../component/tree/tree.dart';

@NgComponent(
    selector: 'list',
    templateUrl: '../lib/component/list/list.html',
    cssUrl: '../lib/component/list/list.css',
    applyAuthorStyles: true,
    publishAs: 'list'
)
class ListComponent {
  final TreeController _treeController;

  @NgOneWayOneTime('items')
  Iterable items;

  ListComponent(this._treeController);

  bool isLeaf(item) => _treeController.isLeaf(item);
  bool hasChildren(item) => getChildren(item).isNotEmpty;
  bool isExpanded(item) => _treeController.isExpanded(item);
  Iterable getChildren(item) => _treeController.children(item);
  String getTemplateMarkup(item) => _treeController.getTemplateMarkup(item);
}
