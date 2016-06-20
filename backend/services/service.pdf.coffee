wkhtmltopdf = require 'wkhtmltopdf'
Promise = require 'bluebird'
request = require 'request'
logger = require('../config/logger').spawn('service:pdf')
config = require('../config/config')
NamedError = require '../utils/errors/util.error.named'


htmlToPdf = (html) ->
  console.log "html:\n#{html}"

module.exports =
  htmlToPdf: htmlToPdf
