_ = require 'lodash'
memoize = require 'memoizee'
util = require 'util'
require '../config/promisify.coffee'
logger = require('../config/logger.coffee').spawn('task:notifications')
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
jobQueue = require '../services/service.jobQueue'
tables = require '../config/tables'
dbs = require '../config/dbs'
sqlHelpers = require '../utils/util.sql.helpers'


notifcationsSvc = require '../services/service.notifications'
analyzeValue = require '../../common/utils/util.analyzeValue'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'

handlers =
  notifcations: notifcationsSvc

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

  dateSlot = switch frequency
    when 'daily'
      minuteSlot = 3600 * 24
      'day'
    else 'hour'

  minuteSlot ?= subtask.data.minuteSlot || MINUTE_SLOT

  dbs.get('main').raw """
    select
      date_trunc(?, rm_inserted_time) AS hour_stump,
      (extract(minute FROM rm_inserted_time)::int / ?) AS min_slot,
      auth_user_id,
      array_agg(id) ids
    from user_events_queue
    group by 1,2,3,4
    order by 1,2,3,4;
    """
  , [dateSlot, minuteSlot]
  .then (rows) ->

    #note this is an array of arrays
    # ids  = _.pluck rows, 'ids'

    jobQueue.queueSubsequentPaginatedSubtask {
      subtask
      totalOrList: rows
      maxPage
      laterSubtaskName: "compactEvents"
      mergeData: {doDequeue, frequency}
    }

compactEvents = (subtask) -> Promise.try () ->
  if !subtask.data?.values?.length
    return

  Promise.map subtask.data.values, (row) ->
    sqlHelpers.whereAndWhereIn tables.user.eventsQueue(),
      id: row.ids
    .then (compactRows) ->
      compacted = _.merge {}, compactRows...

      jobQueue.queueSubsequentSubtask {
        subtask
        manualData: {
          compacted
          ids: row.ids
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
processEvent = (subtask) ->
  {data} = subtask
  {compacted, doDequeue, frequency, ids} = data
  doDequeue ?= false

  eventMapPromise ?= memoize.promise(tables.handlers.eventMap(), maxAge: 15*60*1000) #15 min
  .then (eventMapRows) ->
    _.indexBy eventMapRows, 'event_type'

  eventMapPromise
  .then (eventMap) ->

    # handle event type and do whatever with it accordingly
    {handler_name, handler_method, method, to_direction} = eventMap[data.type]

    handlerObject = handlers[handler_name]?

    if !handlerObject?
      throw HardFail "Unable to find matching handleObject for handler_name: #{handler_name}"

    handle = handlerObject[handler_method]

    if !handle?
      throw HardFail "Unable to find matching handle handler_method: #{handler_method}"


    logger.debug () -> "processEvent: handling, composit: #{util.inspect compacted, depth: null}"

    options = {
      id: compacted.auth_user_id
      to: to_direction
      method
      type: compacted.type
      payload: compacted.options
    }

    logger.debug "processEvent: handle options: #{util.inspect options, depth: null}"

    handle options
    .then () ->
      #TODO: might want to explore using a transaction here
      # Mark as processed
      sqlHelpers.whereAndWhereIn tables.user.eventsQueue(), id: ids
      .update "#{frequency}_processed": true
    .then () ->
      if doDequeue
        sqlHelpers.whereAndWhereIn tables.user.eventsQueue(), id: ids
        .where {onDemand_processed: true, daily_processed: true}
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


module.exports = {
  loadEvents
  compactEvents
  processEvent
  handlers
}
