library list_item;

import 'package:angular/angular.dart';

import '../../component/tree/tree.dart';

@NgComponent(
    selector: 'list-item',
    templateUrl: '../lib/component/list_item/list_item.html',
    cssUrl: '../lib/component/list_item/list_item.css',
    publishAs: 'ctrl',
    applyAuthorStyles: true,
    visibility: NgDirective.CHILDREN_VISIBILITY
)
class ListItemComponent {

  final TreeController _treeController;

  @NgOneWayOneTime('item')
  var item;

  ListItemComponent(this._treeController);

  bool get selected => _treeController.isSelected(item);
  set selected(bool state) => _treeController.toggleSelection(item);
  bool get expanded => _treeController.isExpanded(item);
  Iterable get children => _treeController.children(item);
  bool toggleExpand() => _treeController.toggleExpansion(item);
  bool get hasChildren => children.isNotEmpty;
  bool get selectionEnabled => _treeController.selectionEnabled;
  String get expansionState => hasChildren ?
      (expanded ? 'list-item-expanded' : 'list-item-collapsed') :
          'list-item-expand-collapse';
  bool get visible => _treeController.isVisible(item);
  bool get hasParent => _treeController.hasParent(item);
  String get containerClass => hasParent ? 'list-offset' : 'no-list-offset';
}