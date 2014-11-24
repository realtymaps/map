app = require '../app.coffee'
require '../factories/filters.coffee'

###
  Our Filters Controller
###

module.exports = app.controller 'FiltersCtrl'.ourNs(), [
  '$scope', 'Filters'.ourNs(), ($scope, Filters) ->
    
    $scope.filterValues = Filters.values

]
