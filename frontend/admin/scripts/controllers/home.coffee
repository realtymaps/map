app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'

module.exports = app.controller 'rmapsHomeCtrl', [ '$scope', '$state', ($scope, $state) ->
  $scope.adminRoutes = adminRoutes
  $scope.$state = $state
  console.log "#### home controller"
#  debugger;
]
