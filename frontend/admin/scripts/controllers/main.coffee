app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'

app.controller 'rmapsMainCtrl', [ '$scope', '$state', 'rmapsNormalizeService', ($scope, $state, rmapsNormalizeService) ->
  $scope.adminRoutes = adminRoutes
  $scope.$state = $state
  # using this as temporary place to test the rmapsNormalizeService services
  debugger
]
