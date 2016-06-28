_ = require 'lodash'
clone = require 'clone'
require '../../common/extensions/strings'
logger = require('../config/logger.coffee').spawn('task:util:events')
notificationsSvc = require '../services/service.notifications'

processHandlers =
  notifications: notificationsSvc

###
  Private: remove dupe pins to unPins (favorites to unFavorites) as they cancel each other out

 - `rows` Event rows that are ALREADY sorted in time ASC.

 NOTE TIME ORDERING IS HIGHLY IMPORTANT or the canceling out is invalid.

  Returns properties map of rows got through.
###
_propertiesReduce = (rows) ->
  properties =
    pin: {}
    unPin: {}
    favorite: {}
    unFavorite: {}
    notes: {}

  for row in rows
    oppositeType = if /un/ig.test row.sub_type
      row.sub_type.replace(/un/ig,'').toLowerCase()
    else
      'un' + row.sub_type.toInitCaps()

    logger.debug "oppositeType: #{oppositeType}"
    if properties?[oppositeType]?[row.options.rm_property_id]?
      delete properties[oppositeType][row.options.rm_property_id]
      continue

    properties[row.sub_type][row.options.rm_property_id] = row

  properties

_propertiesFlatten = (propertiesMap) ->
  flat = []
  for k, v of propertiesMap
    for k2, row of v
      flat.push row
  flat

###
  Public: Reduce / debounce the amount of events to have less noise in notifications.

 - `rows`      Rows that have been pre-sorted by time as{Array<object<user_events_queue>>}.
 - `frequency` as {string}.

  Returns the [Description] as `undefined`.
###
propertyCompaction = (rows, frequency) ->
  rows = _propertiesFlatten _propertiesReduce rows
  logger.debug rows

  if !rows?.length
    return

  compacted = clone rows[0]

  compacted.options =
    type: compacted.type
    frequency: frequency
    properties:
      pin: []
      unPin: []
      favorite: []
      unFavorite: []
      notes: []

  ### TODO
  Pull in more data to make the email worth something.
  https://realtymaps.atlassian.net/browse/MAPD-1097
  Join data_combined and parcel for things like:
  - cdn url
  - description
  - address
  ###

  for r in rows
    logger.debug r.sub_type
    compacted.options.properties[r.sub_type].push r.options

  compacted

defaultCompaction = (rows, frequency) ->
  obj = _.merge {}, rows...
  obj.frequency = frequency
  obj

compactHandlers =
  propertySaved: propertyCompaction
  jobQueue: defaultCompaction
  default: defaultCompaction

module.exports = {
  processHandlers
  compactHandlers
}
