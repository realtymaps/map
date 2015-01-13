memoize = require 'memoizee'

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
