_ = require 'lodash'
require '../../common/extensions/strings'
logger = require('../config/logger').spawn('task:util:events')
tables = require('../config/tables')
notificationsSvc = require '../services/service.notifications'
profileService = require '../services/service.profiles'
propertyDetailsService = require '../services/service.properties.combined.details'
clone = require 'clone'
Promise =  require 'bluebird'

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
    pin: nulls: []
    unPin: nulls: []
    favorite: nulls: []
    unFavorite: nulls: []
    note: nulls: []
    unNote: nulls: []

  for row in rows
    oppositeType = if /un/ig.test row.sub_type
      row.sub_type.replace(/un/ig,'').toLowerCase()
    else
      'un' + row.sub_type.toInitCaps()

    logger.debug "oppositeType: #{oppositeType}"
    if properties?[oppositeType]?[row.options.rm_property_id]?
      delete properties[oppositeType][row.options.rm_property_id]
      continue

    if row.options.rm_property_id?
      properties[row.sub_type][row.options.rm_property_id] = row
    else
      properties[row.sub_type].nulls.push(row)

  properties

_propertiesFlatten = (propertiesMap) ->
  flat = []
  # coffeelint: disable=check_scope
  for k, v of propertiesMap
  # coffeelint: enable=check_scope
    for k2, row of v
      if k2 == 'nulls'
        flat = flat.concat row
        continue
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

  summary = rows[0]

  compacted =
    type: summary.type
    auth_user_id: summary.auth_user_id
    project_id: summary.project_id
    options:
      project_id: summary.project_id
      type: summary.type
      frequency: frequency
      properties:
        pin: []
        unPin: []
        favorite: []
        unFavorite: []
        note: []
        unNote: []

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


deleteCleanupHandle = (query) ->
  query.delete()

resetCleanupHandle = (query) ->
  query.update status: null

cleanupHandlers =
  propertySaved: deleteCleanupHandle
  default: resetCleanupHandle


_propertySavedUserDataExtension = ({auth_user_id, project_id}, options) ->
  logger.debug  "userDataExtensionHandlers.propertySaved"
  logger.debug "Begin _propertySavedUserDataExtension"

  q = profileService.getProfileWhere {
    "#{tables.user.profile.tableName}.auth_user_id": auth_user_id
    project_id
  }
  logger.debug "@@@@@ Profiles Query @@@@@"
  logger.debug q.toString()

  q.then (profiles) ->
    if !profiles.length
      logger.warn "_propertySavedUserDataExtension: No profile found!"
      #not throwing as this would mess up all other notifications
      return Promise.resolve(options)

    clonedOptions = clone(options)
    [profile] = profiles

    logger.debug "@@@@ profile @@@@"
    logger.debug profile

    promises = []
    # coffeelint: disable=check_scope
    for key, props of clonedOptions.properties
    # coffeelint: enable=check_scope
      for property in props
        do (property) ->
          if !property?.rm_property_id? and !property?.geometry_center?
            logger.debug 'skipping property data extension'
            return

          logger.debug "getting details to extend property data"

          query = clone(property)
          query.columns = 'all'

          promises.push(
            propertyDetailsService.getProperty {
              profile
              query
            }
            .then (detail) -> #mutate / extend clonedOptions
              property.detail = detail
          )

    Promise.all promises
    .then () ->
      clonedOptions

userDataExtensionHandlers =
  propertySaved: _propertySavedUserDataExtension
  default: (auth_user_id, options) ->
    logger.debug  "userDataExtensionHandlers.default"
    Promise.resolve(options)

notificationTypes = [
  'propertySaved'
  'jobQueue'
]


module.exports = {
  processHandlers
  compactHandlers
  cleanupHandlers
  userDataExtensionHandlers
  notificationTypes
}
