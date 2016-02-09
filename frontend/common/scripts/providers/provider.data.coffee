mod = require '../module.coffee'

mod.service 'rmapsPromiseDataProvider', () ->
  @flattenData = ({data}) ->
    data

  @flattenDataPromise = (promise) =>
    promise.then @flattenData

  @$get = => @

  @
