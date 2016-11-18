Stream = require 'stream'
JSONStream = require 'JSONStream'
Promise = require 'bluebird'

Stream::stringify = () ->
  @pipe(JSONStream.stringify())

if !Stream::toPromise?
  Stream::toPromise = () ->
    new Promise (resolve, reject) =>
      @once 'finish', resolve
      @once 'close', resolve
      @once 'error', reject

module.exports = Stream
