csv = require 'csv'
escape = require 'escape-html'
Promise = require 'bluebird'
logger = require '../config/logger'

class ExpressResponse
  constructor: (@payload, @status=200, allowHtml=false, @format='json') ->
    @name = "ExpressResponse"
    if @payload?.alert? and !allowHtml
      @payload.alert.msg = escape(@payload.alert.msg)
  toString: () ->
    JSON.stringify(@)
  send: (res) ->
    if @format == 'csv'
      # set headers for download
      res.set('Content-disposition', 'attachment; filename=mlsdata.csv')
      res.set('Content-Type', 'text/csv')

      # stringify payload and send
      stringifier = Promise.promisify(csv.stringify)
      stringifier(@payload, header: true)
      .then (data) ->
        res.send data
      .catch (err) ->
        logger.error "Error while sending csv attachment:"
        logger.error err
    else
      content = if @payload? then @payload else ""
      res.status(@status).send content

module.exports = ExpressResponse
