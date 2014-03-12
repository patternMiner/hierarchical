library item_placeholder;

import 'dart:html';
import 'package:angular/angular.dart';

@NgComponent(
    selector: 'item-placeholder',
    templateUrl: '../lib/component/item_placeholder/item_placeholder.html',
    applyAuthorStyles: true,
    publishAs: 'ctrl'
)
class ItemPlaceholderComponent implements NgShadowRootAware {
  @NgOneWayOneTime('template-markup')
  String templateMarkup;

  Compiler compiler;
  Injector injector;
  Scope scope;
  DirectiveMap directives;

  ItemPlaceholderComponent(this.compiler, this.injector, this.scope,
      this.directives);

  void onShadowRoot(ShadowRoot shadowRoot) {
    DivElement placeholder = shadowRoot.querySelector("#item-placeholder");
    placeholder.appendHtml(templateMarkup);
    BlockFactory template = compiler([placeholder], directives);
    Scope childScope = scope.createChild(new PrototypeMap(scope.context));
    Injector childInjector =
        injector.createChild([new Module()..value(Scope, childScope)]);
    template(childInjector, [placeholder]);
  }

}