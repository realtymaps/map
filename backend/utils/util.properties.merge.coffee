db = require('../config/dbs').properties
config = require '../config/config'
sqlHelpers = require './../utils/util.sql.helpers'
PropertyDetails = require "../models/model.propertyDetails"
logger = require '../config/logger'

_maybeMergeSavedProperties = (filters, filteredProperties) ->
  if !state?.properties_selected ||
      _.keys(state.properties_selected).length == 0 ||
      !mergedSaveProps ||
      !filters?.bounds?
#        logger.sql "BAIL"
    return filteredProperties

  logger.debug 'merging saved props'
  # joining saved props to the filter data for properties that passed the filters, keeping track of which
  # ones hit so we can do further processing on the others
  matchingSavedProps = {}
  filteredProperties.forEach (row) ->
    maybeProp = state.properties_selected[row.rm_property_id]
    if maybeProp
      row.savedDetails = maybeProp
      matchingSavedProps[row.rm_property_id] = true

  # now get data for any other saved properties and join saved props to them too
  missingProperties = _.filter _.keys(state.properties_selected), (rm_property_id) ->
    !matchingSavedProps[rm_property_id]
  if missingProperties.length == 0
    # shortcut out if we've handled them all
    return filteredProperties
  query = sqlHelpers.select(db.knex, "filter", false)
  .from(sqlHelpers.tableName(PropertyDetails))

  if limit
    #logger.sql("PropertyDetails is being limited to: #{limit}")
    query.limit(limit)

  sqlHelpers.whereIn(query, 'rm_property_id', missingProperties)
  sqlHelpers.whereInBounds(query, 'geom_polys_raw', filters.bounds)
  query.then (savedProperties) ->
    savedProperties.forEach (row) ->
      row.savedDetails = state.properties_selected[row.rm_property_id]
    return filteredProperties.concat(savedProperties)


module.exports =
  maybeMergeSavedProperties:_maybeMergeSavedProperties
