SourceMap = require 'source-map'
StackTraceGPS = require 'stacktrace-gps'
fs = require 'fs'
Promise = require 'bluebird'
request = require 'request'
memoize = require 'memoizee'
aws = require('../../backend/services/service.aws')

path = "#{__dirname}/../../_public"
cacheFileName = 'scripts/map.bundle.js'
S3_BUCKET = process.env.S3_BUCKET ? 'rmaps-dropbox'
SCRIPTS_CACHE_SECRET_KEY = process.env.SCRIPTS_CACHE_SECRET_KEY

atob = (str) ->
  new Buffer(str, 'base64').toString('binary')

ajax = (url) ->
  requestPromise = Promise.promisify(request.get, {multiArgs: true})
  requestPromise(url).then ([r, text]) ->
    text

pinpoint = (stack, gpsConfig = {ajax, atob}) ->
  gps = new StackTraceGPS(gpsConfig)
  Promise.map stack, (frame) ->
    gps.pinpoint(frame)

fromS3Config = (errorLog) ->
  cacheKey = "#{SCRIPTS_CACHE_SECRET_KEY}/#{errorLog.git_revision}/map.bundle.js"
  sourceMapKey = "#{SCRIPTS_CACHE_SECRET_KEY}/#{errorLog.git_revision}/map.bundle.js.map"
  console.log arguments
  Promise.props(
    cacheFile: aws.getObject(extAcctName: S3_BUCKET, Key: cacheKey)
    sourceMap: aws.getObject(extAcctName: S3_BUCKET, Key: sourceMapKey)
  )
  .then ({cacheFile, sourceMap}) ->
    cacheFile = cacheFile.Body.toString('utf-8')
    sourceMap = sourceMap.Body.toString('utf-8')
    sourceCache = "#{errorLog.file}": cacheFile
    sourceMapConsumer = new SourceMap.SourceMapConsumer(sourceMap)
    sourceMapConsumerCache = sourceMapUrl: sourceMapConsumer, "#{errorLog.file}.map": sourceMapConsumer
    {offline: true, sourceCache, sourceMapConsumerCache, atob}

fromNetworkConfig = (errorLog) ->
  cacheUrl = "https://s3.amazonaws.com/rmaps-dropbox/#{SCRIPTS_CACHE_SECRET_KEY}/#{errorLog.git_revision}/map.bundle.js"
  sourceMapUrl = "https://s3.amazonaws.com/rmaps-dropbox/#{SCRIPTS_CACHE_SECRET_KEY}/#{errorLog.git_revision}/map.bundle.js.map"
  Promise.props(
    cacheFile: ajax(cacheUrl)
    sourceMap: ajax(sourceMapUrl)
  )
  .then ({cacheFile, sourceMap}) ->
    sourceCache = "#{cacheUrl}": cacheFile, "#{errorLog.file}": cacheFile
    sourceMapConsumer = new SourceMap.SourceMapConsumer(sourceMap)
    sourceMapConsumerCache = sourceMapUrl: sourceMapConsumer, "#{errorLog.file}.map": sourceMapConsumer
    {offline: true, sourceCache, sourceMapConsumerCache, atob}

fromLocalConfig = (originalCacheUrl) ->
  readFile = Promise.promisify(fs.readFileAsync)
  Promise.props(
    cacheFile: readFile("#{path}/#{cacheFileName}", "utf-8")
    sourceMap: readFile("#{path}/#{cacheFileName}.map", "utf-8")
  )
  .then ({cacheFile, sourceMap}) ->
    sourceCache = "#{originalCacheUrl}": cacheFile
    sourceMapConsumerCache = "#{originalCacheUrl}.map": new SourceMap.SourceMapConsumer(sourceMap)
    {offline: true, sourceCache, sourceMapConsumerCache, atob}

module.exports = {
  fromS3Config: memoize(fromS3Config, maxAge: 5*60*1000)
  fromNetworkConfig: memoize(fromNetworkConfig, maxAge: 5*60*1000)
  fromLocalConfig: memoize(fromLocalConfig, maxAge: 5*60*1000)
  pinpoint
}
