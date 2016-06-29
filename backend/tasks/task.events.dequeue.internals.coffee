Promise = require 'bluebird'
_ = require 'lodash'
clone = require 'clone'
memoize = require 'memoizee'
util = require 'util'
require '../config/promisify.coffee'
require '../../common/extensions/strings'
logger = require('../config/logger.coffee').spawn('task:events')
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
dbs = require '../config/dbs'
sqlHelpers = require '../utils/util.sql.helpers'
dataLoadHelpers = require './util.dataLoadHelpers'


notificationsSvc = require '../services/service.notifications'
analyzeValue = require '../../common/utils/util.analyzeValue'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'

handlers =
  notifications: notificationsSvc

propertyCompaction = (rows) ->
  compacted = clone rows[0]
  {type} = compacted
  compacted.options =
    type: compacted.type
    properties:
      "#{type}": []
      "un#{type.toInitCaps()}": []

  ### TODO
  Pull in more data to make the email worth something.
  https://realtymaps.atlassian.net/browse/MAPD-1097
  Join data_combined and parcel for things like:
  - cdn url
  - description
  - address
  ###

  for r in rows
    if r.sub_type?
      combinedType = r.sub_type + r.type.toInitCaps()
    compacted.options.properties[combinedType || r.type].push r.options

  compacted

defaultCompaction = (rows) ->
  _.merge {}, rows...

compactHandlers =
  favorite: propertyCompaction
  pin: propertyCompaction
  jobQueue: defaultCompaction
  default: defaultCompaction


NUM_ROWS_TO_PAGINATE = 250
MINUTE_SLOT = 5
eventMapPromise = null

###
user_events_queue rows should only live as long as our
max notifications schedule (daily)

Therefore on the max schedule, once something has been handled it
should be dequeued / removed.
###

###
  Pagenate grouped rows which are grouped by intervals

  http://stackoverflow.com/questions/12623358/group-by-data-intervals


 - `subtask`      The main state object for a subtask {object}.
 - `frequency`    This is the intended frequency in which we will yield a dateSlot. (see inside function)
 - `[minuteSlot]` The minute which will divide our rows in time slots. {int}.

  Returns a Promise.
###
loadEvents = ({subtask, frequency, minuteSlot, doDequeue}) -> Promise.try () ->
  maxPage = subtask?.data?.numRowsToPageProcessEvents || NUM_ROWS_TO_PAGINATE

  # notifications subtasks only begin once all event subtasks are complete
  # this is dependent on the db config of jq_subtask_config
  jobQueue.queueSubsequentSubtask {
    subtask
    laterSubtaskName: frequency + 'Notifications'
  }

  jobQueue.queueSubsequentSubtask {
    subtask
    laterSubtaskName: 'doneEvents'
    manualData:
      startTime: Date.now()
  }

  dateSlot = switch frequency
    when 'daily'
      minuteSlot = 3600 * 24
      'day'
    else 'hour'

  minuteSlot ?= subtask.data?.minuteSlot || MINUTE_SLOT

  dbs.get('main').raw """
    select
      date_trunc(?, rm_inserted_time) AS hour_stump,
      (extract(minute FROM rm_inserted_time)::int / ?) AS min_slot,
      auth_user_id,
      type,
      array_agg(id) ids
    from ??
    where ?? = 'f'
    group by 1,2,3,4
    order by 1,2,3,4;
    """
  , [dateSlot, minuteSlot, tables.user.eventsQueue.tableName, "#{frequency.toLowerCase()}_processed"]
  .then ({rows}) ->

    logger.debug "@@@@@@@@@@@@@@@@@@@@@@"
    logger.debug "compactEvents rows.length to enqueue"
    # logger.debug rows, true
    logger.debug rows.length
    logger.debug "@@@@@@@@@@@@@@@@@@@@@@"

    jobQueue.queueSubsequentPaginatedSubtask {
      subtask
      totalOrList: rows
      maxPage
      laterSubtaskName: "compactEvents"
      mergeData: {doDequeue, frequency, setRefreshTimestamp:doDequeue}
    }

