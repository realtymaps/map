###global: rangy###
app = require '../app.coffee'
_ = require 'lodash'


# when a user fails a directive permission below, modify the sensitive element according to options
restrictElement = (scope, element, attrs, options) ->

  # Assign some readable tests that are made to break possible existing expressions.
  # They're worded and exposed on directive scope so that we know whats going on in the HTML.
  scope.authDisabled = () -> true  # ng-disabled="authDisabled()"
  scope.authHidden = () -> true    # ng-hide="authHidden()"
  scope.authNotShown = () -> false    # ng-show="authNotShown()"
  scope.authRemoved = () -> false  # ng-if="authRemoved()"

  # disable option
  if options.disable
    if 'ngDisabled' of attrs
      savedExpression = attrs.ngDisabled
      attrs.ngDisabled = "#{savedExpression} || authDisabled();" # include former expression to help readability
    else
      attrs.ngDisabled = "authDisabled();"
    element.attr('ng-disabled', attrs.ngDisabled)


  # in order to comprehensively `hide`, let's address both ngHide and ngShow
  if options.hide
    if 'ngHide' of attrs
      savedExpression = attrs.ngHide
      attrs.ngHide = "#{savedExpression} || authHidden();"
    else
      attrs.ngHide = "authHidden();"
    element.attr('ng-hide', attrs.ngHide)

    if 'ngShow' of attrs
      savedExpression = attrs.ngShow
      attrs.ngShow = "#{savedExpression} && authNotShown();"
    else
      attrs.ngShow = "authNotShown();"
    element.attr('ng-show', attrs.ngShow)


  # default omit, ng-if
  if options.omit
    if 'ngIf' of attrs
      savedExpression = attrs.ngIf
      attrs.ngIf = "#{savedExpression} && authRemoved();"
    else
      attrs.ngIf = "authRemoved();"
    element.attr('ng-if', attrs.ngIf)


# require the logged user to be a designated editor on current project
app.directive 'rmapsRequireProjectEditor', ($rootScope, $log, $compile) ->
  restrict: 'A'
  terminal: true
  priority: 1000
  link: (scope, element, attrs) ->
    # GTFO if proj editor
    if $rootScope.principal.isProjectEditor() then return

    # options assemble
    optionalFlags = attrs.rmapsRequireProjectEditor
    options =
      disable: /disable/.test optionalFlags
      hide: /hide/.test optionalFlags
      omit: !optionalFlags # default, expect something on element like `ng-if="false"`

    restrictElement(scope, element, attrs, options)
    element.removeAttr('rmaps-require-project-editor')

    $compile(element)(scope)


# require the logged user to be an active subscriber
app.directive 'rmapsRequireSubscriber', ($rootScope, $log) ->
  restrict: 'A'
  link: (scope, element, attrs, ngModel) ->
    # GTFO if subscriber
    if $rootScope.principal.isSubscriber() then return

    # options assemble
    optionalFlags = attrs.rmapsRequireSubscriber
    options =
      disable: /disable/.test optionalFlags
      hide: /hide/.test optionalFlags
      omit: !optionalFlags # default, expect something on element like `ng-if="false"`

    restrictElement(scope, element, attrs, options)
    element.removeAttr('rmaps-require-subscriber')

    $compile(element)(scope)

