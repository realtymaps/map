# code based on: http://stackoverflow.com/a/23948165/751577

app = require '../app.coffee'

events = [
  # if there are other useful events not handled natively by angular, add them here
  'load'
  'error'
]

# result of these is that you can put attributes like rmaps-onload="..." and rmaps-onerror="..." in the html, and
# you get an angular-ized version of the equivalent onload or onerror attribute.  Specifically, the expressions
# will be evaluated in the context of the current scope, and then the resulting function will be executed like an
# event handler for the given event, with the addition that angular will do a data-checking digest afterwards.  

events.forEach (eventname) ->
  app.directive "rmapsOn#{eventname}", ->
    scope:
      callback: "&rmapsOn#{eventname}"
    link: (scope, element, attrs) ->
      element.on eventname, (event) ->
        ret = callback(event)
        scope.$evalAsync () ->
          # dummy function to be sure Angular knows something happened
        return ret # return the value from the callback, in case it needs to return false and stop default event behavior
    restrict: 'A'
