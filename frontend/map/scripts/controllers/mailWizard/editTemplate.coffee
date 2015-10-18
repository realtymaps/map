app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsEditTemplateCtrl', ($rootScope, $scope, $state, $log, $window, rmapsprincipal) ->
  $scope.data =
    htmlcontent: "<h2>content!</h2>"
  $scope.preview = () ->
    $log.debug "#### preview()"
    preview = $window.open "", "_blank"
    preview.document.write "<html><body>#{$scope.data.htmlcontent}</body></html>"
