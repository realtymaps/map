Stream = require 'stream'
JSONStream = require 'JSONStream'
logger = require('../config/logger').spawn('extensions:stream')
require './emitter'

Stream::stringify = () ->
  @pipe(JSONStream.stringify())

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
