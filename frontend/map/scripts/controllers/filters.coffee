app = require '../app.coffee'
require '../factories/filters.coffee'

###
  Our Filters Controller
###

module.exports = app.controller 'rmapsFiltersCtrl', ($scope, rmapsFilters) ->

  #initialize values for filter options in the select tags
  $scope.filterValues = rmapsFilters.values
