Promise = require 'bluebird'

defer = () ->
  resolve = undefined
  reject = undefined
  promise = new Promise (res, rej) ->
    resolve = res
    reject = rej
  {
    resolve
    reject
    promise
  }


module.exports = {
  defer
}
