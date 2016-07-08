app = require '../app.coffee'

app.directive 'rmapsSubinput', [ () ->
  restrict: 'E'
  scope: true
  replace: false
  template: """
            <div class="field" rmaps-droppable="field" on-drop="onDropBaseInput" ng-class="{ empty: !fieldData.current.input[field] }">
              <span>{{name}}:</span>
              <span ng-show="fieldData.current.input[field]">{{fieldData.current.input[field]}}</span>
              <span class="remove-icon" ng-show="fieldData.current.input[field]" ng-click="removeBaseInput(field)">X</span>
            </div>
            """
  link: (scope, element, attrs) ->
    scope.name = attrs.name
    scope.field = attrs.field
]
