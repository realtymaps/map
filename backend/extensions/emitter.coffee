Promise = require 'bluebird'
logger = require('../config/logger').spawn('extensions:emitter')

EventEmitter = require 'events'

toPromise = (emitterLike) -> new Promise (resolve, reject) ->
  emitterLike.once 'finish', resolve
  emitterLike.once 'end', resolve
  emitterLike.once 'close', resolve
  emitterLike.once 'error', reject

if !EventEmitter::toPromise?
  EventEmitter::toPromise = () ->
    toPromise(@)
else
  logger.warn "EventEmitter::toPromise already exist! We should change the prototype naming."


module.exports = {
  toPromise
}
