app = require '../app.coffee'

app.directive 'rmapsJsonInput', [ () ->
  {
    restrict: 'A'
    require: 'ngModel'
    link: (scope, element, attrs, ctrl) ->

      element[0].focus()
      element[0].select()

      onBlur = () ->
        if ctrl.$invalid
          scope.$emit attrs['rmapsJsonInputCancel']
        else
          scope.$emit attrs['rmapsJsonInputCommit']

      element.bind 'blur', onBlur

      ctrl.$parsers.push (viewValue) ->
        try
          parsed = JSON.parse viewValue
          ctrl.$setValidity 'json', true
          parsed
        catch ex
          if ex instanceof SyntaxError
            ctrl.$setValidity 'json', false
            return

      ctrl.$formatters.push (value) ->
        JSON.stringify value ? '', null, 2
  }
]
