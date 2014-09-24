memoize = require 'memoizee'
config = require '../config/config'

expiringMemoizee = (
  fn,
  options = {
    maxAge: config.DB_CACHE_TIMES.SLOW_REFRESH,
    preFetch: config.DB_CACHE_TIMES.PRE_FETCH
  }
) ->
  memoize fn, options

expiringFastMemoizee = (
  fn,
  options = {
    maxAge: config.DB_CACHE_TIMES.FAST_REFRESH
    preFetch: config.DB_CACHE_TIMES.PRE_FETCH
  }
) ->
  memoize fn, options


module.exports =
  memoize: memoize
  memoizeExp : expiringMemoizee
  memoizeSlowExp : expiringMemoizee
  memoizeFastExp : expiringFastMemoizee
