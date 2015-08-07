app = require '../app.coffee'

module.exports = app.filter 'emptyValueOutput', () ->
  (input) ->
    if input is null or input is ""
      return "Empty"
    return input