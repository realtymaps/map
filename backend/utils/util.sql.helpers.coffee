memoize = require 'memoizee'

_interval = (val, operator, beginTimeStamp, endTmeStamp, interval) ->
  "make_negative_interval_null((#{endTmeStamp}::timestamp - #{beginTimeStamp}::timestamp)) #{operator} #{val} * INTERVAL '1 #{interval}'"

_days = (val, operator, beginTimeStamp, endTmeStamp) ->
  _interval val, operator, beginTimeStamp, endTmeStamp, 'day'

module.exports =

  between: (query, column, min, max) ->
    if min and max
      query.whereBetween(column, [min, max])
    else if min
      query.where(column, '>=', min)
    else if max
      query.where(column, '<=', max)
  tableName: memoize (model) ->
    model.query()._single.table

  daysGreaterThan: (val, beginTimeStamp = 'close_date', endTmeStamp = 'listing_start_date') ->
    _days(val, '>=', beginTimeStamp, endTmeStamp)

  daysLessThan: (val, beginTimeStamp = 'close_date', endTmeStamp = 'listing_start_date') ->
    _days(val, '>=', beginTimeStamp, endTmeStamp)