compactEvents = (subtask) -> Promise.try () ->
  if !subtask.data?.values?.length
    return
  {doDequeue, frequency} = subtask.data

  Promise.map subtask.data.values, (row) ->
    sqlHelpers.whereAndWhereIn tables.user.eventsQueue(),
      id: row.ids
    .then (compactRows) ->
      if !compactRows?.length
        return

      compactHandler = compactHandlers[compactRows[0].type] || compactHandlers.default
      compacted = compactHandler(compactRows)

      jobQueue.queueSubsequentSubtask {
        subtask
        manualData: {
          compacted
          ids: row.ids
          doDequeue
          frequency
        }
        laterSubtaskName: 'processEvent'
      }

###
  Process and event and handle it a specific way loosely coupled way.

  For now this will mainly just be notifications. Which are compacted via
  the previous subtask. (onDemand, daily).

  - `subtask`      The main state object for a subtask {object}.

  Returns Promise.
###
processEvent = (subtask) -> Promise.try () ->
  {compacted, doDequeue, frequency, ids} = subtask.data
  doDequeue ?= false

  eventMapPromise ?= memoize.promise () ->
    tables.config.handlersEventMap()
    .then (rows) ->
      _.indexBy rows, 'event_type'
  , maxAge: 15*60*1000 #15 min

  eventMapPromise()
  .then (eventMap) ->
    # handle event type and do whatever with it accordingly
    logger.debug eventMap, true
    logger.debug "Attempting to find handle for compacted.type: #{compacted.type}"

    logger.debug "original type: #{compacted.type}"
    type = compacted.type.replace(/un/,'').toLowerCase()
    logger.debug "base type: #{type}"

    {handler_name, handler_method, method, to_direction} = eventMap[type]

    logger.debug "Destructured eventMap via type"

    handlerObject = handlers[handler_name]

    if !frequency?
      throw new HardFail "Frequency must be defined."

    if !handlerObject?
      throw new HardFail "Unable to find matching handleObject for handler_name: #{handler_name}"

    handle = handlerObject[handler_method]

    if !handle?
      throw new HardFail "Unable to find matching handle handler_method: #{handler_method}"


    logger.debug () -> "processEvent: handling, composit: #{util.inspect compacted, depth: null}"

    options = {
      opts: {
        id: compacted.auth_user_id
        to: to_direction
        project_id: compacted.project_id
        method
        type: compacted.type
        verify: true
        verbose: true
      }
      payload: compacted.options
    }

    logger.debug "processEvent: handle options: #{util.inspect options, depth: null}"

    dbs.get("main").transaction (transaction) ->
      #TODO: add transaction to revert dequeuing when any error ocurrs
      handle options
      .then () ->
        #TODO: might want to explore using a transaction here
        # Mark as processed
        sqlHelpers.whereAndWhereIn tables.user.eventsQueue({transaction}), id: ids
        .update "#{frequency.toLowerCase()}_processed": true
      .then () ->
        if doDequeue
          logger.debug "@@@@@@@@@@@@@@@@@@@@@@"
          logger.debug "dequeuing with frequency: #{frequency}"
          logger.debug "@@@@@@@@@@@@@@@@@@@@@@"
          sqlHelpers.whereAndWhereIn tables.user.eventsQueue({transaction}), id: ids
          .where {ondemand_processed: true, daily_processed: true}
          .delete()

      .catch errorHandlingUtils.isUnhandled, (error) ->
        throw new errorHandlingUtils.PartiallyHandledError error, """
        failed to processEvent:
         handler_name: #{handler_name},
         handler_method: #{handler_method},
         compacted: #{}
        """.replace(/\n/g)
      .catch (error) ->
        throw new SoftFail(analyzeValue.getSimpleMessage(error))

doneEvents = (subtask) ->
  logger.debug "@@@@@@@@@@ doneEvents @@@@@@@@@@@@"
  logger.debug "marking lastRefreshTimestamp"
  dataLoadHelpers.setLastRefreshTimestamp(subtask)
  logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

module.exports = {
  loadEvents
  compactEvents
  processEvent
  doneEvents
  handlers
}
