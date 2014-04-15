part of hierarchical;

@NgController(
    selector: 'hierarchical-app',
    publishAs: 'app'
)
class HierarchicalApp {
  static final List<String> entities  =
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

  final MenuModel hierarchical =
      new TreeMenuModel.fromList(entities)..
      search='angle';

  final MenuModel linear =
      new ListMenuModel.fromList(entities)..
      search='angle';
}
