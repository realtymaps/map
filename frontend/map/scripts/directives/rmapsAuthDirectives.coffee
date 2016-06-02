###global: rangy###
app = require '../app.coffee'
_ = require 'lodash'

###
  Docs for reference and to maintain with this file:
  https://realtymaps.atlassian.net/wiki/display/RD/Authorization
###

###
options =
  # flags via attr value
  disable   # permits element to show up, but disabled
  noModal   # supresses the modal if disabled element is clicked (requires disable option)
  hide      # `ng-hide` element instead of the default `ng-if` (also accounts for ng-show)

  omit      # default `ng-if`, overridden if an above option is specified

  # messaging
  message   # message to display to user
  $modal    # exposed bootstrap modal service

###


# when a user fails a directive permission below, modify the sensitive element according to options
# somewhat based on http://stackoverflow.com/questions/19224028/add-directives-from-directive-in-angularjs
restrictElement = (scope, element, attrs, options) ->

  # Assign some readable tests that are made to break possible existing expressions.
  # They're worded and exposed on directive scope so that we know whats going on in the HTML.
  scope.authDisabled = () -> true  # ng-disabled="authDisabled()"
  scope.authHidden = () -> true    # ng-hide="authHidden()"
  scope.authNotShown = () -> false    # ng-show="authNotShown()"
  scope.authRemoved = () -> false  # ng-if="authRemoved()"

  # disable option
  if options.disable

    # if we want modal (default), attached handle and click functionality
    # Dont disable it b/c then we cant click it for modal (can still apply disabled class though, below)
    if !options.noModal
      # define auth modal
      scope.authModal = (message) ->
        scope.modalTitle = "Restricted"
        scope.modalBody = message
        modalInstance = options.$modal.open
          scope: scope
          template: require('../../html/views/templates/modals/confirm.jade')()

      # hijack ng-click to give us a modal and auth message
      attrs.ngClick = "authModal('#{options.message}')"
      element.attr('ng-click', attrs.ngClick)

    # if we don't want modal, disable the button
    else
      # omit any existing angular ng-click (if not a button that we can disable, this is helpful)
      if 'ngClick' of attrs
        attrs.ngClick = null # clear
        element.removeAttr('ng-click')

      if 'ngDisabled' of attrs
        savedExpression = attrs.ngDisabled
        attrs.ngDisabled = "authDisabled() || (#{savedExpression});" # include former expression to help readability
      else
        attrs.ngDisabled = "authDisabled();"
      element.attr('ng-disabled', attrs.ngDisabled)

    # account for ui-router clicking
    if element.attr('ui-sref')
      attrs.uiSref = null
      element.removeAttr('ui-sref')

    # account for misc click handlers (like on elements like anchor)
    element.on "click", (event) ->
      event.preventDefault()

    # apply the 'disabled' class
    element.addClass('disabled')


  # in order to comprehensively `hide`, let's address both ngHide and ngShow
  if options.hide
    if 'ngHide' of attrs
      savedExpression = attrs.ngHide
      attrs.ngHide = "authHidden() || (#{savedExpression})"
    else
      attrs.ngHide = "authHidden();"
    element.attr('ng-hide', attrs.ngHide)

    if 'ngShow' of attrs
      savedExpression = attrs.ngShow
      attrs.ngShow = "authNotShown() && (#{savedExpression})"
    else
      attrs.ngShow = "authNotShown();"
    element.attr('ng-show', attrs.ngShow)


  # default omit, ng-if
  if options.omit
    if 'ngIf' of attrs
      savedExpression = attrs.ngIf
      attrs.ngIf = "authRemoved() && (#{savedExpression})"
    else
      attrs.ngIf = "authRemoved();"
    element.attr('ng-if', attrs.ngIf)


# return an options object parsed from directive attribute value
getOptions = (flags = "") ->
  {
    disable: /disable/.test flags
    noModal: /^(?=.*disable)(?=.*noModal).*$/.test flags # noModal used with `disable` option (any order)
    hide: /hide/.test flags
    omit: !flags # default, expect something on element like `ng-if="false"`
  }


# require the logged user to be a designated editor on current project
app.directive 'rmapsRequireProjectEditor', ($rootScope, $log, $compile, $modal) ->
  restrict: 'A'
  terminal: true
  priority: 1000
  link: (scope, element, attrs) ->
    if !$rootScope.principal.isProjectEditor()

      # options and services to pass around
      optionalFlags = attrs.rmapsRequireProjectEditor
      options = _.merge getOptions(optionalFlags),
        message: "You must be the editor of your current project to do that."
        $modal: $modal

      # restriction logic
      restrictElement(scope, element, attrs, options)

    # suppress recursive calls, then compile
    element.removeAttr('rmaps-require-project-editor')
    $compile(element)(scope)


# require the logged user to be an active subscriber
app.directive 'rmapsRequireSubscriber', ($rootScope, $log, $compile, $modal) ->
  restrict: 'A'
  terminal: true
  priority: 1000
  link: (scope, element, attrs) ->
    if !$rootScope.principal.isSubscriber()

      # options and services to pass around
      optionalFlags = attrs.rmapsRequireSubscriber
      options = _.merge getOptions(optionalFlags),
        message: "You must have a paid subscription to do that."
        $modal: $modal

      # restriction logic
      restrictElement(scope, element, attrs, options)

    # suppress recursive calls, then compile
    element.removeAttr('rmaps-require-subscriber')
    $compile(element)(scope)

