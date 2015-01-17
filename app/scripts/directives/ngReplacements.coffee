app = require '../app.coffee'
###
  Mostly direct ports with some tweaks from angular
###
eventDirectives = {}
SPECIAL_CHARS_REGEXP = /([\:\-\_]+(.))/g
MOZ_HACK_REGEXP = /^moz([A-Z])/
PREFIX_REGEXP = /^((?:x|data)[\:\-_])/i


###*
Converts snake_case to camelCase.
Also there is special case for Moz prefix starting with upper case letter.
@param name Name to normalize
###
camelCase = (name) ->
  name.replace(SPECIAL_CHARS_REGEXP, (_, separator, letter, offset) ->
    (if offset then letter.toUpperCase() else letter)
  ).replace MOZ_HACK_REGEXP, "Moz$1"

###*
Converts all accepted directives format into proper directive name.
@param name Name to normalize
###
directiveNormalize = (name) ->
  camelCase name.replace(PREFIX_REGEXP, "")

capitalize = (str) ->
  str.replace /^./, (match) ->
    match.toUpperCase()

# For events that might fire synchronously during DOM manipulation
# we need to execute their event handlers asynchronously using $evalAsync,
# so that they are not executed in an inconsistent state.
forceAsyncEvents =
  blur: true
  focus: true

$parseQuick = (dotPropString , scope) ->
  toFind = undefined
  dotPropString.split('.').forEach (path) ->
    newRoot = if not toFind then scope else toFind
    toFind = newRoot[path]
  toFind

'click dblclick mousedown mouseup mouseover mouseout mousemove mouseenter mouseleave keydown keyup keypress submit focus blur copy cut paste'
.split(' ')
.forEach (eventName) ->
  directiveName = directiveNormalize('rmaps-' + eventName)
  valuePropName = 'rmapsValueName' + capitalize(eventName)
  eventDirectives[directiveName] = ['$parse', '$rootScope', 'Logger'.ourNs(), ($parse, $rootScope, $log) ->

    restrict: 'A'
#    scope: _scope

    link:(scope, element, attrs) ->
      elementScope = element.scope()
      element.on 'destroy', ->
        $log.debug 'destroyed'
        element.unbind eventName

      element.bind eventName, (event) ->
        fnNameToFind = attrs[directiveName]
        fn = $parseQuick fnNameToFind, elementScope
        $log.error "failed to find function for #{directiveName} to prop #{fnNameToFind}" unless fn

        callback = ->
          fn($parseQuick(attrs[valuePropName], element.scope()), $event: event)

        if forceAsyncEvents[eventName] and $rootScope.$$phase
          scope.$evalAsync callback
        else
          scope.$apply callback
  ]


app.directive eventDirectives
