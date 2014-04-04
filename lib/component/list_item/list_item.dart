library list_item;

import 'package:angular/angular.dart';

import '../../component/selection_controller/selection_controller.dart';

@NgComponent(
    selector: 'list-item',
    templateUrl: '../lib/component/list_item/list_item.html',
    cssUrl: '../lib/component/list_item/list_item.css',
    publishAs: 'ctrl',
    applyAuthorStyles: true,
    visibility: NgDirective.CHILDREN_VISIBILITY
)
class ListItemComponent {

  final List _ancestors = [];
  final SelectionController _selectionController;

  @NgOneWayOneTime('item')
  var item;

  ListItemComponent(this._selectionController);

  bool get selected => _selectionController.isSelected(item);
  set selected(bool state) => _selectionController.toggleSelection(item);
  bool get expanded => _selectionController.isExpanded(item);
  Iterable get children => _selectionController.children(item);
  bool toggleExpand() => _selectionController.toggleExpansion(item);
  bool get hasChildren => children.isNotEmpty;
  bool get selectionEnabled => _selectionController.selectionEnabled;
  String get expansionState => hasChildren ?
      (expanded ? 'list-item-expanded' : 'list-item-collapsed') :
          'list-item-expand-collapse';
  bool get visible => _selectionController.isVisible(item);
  bool get hasParent => _selectionController.hasParent(item);
  String get containerClass => hasParent ? 'list-offset' : 'no-list-offset';
  Iterable get ancestors {
    _ancestors.clear();
    _ancestors.addAll(_selectionController.getAncestors(item));
    return _ancestors;
  }
}