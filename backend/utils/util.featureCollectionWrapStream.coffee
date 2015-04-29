through = require('through')
through2 = require 'through2'
logger = require '../config/logger'
{parcelFeatureCollection} = require './util.featureCollectionWrap'

_basicWrapStream = ->
  prefixWritten = false
  write = (data) -> # 1st param to through() gets called whenever there is data to write
    if !prefixWritten # write the prefix before the first write
      @queue new Buffer('{"type": "FeatureCollection", "features": ')
      prefixWritten = true
    @queue(data)
  end = () -> # 2nd param to through() is optional and is called when there is no more data left
    @queue new Buffer('}') # finish the wrapper once everything is done
    @queue null # queuing null signals to the next stream that this one is done

  through(write, end)

#note this is just to prove and show how the formatting can work in through2
#since this end up putting eveything into memory anyways it is better to just work with the object
#originally and then convert the object to a stream to save
_complexWrapStream = ->
    buffStr = ''

    write = (buf, ignored, next) ->
      line = buf.toString()
      buffStr += line
      next()

    end = (next) ->
      if buffStr
        rows = JSON.parse(buffStr)
        featureCollection = parcelFeatureCollection(rows)
        @push(JSON.stringify(featureCollection) + '\n')
      next()

    through2(write, end)

module.exports =
  basicWrapStream: _basicWrapStream
  complexWrapStream: _complexWrapStream
