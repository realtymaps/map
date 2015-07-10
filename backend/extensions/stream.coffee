Stream = require 'stream'
JSONStream = require 'JSONStream'

Stream::stringify = () ->
  @pipe(JSONStream.stringify())

module.exports = Stream
