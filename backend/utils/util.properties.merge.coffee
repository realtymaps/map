db = require('../config/dbs').properties
config = require '../config/config'
sqlHelpers = require './../utils/util.sql.helpers'
PropertyDetails = require "../models/model.propertyDetails"
logger = require '../config/logger'

_getMissingProperties = (state, properties) ->
  return [] if !properties?.length
  matchingSavedProps = {}
  properties.forEach (row) ->
    maybeProp = state.properties_selected?[row.rm_property_id]
    if maybeProp
      row.savedDetails = maybeProp
      matchingSavedProps[row.rm_property_id] = true

  _.filter _.keys(state.properties_selected), (rm_property_id) ->
    !matchingSavedProps[rm_property_id]


_savedPropertiesQuery = (limit, filters, missingProperties) ->
  query = sqlHelpers.select(db.knex, "filter", false)
  .from(sqlHelpers.tableName(PropertyDetails))

  if limit
    #logger.sql("PropertyDetails is being limited to: #{limit}")
    query.limit(limit)

  sqlHelpers.whereIn(query, 'rm_property_id', missingProperties)
  sqlHelpers.whereInBounds(query, 'geom_polys_raw', filters.bounds)
  query

_maybeMergeSavedProperties = (state, filters, filteredProperties, limit) ->
  if !state?.properties_selected ||
      _.keys(state.properties_selected).length == 0 ||
      !filters?.bounds?
#        logger.sql "BAIL"
    return filteredProperties

  missingProperties = _getMissingProperties(state, filteredProperties)
  if missingProperties.length == 0
    # shortcut out if we've handled them all
    return filteredProperties

  _savedPropertiesQuery(limit, filters, missingProperties).then (savedProperties) ->
    savedProperties.forEach (row) ->
      # logger.debug row
      row.savedDetails = state.properties_selected[row.rm_property_id]
    return filteredProperties.concat(savedProperties)


module.exports =
  maybeMergeSavedProperties:_maybeMergeSavedProperties
  getMissingProperties: _getMissingProperties
  savedPropertiesQuery:_savedPropertiesQuery
