_ = require 'lodash'

module.exports = (type = 'geojsonPolys') ->
  _.extend require('./mapFilter'),
    returnType: type
    status: [ 'for sale', 'pending', 'recently sold' ]
