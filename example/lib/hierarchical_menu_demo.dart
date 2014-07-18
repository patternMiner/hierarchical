library hierarchical_menu_demo;

import 'dart:html';
import 'dart:async';
import 'package:angular/angular.dart';

import 'package:hierarchical/model/menu_model.dart';
import 'package:hierarchical/event/menu_selection_event.dart';

part 'tree_chip.dart';

/**
 * Demo widget to promote [HierarchicalMenuController].
 *
 * Basically, the client only needs to create and configure a
 * [MenuSelectionModel] instance, and an appropriate [HierarchicalMenuModel]
 * instance, in order to use the [HierarchicalMenuController].
 */
@Component(
    selector: 'hierarchical-menu-demo',
    templateUrl: 'packages/hierarchical_menu_demo/hierarchical_menu_demo.html',
    publishAs: 'ctrl'
)
class HierarchicalMenuDemoComponent {
  bool isLinear=false, isMultiSelect=true;
  MenuModel<String> linear, hierarchical;
  MenuModelFactory<String> modelFactory = new MenuModelFactory<String>();

  static const
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
    saturday    = 'Saturday',
    other       = 'Other';

  static final Map<String, String>
    entities  = {
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
      saturday: null,
      other: null
  };

  static String getLabel(String component) => component;

  HierarchicalMenuDemoComponent() {
    linear = modelFactory.createModel(linear: true, dynamic: false,
        labelMaker: getLabel)..init(entities);
    hierarchical = modelFactory.createModel(linear: false, dynamic: false,
        labelMaker: getLabel)..init(entities);
  }
}
