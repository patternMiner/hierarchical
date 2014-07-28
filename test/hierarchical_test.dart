library hierarchical_tests;

import 'dart:async';

import 'package:guinness/guinness.dart';
import 'package:angular/mock/module.dart';
import 'package:hierarchical/controller/menu_controller.dart';
import 'package:hierarchical/model/menu_model.dart';
import 'package:hierarchical/event/menu_selection_event.dart';

const
  shape       = 'Shape',
  openShape   = 'Open shape',
  closedShape = 'Closed shape',
  polygon     = 'Polygon',
  triangle    = 'Triangle',
  quadrangle  = 'Quadrangle',
  pentagon    = 'Pentagon',
  ellipse     = 'Ellipse',
  circle      = 'Circle',
  collection  = 'Collection',
  list        = 'List',
  arrayList   = 'Array list',
  linkedList  = 'Linked list',
  queue       = 'Queue',
  deque       = 'Deque',
  arrayDeque  = 'Array deque',
  sunday      = 'Sunday',
  monday      = 'Monday',
  tuesday     = 'Tuesday',
  wednesday   = 'Wednesday',
  thursday    = 'Thursday',
  friday      = 'Friday',
  saturday    = 'Saturday';

final List<List<String>> entities  = [
  [shape, openShape],
  [shape, closedShape, polygon, triangle],
  [shape, closedShape, polygon, quadrangle],
  [shape, closedShape, polygon, pentagon],
  [shape, closedShape, ellipse, circle],
  [collection, list, arrayList],
  [collection, list, linkedList],
  [collection, queue, deque, linkedList],
  [collection, queue, deque, arrayDeque],
  [sunday],
  [monday],
  [tuesday],
  [wednesday],
  [thursday],
  [friday],
  [saturday]
];

final Map<String, String>
  entitiesMap  = {
                  shape: null,
                  openShape: shape,
                  closedShape: shape,
                  polygon: closedShape,
                  triangle: polygon,
                  quadrangle: polygon,
                  pentagon: polygon,
                  ellipse: closedShape,
                  circle: ellipse,
                  collection: null,
                  list: collection,
                  arrayList: list,
                  linkedList: list,
                  queue: collection,
                  deque: queue,
                  arrayDeque: deque,
                  sunday: null,
                  monday: null,
                  tuesday: null,
                  wednesday: null,
                  thursday: null,
                  friday: null,
                  saturday: null
  };

String getLabel(String component) => component;
MenuItem makeMenuItem(List path) => new MenuItem(path, getLabel);

MenuModel initHierarchy(MenuModel model, List paths) =>
  model..init(entitiesMap);

void testTreeMenuModel() {
  describe('TreeMenuModel:', () {
    MenuModel<String> model;
    MenuModelFactory<String> modelFactory = new MenuModelFactory<String>();
    TestBed _tb;

    beforeEach(setUpInjector);
    afterEach(tearDownInjector);

    beforeEach((TestBed tb) {
      _tb = tb;
      model = initHierarchy(
          modelFactory.createStaticTreeModel(labelMaker: getLabel), entities);
    });

    it('must have the correct structure of '
        '9 roots, 23 filtered items etc.', async(() {
      expect(model.roots.length, 9);
      expect(model.filteredItems.length, 23);
      expect(model.isLinear, false);
      expect(model.getAncestors(makeMenuItem(
          [shape, closedShape, ellipse, circle])).length, 3);
      expect(model.getDescendants(makeMenuItem(
          [shape, closedShape])).length, 6);
      expect(model.hasParent(makeMenuItem([shape, closedShape])), true);
      expect(model.hasParent(makeMenuItem([sunday])), false);
    }));

    it('must have an empty entry at the beginning when "showDeselectOption"'
       'is set to true.', async(() {
      model.showDeselectOption = true;
      model.reset();
      expect(model.roots.length, 9);
      expect(model.filteredItems.length, 24);
      expect(model.isLinear, false);
      expect(model.getChildren(makeMenuItem([shape])).length, 2);
      expect(model.getAncestors(makeMenuItem(
          [shape, closedShape, ellipse, circle])).length, 3);
      expect(model.getDescendants(makeMenuItem(
          [shape, closedShape])).length, 6);
      expect(model.hasParent(makeMenuItem([shape, closedShape])), true);
      expect(model.hasParent(makeMenuItem([sunday])), false);
    }));

    it('must filter the items correctly according to the user input.',
       async(() {
      model.search = 'shape';
      expect(model.roots.length, 1);
      expect(model.filteredItems.length, 3);
      expect(model.isLinear, false);
      expect(model.getChildren(makeMenuItem([shape])).length, 2);
      expect(model.hasParent(makeMenuItem([shape, openShape])), true);
      expect(model.hasParent(makeMenuItem([shape, closedShape])), true);
    }));

    it('must filter the items correctly according to the user input.',
        async(() {
      model.search = 'shape';
      expect(model.filteredItems.length, 3);
      expect(model.isLinear, false);
    }));

    it('must search the items according to the user input.',
        async(() {
      model.search = 'list';
      expect(model.filteredItems.length, 4);
      expect(model.isLinear, false);
    }));
  });
}

