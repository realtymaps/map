escape = require 'escape-html'
Promise = require 'bluebird'
logger = require '../config/logger'

class ExpressResponse
  constructor: (@payload, @status=200, allowHtml=false, @format='json') ->
    @name = 'ExpressResponse'
    @originalMsg = @payload?.alert?.msg
    if @originalMsg and !allowHtml
      @payload.alert.msg = escape(@payload.alert.msg)
  toString: () ->
    result = "ExpressResponse:\n"
    result += "    Status: #{@status}\n"
    result += "    Format: #{@format}\n"
    details = (@originalMsg || JSON.stringify(@payload,null,2)).split('\n')
    if details.length > 1
      result += "    Details:\n"
      result += "        " + details.join('\n        ')
    else
      result += "    Details: #{details}"
    result
  send: (res) ->
    if @format == 'csv'
      # set headers for download
      res.set('Content-disposition', 'attachment; filename=mlsdata.csv')
      res.set('Content-Type', 'text/csv')
      res.send @payload
    else
      content = if @payload? then JSON.stringify(@payload) else ''
      res.status(@status).send content


module.exports = ExpressResponse
