app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'

module.exports = app.controller 'rmapsMainCtrl', [ '$scope', ($scope) ->
  $scope.adminRoutes = adminRoutes
]
