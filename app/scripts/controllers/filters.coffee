app = require '../app.coffee'
require '../factories/filters.coffee'

###
  Our Filters Controller
###

module.exports = app.controller 'FiltersCtrl'.ourNs(), [
  '$scope', '$rootScope', 'Filters'.ourNs(), ($scope, $rootScope, Filters) ->
    
    #initialize values for filter options in the select tags
    $scope.filterValues = Filters.values

]
