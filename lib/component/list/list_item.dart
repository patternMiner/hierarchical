part of hierarchical;

@NgComponent(
    selector: 'list-item',
    templateUrl: '../lib/component/list/list_item.html',
    cssUrl: '../lib/component/list/list_item.css',
    publishAs: 'ctrl',
    applyAuthorStyles: true,
    visibility: NgDirective.CHILDREN_VISIBILITY
)
class ListItemComponent {

  final TreeController _treeController;

  ListItemComponent(this._treeController) {
    _treeController.addNode(this);
  }

  bool get selected => _treeController.isSelected(this);
  set selected(bool state) => _treeController.toggleSelection(this);
  bool get expanded => _treeController.isExpanded(this);
  Iterable get children => _treeController.children(this);
  bool toggleExpand() => _treeController.toggleExpansion(this);
  bool get hasChildren => children.isNotEmpty;
  bool get treeSelectionEnabled => _treeController.treeSelectionEnabled;
  String get expansionState => hasChildren ? (expanded ? '-' : '+') : '';
  bool get visible => _treeController.isVisible(this);
  bool get hasParent => _treeController.hasParent(this);
  String get containerClass => hasParent ? 'list-offset' : 'no-list-offset';
}