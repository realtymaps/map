memoize = require 'memoizee'
config = require '../config/config'


expiringMemoizee = (fn) ->
  memoize fn,
    maxAge: config.CACHE.MAX_AGE,
    preFetch: config.CACHE.PRE_FETCH

module.exports =
  memoize: memoize
  memoizeExp : expiringMemoizee
