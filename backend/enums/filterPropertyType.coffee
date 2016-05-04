_ = require 'lodash'

propertyTypes = {'Single Family', 'Condo', 'Co-Op'}

module.exports =
  enum: propertyTypes
  keys: _.keys propertyTypes

