part of hierarchical;

@NgController(
    selector: 'list-end',
    publishAs: 'listEnd'
)
class ListEndController {
  final TreeController _treeController;

  ListEndController(this._treeController) {
    _treeController.popList();
  }
}
