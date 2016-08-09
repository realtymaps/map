_ = require 'lodash'

propertyTypes = {'Single Family', 'Condo / Townhome', 'Lots', 'Multi-Family'}

keys = _.keys propertyTypes

module.exports =  {
  enum: propertyTypes
  keys
  propertyTypes: keys
}
