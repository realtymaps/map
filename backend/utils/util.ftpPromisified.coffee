Promise = require "bluebird"
logger = require '../config/logger'
ftp = require 'ftp'

#consider open sourcing as an npm lib

_createFtp = (url, account, password) ->
  c = Promise.promisifyAll(new ftp())
  opts =
    host:url
    user:account
    password: password

  logger.debug("new client connecting: #{JSON.stringify(opts)}")

  c.connect(opts)
  c.onAsync 'ready'
  .catch (err) ->
    logger.error(err)
    throw err
  .then ->
    logger.debug("new client connected")
    c

module.exports = _createFtp
