app = require '../app.coffee'

app.directive 'rmapsListInput', [ () ->
    {
        restrict: 'A'
        priority: 100
        require: 'ngModel'
        link: (scope, element, attr, ctrl) ->
          ctrl.$parsers.push (viewValue) ->
            if viewValue
              if attr.rmapsListInput != 'multi'
                result = viewValue.split /\s*,\s*/
              else
                result = viewValue.split(/\s*\n\s*/).map (r) ->
                  r.split /\s*,\s*/
              console.log result
              result
          ctrl.$formatters.push (value) ->
            if angular.isArray(value)
              if attr.rmapsListInput != 'multi'
                value.map (r) ->
                  r.join ', '
                .join '\n'
              else
                r.join ', '
    }
]
