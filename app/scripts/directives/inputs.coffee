app = require '../app.coffee'
numeral = require 'numeral'

module.exports = app

  .directive "numeral", ->
    require: "ngModel"
    link: (scope, element, attrs, ngModelCtrl) ->
      ngModelCtrl.$parsers.push (val) ->
          
        if attrs.format
          format = attrs.format
        else
          format = ""

        formattedVal = ""
        if val != "" && val != "$"
          formattedVal = numeral(val).format("'" + format + "'")
        ngModelCtrl.$setViewValue formattedVal
        ngModelCtrl.$render()
        formattedVal

      return
