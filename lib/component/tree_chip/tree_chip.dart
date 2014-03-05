part of hierarchical;

@NgComponent(
    selector: 'tree-chip',
    templateUrl: '../lib/component/tree_chip/tree_chip.html',
    applyAuthorStyles: true,
    publishAs: 'ctrl'
)
class TreeChipComponent {

  @NgOneWayOneTime('title')
  String title;

  @NgOneWayOneTime('items')
  Iterable items;
}