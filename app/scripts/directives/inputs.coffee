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

  .directive "currencyInput", ->
    restrict: "A"
    require: "ngModel"
    link: (scope, element, attrs, ctrl) ->
      ctrl.$parsers.push (inputValue) ->
        inputVal = element.val()
        
        #clearing left side zeros
        inputVal = inputVal.substr(1)  while inputVal.charAt(0) is "0"
        inputVal = inputVal.replace(/[^\d.\',']/g, "")
        point = inputVal.indexOf(".")
        inputVal = inputVal.slice(0, point + 3)  if point >= 0
        decimalSplit = inputVal.split(".")
        intPart = decimalSplit[0]
        decPart = decimalSplit[1]
        intPart = intPart.replace(/[^\d]/g, "")
        if intPart.length > 3
          intDiv = Math.floor(intPart.length / 3)
          while intDiv > 0
            lastComma = intPart.indexOf(",")
            lastComma = intPart.length  if lastComma < 0
            intPart = intPart.slice(0, lastComma - 3) + "," + intPart.slice(lastComma - 3)  if lastComma - 3 > 0
            intDiv--
        if decPart is `undefined`
          decPart = ""
        else
          decPart = "." + decPart
        res = intPart + decPart
        unless res is inputValue
          ctrl.$setViewValue res
          ctrl.$render()
        return