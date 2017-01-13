Promise = require 'bluebird'
_ = require 'lodash'
memoize = require 'memoizee'
util = require 'util'
require '../config/promisify.coffee'
require '../../common/extensions/strings'
logger = require('../config/logger.coffee').spawn('task:events:dequeue')
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
dbs = require '../config/dbs'
sqlHelpers = require '../utils/util.sql.helpers'
dataLoadHelpers = require './util.dataLoadHelpers'
analyzeValue = require '../../common/utils/util.analyzeValue'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
utilEvents = require './util.events.coffee'
eventMapPromise = null


NUM_ROWS_TO_PAGINATE = 250
MINUTE_SLOT = 5

eventMapPromise ?= memoize.promise () ->
  l = logger.spawn("eventMapPromise")

  eventHandleTable = tables.user.notificationEventHandle
  methodsTable = tables.user.notificationMethods

  l.debugQuery(eventHandleTable().select("*", "code_name as method")
  .join(methodsTable.tableName, "#{methodsTable.tableName}.id", "#{eventHandleTable.tableName}.method_id"))
  .then (rows) ->
    _.indexBy rows, 'event_type'
, maxAge: 60*60*1000 #1 HOUR

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
  l = logger.spawn('loadEvents')
  l.debug -> {subtask, frequency, minuteSlot, doDequeue}

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

  milliSecDay = 3600 * 24
  dateSlot = switch frequency
    when 'daily'
      minuteSlot = milliSecDay
      'day'
    when 'week'
      minuteSlot = 7 * milliSecDay
      'week'
    when 'month'
      minuteSlot = 4 * 7 * milliSecDay # ~ loose estimate
      'month'
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

    l.debug -> "@@@@@@@@@@@@@@@@@@@@@@"
    l.debug -> "compactEvents rows.length to enqueue"
    # l.debug -> rows, true
    l.debug -> rows.length
    l.debug -> "@@@@@@@@@@@@@@@@@@@@@@"

    jobQueue.queueSubsequentPaginatedSubtask {
      subtask
      totalOrList: rows
      maxPage
      laterSubtaskName: "compactEvents"
      mergeData: {doDequeue, frequency, setRefreshTimestamp:doDequeue}
    }

compactEvents = (subtask) -> Promise.try () ->
  l = logger.spawn('compactEvents')

  if !subtask.data?.values?.length
    return

  l.debug -> subtask.data
  {doDequeue, frequency} = subtask.data


  Promise.map subtask.data.values, (row) ->
    sqlHelpers.whereAndWhereIn tables.user.eventsQueue(),
      id: row.ids
    .orderBy('rm_inserted_time')
    .then (compactRows) ->
      if !compactRows?.length
        return

      compactHandler = utilEvents.compactHandlers[compactRows[0].type] || utilEvents.compactHandlers.default
      compacted = compactHandler(compactRows, frequency)

      if !compacted
        logger.debug '@@@@ nothing compacted, nothing to process @@@@'
        return

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
  l = logger.spawn('processEvent')

  {compacted, doDequeue, frequency, ids} = subtask.data
  l.debug -> {compacted, doDequeue, frequency, ids}

  {type} = compacted
  doDequeue ?= false

  eventMapPromise()
  .then (eventMap) ->
    # handle event type and do whatever with it accordingly
    l.debug -> eventMap
    l.debug -> "Attempting to find handle for compacted.type: #{compacted.type}"

    {handler_name, handler_method, method, to_direction} = eventMap[type]

    l.debug -> "Destructured eventMap via type"
    l.debug -> {handler_name, handler_method, method, to_direction}

    handlerObject = utilEvents.processHandlers[handler_name]

    if !method?
      throw new HardFail "Method must be defined."

    if !frequency?
      throw new HardFail "Frequency must be defined."

    if !handlerObject?
      throw new HardFail "Unable to find matching handleObject for handler_name: #{handler_name}"

    handle = handlerObject[handler_method]

    if !handle?
      throw new HardFail "Unable to find matching handle handler_method: #{handler_method}"


    l.debug -> "processEvent: handling, composit: #{util.inspect compacted, depth: null}"

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

    l.debug -> "processEvent: handle options: #{util.inspect options, depth: null}"

    dbs.get("main").transaction (transaction) ->
      handle(options)
      .then () ->
        #TODO: might want to explore using a transaction here
        # Mark as processed
        sqlHelpers.whereAndWhereIn tables.user.eventsQueue({transaction}), id: ids
        .update "#{frequency.toLowerCase()}_processed": true
      .then () ->
        tables.user.notificationFrequencies().select('code_name')
        .where('code_name', '!=', 'off')
        .then (rows) ->
          clause = {}
          rows.forEach (r) ->
            clause["#{r.code_name.toLowerCase()}_processed"] = true

          if doDequeue
            l.debug -> "@@@@@@@@@@@@@@@@@@@@@@"
            l.debug -> "dequeuing with frequency: #{frequency}"
            l.debug -> "@@@@@@@@@@@@@@@@@@@@@@"
            sqlHelpers.whereAndWhereIn tables.user.eventsQueue({transaction}), id: ids
            .where clause
            .delete()

      .catch errorHandlingUtils.isUnhandled, (error) ->
        throw new errorHandlingUtils.PartiallyHandledError error, """
        failed to processEvent:
         handler_name: #{handler_name},
         handler_method: #{handler_method},
         compacted: #{compacted}
        """
      .catch (error) ->
        throw new SoftFail(analyzeValue.getSimpleMessage(error))

doneEvents = (subtask) ->
  l = logger.spawn('doneEvents')
  l.debug -> "marking lastRefreshTimestamp"
  dataLoadHelpers.setLastRefreshTimestamp(subtask)
  l.debug -> "done"

module.exports = {
  loadEvents
  compactEvents
  processEvent
  doneEvents
}
