escape = require 'escape-html'
Promise = require 'bluebird'
logger = require '../config/logger'
csvStringify = Promise.promisify(require('csv-stringify'))
{PartiallyHandledError} = require './errors/util.error.partiallyHandledError'



class ExpressResponse
  constructor: (@payload, {@status=200, allowHtml=false, @format='json', @quiet=false}={}) ->
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
    if @download
      return res.download(@download, @filename)
    if @filename
      res.set('Content-disposition', "attachment; filename=#{@filename}")
    if @format == 'csv'
      # set headers for download
      res.set('Content-Type', 'text/csv')

      # stringify payload and send
      csvStringify(@payload.data, @payload.options)
      .then (data) ->
        res.send(data)
      .catch (err) ->
        new PartiallyHandledError(err, 'Error while sending csv attachment')
    else if @format == 'text'
      res.set('Content-Type', 'text/plain')
      res.status(@status).send(@payload||'')
    else
      content = if @payload? then JSON.stringify(@payload) else ''
      res.status(@status).send content


module.exports = ExpressResponse
