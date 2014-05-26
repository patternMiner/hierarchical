library item_placeholder;

import 'dart:html';
import 'package:angular/angular.dart';

/**
 * Helps in the transclusion of fully styled, application specific, components
 * inside other components.
 *
 * Input:
 *  template-markup:  The markup to be transcluded inside this component.
 */
@Component(
    selector: 'item-placeholder',
    templateUrl: '../lib/component/item_placeholder/item_placeholder.html',
    applyAuthorStyles: true,
    publishAs: 'ctrl'
)
class ItemPlaceholderComponent implements ShadowRootAware {
  @NgOneWayOneTime('template-markup')
  String templateMarkup;

  Compiler _compiler;
  Injector _injector;
  Scope _scope;
  DirectiveMap _directives;

  ItemPlaceholderComponent(this._compiler, this._injector, this._scope,
      this._directives);

  void onShadowRoot(ShadowRoot shadowRoot) {
    DivElement placeholder = shadowRoot.querySelector("#item-placeholder");
    placeholder.appendHtml(templateMarkup);
    ViewFactory template = _compiler([placeholder], _directives);
    Scope childScope = _scope.createChild(new PrototypeMap(_scope.context));
    Injector childInjector =
        _injector.createChild([new Module()..value(Scope, childScope)]);
    template(childInjector, [placeholder]);
  }
}