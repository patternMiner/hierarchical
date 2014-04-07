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

  final SelectionPathModel hierarchical =
      new TreeSelectionPathModel.fromList(entities);

  final SelectionPathModel linear =
      new ListSelectionPathModel.fromList(entities);
}
