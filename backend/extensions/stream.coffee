Stream = require 'stream'
JSONStream = require 'JSONStream'
Promise = require 'bluebird'
logger = require('../config/logger').spawn('extensions:stream')

Stream::stringify = () ->
  @pipe(JSONStream.stringify())

if !Stream::toPromise?
  Stream::toPromise = () ->
    new Promise (resolve, reject) =>
      @once 'finish', resolve
      @once 'end', resolve
      @once 'close', resolve
      @once 'error', reject
else
  logger.warn "Stream::toPromise already exist! We should change the prototype naming."


if !Stream::toCounterPromise?
  Stream::toCounterPromise = () ->
    counters = null

    @once 'counters', (_counters) ->
      counters = _counters
    .toPromise()
    .then () ->
      counters
else
  logger.warn "Stream::toCounterPromise already exist! We should change the prototype naming."

module.exports = Stream
