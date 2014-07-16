part of chip;

@Component(
    selector: 'chip-container',
    templateUrl: 'packages/hierarchical/component/'
                 'chip/chip_container.html',
    cssUrl: 'packages/hierarchical/component/'
            'chip/chip_container.css',
    publishAs: 'ctrl',
    map: const {
      'items': '=>!items',
      'on-delete': '=>!onChipDelete',
      'label-template-maker': '=>!makeLabelTemplate'
    }
)
class ChipContainerComponent {
  List items;
  Function onChipDelete;
  Function makeLabelTemplate;

  String getTemplate(item, bool selected) {
    String template = makeLabelTemplate(item, selected);
    return template;
  }
}
