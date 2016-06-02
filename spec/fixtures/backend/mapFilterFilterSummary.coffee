_ = require 'lodash'

module.exports = (type = 'clusterOrDefault') ->
  _.merge require('./mapFilter'),
    returnType: type
    state:
      filters:
        status: [ 'for sale', 'pending', 'sold' ]
        # any other filters like bedsMin/Max, columns, etc
