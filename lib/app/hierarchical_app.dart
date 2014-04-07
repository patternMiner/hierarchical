part of hierarchical;

@NgController(
    selector: 'hierarchical-app',
    publishAs: 'app'
)
class HierarchicalApp {

  final SelectionPathModel shapes =
      new TreeSelectionPathModel.fromList(
          const ['Shape',
              const ['Open shape'],
              const ['Closed shape',
                  const ['Polygon',
                      const ['Triangle', 'Quadrangle', 'Pentagon']],
                  const ['Ellipse',
                      const ['Circle']]]]);

  final SelectionPathModel linearShapes =
      new ListSelectionPathModel.fromList(
          const ['Shape',
              const ['Open shape'],
              const ['Closed shape',
                  const ['Polygon',
                      const ['Triangle', 'Quadrangle', 'Pentagon']],
                  const ['Ellipse',
                      const ['Circle']]]]);

  final SelectionPathModel collections =
      new ListSelectionPathModel.fromList(
          const ['Collection',
              const ['List',
                 const ['Array list', 'Linked list']],
              const ['Queue',
                 const ['Deque',
                    const ['Linked list', 'Array deque']]]]);

  final SelectionPathModel nonLinearCollections =
      new TreeSelectionPathModel.fromList(
          const ['Collection',
              const ['List',
                 const ['Array list', 'Linked list']],
              const ['Queue',
                 const ['Deque',
                    const ['Linked list', 'Array deque']]]]);
}
