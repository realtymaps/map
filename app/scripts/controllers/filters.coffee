app = require '../app.coffee'
require '../factories/filters.coffee'

###
  Our Filters Controller
###

module.exports = app.controller 'FiltersCtrl'.ourNs(), [
  '$scope', 'Filters'.ourNs(), 'MapToggles'.ourNs(), ($scope, Filters, Toggles) ->
    
    #initialize values for filter options in the select tags
    $scope.filterValues = Filters.values

]
