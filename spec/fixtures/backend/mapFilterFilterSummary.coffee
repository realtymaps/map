_ = require 'lodash'

module.exports = (type = 'geojsonPolys') ->
  _.merge require('./mapFilter'),
    returnType: type
    state:
      filters:
        status: [ 'for sale', 'pending', 'recently sold' ]
        # any other filters like bedsMin/Max, columns, etc
