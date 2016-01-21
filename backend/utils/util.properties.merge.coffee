config = require '../config/config'
sqlHelpers = require './../utils/util.sql.helpers'
tables = require '../config/tables'
logger = require '../config/logger'
_ = require 'lodash'

# merge details of data in memory; no db call
_updateSavedProperties = (state, properties) ->
  _.each properties, (prop) ->
    # ensure saved details are part of the saved props
    if state.properties_selected?[prop.rm_property_id]?
      prop.savedDetails = state.properties_selected[prop.rm_property_id]
  properties


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
  query = sqlHelpers.select(tables.property.propertyDetails(), 'filter', false)

  if limit
    query.limit(limit)

  sqlHelpers.whereIn(query, 'rm_property_id', missingProperties)
  sqlHelpers.whereInBounds(query, 'geom_polys_raw', filters.bounds)
  query

_maybeMergeSavedProperties = (state, filters, filteredProperties, limit) ->
  if !state?.properties_selected || _.keys(state.properties_selected).length == 0 || !filters?.bounds?
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
  updateSavedProperties: _updateSavedProperties
  maybeMergeSavedProperties: _maybeMergeSavedProperties
  getMissingProperties: _getMissingProperties
  savedPropertiesQuery: _savedPropertiesQuery
