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


module.exports =
  defer: defer
