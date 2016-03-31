Promise = require 'bluebird'

defer = () ->
  resolve = undefined
  reject = undefined
  promise = new Promise (res, rej) ->
    resolve = res
    reject = rej
    return
  {
    resolve: resolve
    reject: reject
    promise: promise
  }

#force a to be called promise chain to wait on one another
#behave synchronously :( 
reduceSeries = (promisesToCall) ->
  [peek] = promisesToCall
  if peek.then?
    throw new Error 'Promises to call must not be promises!'

  promisesToCall.reduce (res, promise) ->
    if !res.then?
      res = res()
    res.then () -> promise()


mapSeries = (promisesToCall, mapFn) ->
  res = []
  index = 0

  callPromise = (p) ->
    res.push(
      p()
      .then (res) ->
        mapFn(res)
    )

  for p in promisesToCall
    do (p) ->
      if res.length
        return res[index]
        .then () ->
          callPromise(p)

      callPromise(p)


module.exports = {
  defer
  mapSeries
  reduceSeries
}