void testListMenuModel() {
  describe('ListMenuModel:', () {
    MenuModel<String> model;
    MenuModelFactory<String> modelFactory = new MenuModelFactory<String>();
    TestBed _tb;

    beforeEach(setUpInjector);
    afterEach(tearDownInjector);

    beforeEach((TestBed tb) {
      _tb = tb;
      model = initHierarchy(
          modelFactory.createStaticListModel(labelMaker: getLabel), entities);
    });

    it('must have the correct structure of '
        '23 roots, 23 filtered items etc.', async(() {
      expect(model.roots.length, 23);
      expect(model.filteredItems.length, 23);
      expect(model.isLinear, true);
      expect(model.getChildren(makeMenuItem([shape])).length, 0);
      expect(model.getAncestors(makeMenuItem(
          [shape, closedShape, ellipse, circle])).length, 0);
      expect(model.getDescendants(makeMenuItem(
          [shape, closedShape])).length, 0);
      expect(model.hasParent(makeMenuItem([shape, closedShape])), false);
      expect(model.hasParent(makeMenuItem([sunday])), false);
    }));

    it('must have an empty entry at the beginning when "showDeselectOption"'
       'is set to true.', async(() {
      model.showDeselectOption = true;
      model.reset();
      expect(model.roots.length, 24);
      expect(model.filteredItems.length, 24);
      expect(model.isLinear, true);
    }));

    it('must filter the items correctly according to the user input.',
       async(() {
      model.search = 'shape';
      expect(model.roots.length, 3);
      expect(model.filteredItems.length, 3);
      expect(model.isLinear, true);
      expect(model.getChildren(makeMenuItem([shape])).length, 0);
      expect(model.getAncestors(makeMenuItem(
          [shape, closedShape, ellipse, circle])).length, 0);
      expect(model.getDescendants(makeMenuItem(
          [shape, closedShape])).length, 0);
      expect(model.hasParent(makeMenuItem([shape, openShape])), false);
      expect(model.hasParent(makeMenuItem([shape, closedShape])), false);
    }));

    it('must search the items according to the user input.', async(() {
      model.search = 'list';
      expect(model.roots.length, 3);
      expect(model.filteredItems.length, 3);
      expect(model.isLinear, true);
      expect(model.getChildren(makeMenuItem([collection])).length, 0);
      expect(model.getChildren(makeMenuItem([collection, list])).length, 0);
      expect(model.getChildren(makeMenuItem([collection, queue])).length, 0);
      expect(model.getChildren(makeMenuItem(
          [collection, queue, deque])).length, 0);
    }));
  });
}

