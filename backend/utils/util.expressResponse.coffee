csv = require 'csv'
escape = require('escape-html');

class ExpressResponse
  constructor: (@payload, @status=200, allowHtml=false, @format='json') ->
    @name = "ExpressResponse"
    if @payload?.alert? and !allowHtml
      @payload.alert.msg = escape(@payload.alert.msg)
  toString: () ->
    JSON.stringify(@)
  send: (res) ->
    console.log '### format:'
    console.log @format
    if @format == 'csv'
      res.set('Content-disposition', 'attachment; filename=testing.csv')
      res.set('Content-Type', 'text/csv')
      csv.generate().pipe(csv.stringify(@payload)).pipe(res)
      res.send
    else
      content = if @payload? then @payload else ""
      res.status(@status).send content

module.exports = ExpressResponse
