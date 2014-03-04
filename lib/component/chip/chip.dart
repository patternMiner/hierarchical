part of hierarchical;

@NgComponent(
    selector: 'chip',
    templateUrl: '../lib/component/chip/chip.html',
    cssUrl: '../lib/component/chip/chip.css',
    visibility: NgDirective.CHILDREN_VISIBILITY,
    publishAs: 'chip',
    applyAuthorStyles: true
)
class ChipComponent {

  @NgOneWayOneTime('item')
  var item;

  final AppEventBus _eventBus;

  ChipComponent(this._eventBus);

  void delete() {
    _eventBus.post(new AppEvent(AppEvent.CHIP_DELETED, item, null));
  }
}
