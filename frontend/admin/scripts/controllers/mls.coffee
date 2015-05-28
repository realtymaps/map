app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'

module.exports = app.controller 'rmapsMlsCtrl', [ '$scope', ($scope) ->
  $scope.msg = "(form and wizard)"
  $scope.adminRoutes = adminRoutes
]
