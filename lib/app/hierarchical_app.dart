part of hierarchical;

@NgController(
    selector: 'hierarchical-app',
    publishAs: 'app'
)
class HierarchicalApp {
  List hierarchy = const [
      'Shape',
      const ['Open shape',
             const ['Closed shape',
                    const ['Polygon',
                           const ['Triangle', 'Quadrangle', 'Pentagon']],
                           const ['Ellipse',
                                  const ['Circle']]]]];
}
