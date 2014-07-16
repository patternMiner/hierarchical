part of menu;

class _CheckBoxModel {
  final HierarchicalMenuController _menuController;

  _CheckBoxModel(this._menuController);

  bool operator[](item) => _menuController.isSelected(item);
  void operator[]=(item, bool value) {
    _menuController.setSelectedState(item, value);
  }
}
