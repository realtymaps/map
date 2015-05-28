app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'

module.exports = app.controller 'rmapsMlsCtrl', [ '$scope', '$state', ($scope, $state) ->
  $scope.msg = "(form and wizard)"
  $scope.adminRoutes = adminRoutes
  $scope.$state = $state
  console.log "#### mls controler"
  #debugger;
]
