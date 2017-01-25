app = require '../app.coffee'


###
  Logout controller
###
module.exports = app.controller 'rmapsLogoutCtrl', (
$state
$http
$timeout
$rootScope
rmapsPrincipalService
rmapsMainOptions
rmapsSpinnerService
rmapsProfilesService
rmapsLogoutFactory
) ->
  rmapsLogoutFactory().logout()
