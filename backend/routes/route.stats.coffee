auth = require '../utils/util.auth'
tables = require '../config/tables'
logger = require '../config/logger'


module.exports =
  signUps:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions('access_staff')
    ]
    handleQuery: true
    handle: (req) ->
      l = logger.spawn('signUps')
      l.debug -> 'hit'

      rawSelect = tables.auth.user.raw """
        to_char(date_trunc('day', rm_inserted_time), 'YYYY-MM-DD') AS date,
        COUNT(id) AS count
        """

      groupRaw = tables.auth.user.raw("date_trunc('day', rm_inserted_time)")

      l.debugQuery (
        tables.auth.user()
        .select(rawSelect)
        .groupBy(groupRaw)
        .orderBy(groupRaw)
      )

  mailings:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions('access_staff')
    ]
    handleQuery: true
    handle: (req) ->
      l = logger.spawn('signUps')
      l.debug -> 'hit'

      rawSelect = tables.mail.campaign.raw """
        to_char(date_trunc('day', rm_inserted_time), 'YYYY-MM-DD') AS date,
        COUNT(id) AS count,
        SUM(json_array_length(recipients)) AS recipientsCount
        """

      groupRaw = tables.mail.campaign.raw("date_trunc('day', rm_inserted_time)")

      l.debugQuery (
        tables.mail.campaign()
        .select(rawSelect)
        .groupBy(groupRaw)
        .orderBy(groupRaw)
      )
