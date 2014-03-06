part of hierarchical;

@NgController(
    selector: 'hierarchical-app',
    publishAs: 'app'
)
class HierarchicalApp {

  final List shapes =
      const ['Shape',
             const ['Open shape'],
             const ['Closed shape',
                const ['Polygon',
                    const ['Triangle', 'Quadrangle', 'Pentagon']],
                const ['Ellipse',
                    const ['Circle']]]];

  final List collections =
      const ['Collection',
          const ['List',
             const ['Array list', 'Linked list']],
          const ['Queue',
             const ['Deque',
                const ['Linked list', 'Array deque']]]];
}
