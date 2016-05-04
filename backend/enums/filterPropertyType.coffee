_ = require 'lodash'

propertyTypes = {'Single Family', 'Condo / Townhome', 'Lots', 'Multi-Family'}

module.exports =
  enum: propertyTypes
  keys: _.keys propertyTypes

