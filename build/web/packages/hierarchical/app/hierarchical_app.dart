part of hierarchical;

@Controller(
    selector: 'hierarchical-app',
    publishAs: 'app'
)
class HierarchicalApp {
  static final List entities  =
      const [
          const ['Shape',
              const ['Open shape'],
              const ['Closed shape',
                  const ['Polygon',
                      const ['Triangle', 'Quadrangle', 'Pentagon']],
                  const ['Ellipse',
                      const ['Circle']]]],
          const ['Collection',
              const ['List',
                const ['Array list', 'Linked list']],
              const ['Queue',
                const ['Deque',
                    const ['Linked list', 'Array deque']]]],
          const ['Sunday', 'Monday', 'Tuesday', 'Wednesday',
                 'Thursday', 'Friday', 'Saturday']];

  static final List<List<String>> components  = [
    ['Shape', 'Open shape'],
    ['Shape', 'Closed shape', 'Polygon', 'Triangle'],
    ['Shape', 'Closed shape', 'Polygon', 'Quadrangle'],
    ['Shape', 'Closed shape', 'Polygon', 'Pentagon'],
    ['Shape', 'Closed shape', 'Ellipse', 'Circle'],
    ['Collection', 'List', 'Array list'],
    ['Collection', 'List', 'Linked list'],
    ['Collection', 'Queue', 'Deque', 'Linked list'],
    ['Collection', 'Queue', 'Deque', 'Array deque'],
    ['Sunday'],
    ['Monday'],
    ['Tuesday'],
    ['Wednesday'],
    ['Thursday'],
    ['Friday'],
    ['Saturday']
  ];

  final HierarchicalMenuModel hierarchical = new TreeMenuModel();

  final HierarchicalMenuModel linear = new ListMenuModel();

  HierarchicalApp() {
    components.forEach((path) {
      hierarchical.add(new MenuItem(path));
      linear.add(new MenuItem(path));
   });
  }
}
