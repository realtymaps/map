escape = require('escape-html');

class ExpressResponse
  constructor: (@payload, @status=200, allowHtml=false) ->
    @name = "ExpressResponse"
    if @payload.alert and !allowHtml
      @payload.alert.msg = escape(payload.alert.msg)
  toString: () ->
    JSON.stringify(@)

module.exports = ExpressResponse
