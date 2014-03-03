part of hierarchical;

@NgComponent(
    selector: 'list',
    templateUrl: '../lib/component/list/list.html',
    cssUrl: '../lib/component/list/list.css',
    publishAs: 'list'
)
class ListComponent {
  final TreeController _treeController;

  ListComponent(this._treeController) {
    _treeController.pushList();
  }
}