void testHierarchicalMenuController() {
  describe('HierarchicalMenuController:', () {
    HierarchicalMenuController ctrl;
    MenuModelFactory<String> modelFactory = new MenuModelFactory<String>();
    MenuModel model;
    MenuSelectionModel selectionModel;
    TestBed _tb;

    beforeEach(setUpInjector);
    afterEach(tearDownInjector);

    beforeEach((TestBed tb) {
      _tb = tb;
    });

    describe('TreeMenuModel: SingleSelect:', () {
      beforeEach(() {
        ctrl = new HierarchicalMenuController();
        ctrl.model = initHierarchy(
            modelFactory.createStaticTreeModel(labelMaker: getLabel), entities);
        ctrl.selectionModel =
            new MenuSelectionModel(new MenuSelectionEventMediator());
      });

      it('must have the correct structure of '
         '9 roots, 23 filtered items etc.',
          async(() {
        expect(ctrl.roots.length, 9);
        expect(ctrl.isLinear, false);
        expect(ctrl.children(makeMenuItem([shape])).length, 2);
        expect(ctrl.getAncestors(makeMenuItem(
            [shape, closedShape, ellipse, circle])).length, 3);
        expect(ctrl.hasParent(makeMenuItem([shape, closedShape])), true);
        expect(ctrl.hasParent(makeMenuItem([sunday])), false);
      }));

      it('must have an empty entry at the beginning when "showDeselectOption"'
         'is set to true.',
          async(() {
        ctrl.model.showDeselectOption = true;
        ctrl.model.reset();
        expect(ctrl.roots.length, 9);
        expect(ctrl.isLinear, false);
        expect(ctrl.children(makeMenuItem([shape])).length, 2);
        expect(ctrl.getAncestors(makeMenuItem(
            [shape, closedShape, ellipse, circle])).length, 3);
        expect(ctrl.hasParent(makeMenuItem([shape, closedShape])), true);
        expect(ctrl.hasParent(makeMenuItem([sunday])), false);
      }));

      it('must expand/collapse the correct node when the expand operation'
         ' is performed on an item',
          async(() {
        expect(ctrl.isExpanded(makeMenuItem([shape])), false);
        expect(ctrl.isVisible(makeMenuItem([shape, closedShape])), false);

        ctrl.toggleExpansion(makeMenuItem([shape]));
        expect(ctrl.isExpanded(makeMenuItem([shape])), true);
        expect(ctrl.isVisible(makeMenuItem([shape, closedShape])), true);

        ctrl.toggleExpansion(makeMenuItem([shape]));
        expect(ctrl.isExpanded(makeMenuItem([shape])), false);
        expect(ctrl.isVisible(makeMenuItem([shape, closedShape])), false);
      }));

      it('must select/deselect the correct node when the select operation'
         ' is performed on an item',
          async(() {
        ctrl.toggleExpansion(makeMenuItem([shape]));
        expect(ctrl.isSelected(makeMenuItem([shape, closedShape])), false);

        ctrl.toggleSelection(makeMenuItem([shape, closedShape]));
        expect(ctrl.isSelected(makeMenuItem([shape, closedShape])), true);

        ctrl.toggleSelection(makeMenuItem([shape, closedShape]));
        expect(ctrl.isSelected(makeMenuItem([shape, closedShape])), false);
      }));
    });

    describe('TreeMenuModel: MultiSelect:', () {
      beforeEach(async(() {
        ctrl = new HierarchicalMenuController();
        ctrl.model = initHierarchy(
            modelFactory.createStaticTreeModel(labelMaker: getLabel), entities);
        ctrl.selectionModel =
            new MenuSelectionModel(new MenuSelectionEventMediator());
        ctrl.selectionModel.multiSelect = true;
      }));

      it('must select/deselect the correct item when the select operation'
         ' is performed on an item',
          async(() {

        void subtreeSelectionChecker(HierarchicalMenuController ctrl,
                                     MenuItem root, bool state) {
          expect(ctrl.isSelected(root), state);
          ctrl.model.getDescendants(root).forEach((MenuItem item) =>
              expect(ctrl.isSelected(item), state));
        }

        // Initial state. The item is unselected
        expect(ctrl.isSelected(makeMenuItem([shape, closedShape])), false);

        // State after 'closedShape' is selected. The item is selected.
        ctrl.toggleSelection(makeMenuItem([shape, closedShape]));
        expect(ctrl.isSelected(makeMenuItem([shape, closedShape])), true);

        // State after 'closedShape' is de-selected. The item is de-selected.
        ctrl.toggleSelection(makeMenuItem([shape, closedShape]));
        expect(ctrl.isSelected(makeMenuItem([shape, closedShape])), false);
      }));
    });
  });
}

