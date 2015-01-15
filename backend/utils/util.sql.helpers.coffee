memoize = require 'memoizee'

_interval = (val, operator, beginTimeStamp, endTmeStamp, interval) ->
  sql: "make_negative_interval_null((#{endTmeStamp}::timestamp - #{beginTimeStamp}::timestamp)) #{operator} ? * INTERVAL '1 #{interval}'"
  bindings: [ val ]

_days = (val, operator, beginTimeStamp, endTmeStamp) ->
  _interval val, operator, beginTimeStamp, endTmeStamp, 'day'

_whereRawSafe = (query, rawSafe) ->
  query.whereRaw rawSafe.sql, rawSafe.bindings
  
_orWhereRawSafe = (query, rawSafe) ->
  query.orWhere ()-> _whereRawSafe(@, rawSafe)


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

  daysGreaterThan: (query, val, beginTimeStamp = 'close_date', endTmeStamp = 'listing_start_date') ->
    _whereRawSafe query, _days(val, '>=', beginTimeStamp, endTmeStamp)

  daysLessThan: (query, val, beginTimeStamp = 'close_date', endTmeStamp = 'listing_start_date') ->
    _whereRawSafe query, _days(val, '<=', beginTimeStamp, endTmeStamp)

  _whereRawSafe: _whereRawSafe
  _orWhereRawSafe: _orWhereRawSafe
  
  whereIn: (query, column, values) ->
    # this logic is necessary to avoid SQL parse errors
    if values.length == 1
      query.where(column, values[0])
    else
      query.whereIn(column, values)

  allPatternsInAnyColumn: (query, patterns, columns) ->
    patterns.forEach (pattern) ->
      query.where () ->
        subquery = @
        columns.forEach (column) ->
          _orWhereRawSafe subquery,
            sql: "#{column} ~* ?"
            bindings: [ pattern ]
