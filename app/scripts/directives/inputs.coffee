app = require '../app.coffee'

module.exports = app

  .directive "validNumber", ->
    require: "?ngModel"
    link: (scope, element, attrs, ngModelCtrl) ->
      return  unless ngModelCtrl
      ngModelCtrl.$parsers.push (val) ->
        clean = val.replace(/[^0-9]+/g, "")
        if val isnt clean
          ngModelCtrl.$setViewValue clean
          ngModelCtrl.$render()
        clean

      element.bind "keypress", (event) ->
        event.preventDefault()  if event.keyCode is 32
        return

      return