/**
 * Test the interface to the [MenuSelectionEventMediator] of the
 * [GtHierarchicalMenuController].
 */
void testMenuSelectionEventMediator() {
  describe('MenuSelectionEventMediator:', () {
    HierarchicalMenuController ctrl;
    MenuModelFactory<String> modelFactory = new MenuModelFactory<String>();
    MenuModel model;
    MenuSelectionModel selectionModel;
    TestBed _tb;

    beforeEach(setUpInjector);
    afterEach(tearDownInjector);

    beforeEach((TestBed tb) {
      _tb = tb;
    });

    describe('MenuSelectionEventMediator: MultiSelect:', () {
      beforeEach(async(() {
        ctrl = new HierarchicalMenuController();
        ctrl.model = initHierarchy(
            modelFactory.createStaticTreeModel(labelMaker: getLabel), entities);
        ctrl.selectionModel =
            new MenuSelectionModel(new MenuSelectionEventMediator());
        ctrl.selectionModel.multiSelect = true;
      }));

      it('must notify the correct selected item when the select operation'
          ' is performed on an item', async(() {
        List<MenuItem> selectedItems = <MenuItem>[];
         StreamSubscription subscription = ctrl.mediator.onSelectionEvent().
            listen((MenuSelectionEvent event) {
          switch(event.type) {
            case MenuSelectionEvent.SELECTION_CHANGED:
              selectedItems.clear();
              selectedItems.addAll(event.data);
              return;
          }
        });

        // Initial state
        expect(selectedItems.length, 0);

        // State after the selection of an item.
        ctrl.toggleSelection(makeMenuItem([shape, closedShape]));
        microLeap();
        expect(selectedItems.length, 7);

        // State after the deselection of an item.
        ctrl.toggleSelection(makeMenuItem([shape, closedShape]));
        microLeap();
        expect(selectedItems.length, 0);

        subscription.cancel();
      }));

      it('must deselect the correct item when the deselect operation'
          ' is performed on an item using the MenuSelectionEvent.', async(() {
        List<MenuItem> selectedItems = <MenuItem>[];
        // Setup a listener to observe the selection change events
        // on the mediator.
        StreamSubscription subscription = ctrl.mediator.onSelectionEvent().
            listen((MenuSelectionEvent event) {
          switch(event.type) {
            case MenuSelectionEvent.SELECTION_CHANGED:
              selectedItems.clear();
              selectedItems.addAll(event.data);
              return;
          }
        });

        ctrl.attach();

        // Initial state
        expect(selectedItems.length, 0);

        // State after the selection of a subtree.
        ctrl.mediator.post(new MenuSelectionEvent(
            MenuSelectionEvent.SET_SELECTION, null,
            [makeMenuItem([shape, closedShape])], null));
        microLeap();

        Completer completer = new Completer();
        completer.future.then((Iterable<MenuItem> selections) {
          selectedItems.clear();
          selectedItems.addAll(selections);
        });

        ctrl.mediator.post(new MenuSelectionEvent(
            MenuSelectionEvent.GET_CURRENT_SELECTION, null, null, completer));
        microLeap();

        expect(selectedItems.length, 1);

        // State after the deselection of a subtree.
        ctrl.mediator.post(new MenuSelectionEvent(MenuSelectionEvent.DESELECT,
            null, makeMenuItem([shape, closedShape]), null));
        microLeap();

        expect(selectedItems.length, 0);

        subscription.cancel();
        ctrl.detach();
      }));
    });
  });
}

main() {
  testTreeMenuModel();
  testListMenuModel();
  testHierarchicalMenuController();
  testMenuSelectionEventMediator();
}
