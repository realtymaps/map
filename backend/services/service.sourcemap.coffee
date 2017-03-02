SourceMap = require 'source-map'
StackTraceGPS = require 'stacktrace-gps'
fs = require 'fs'
Promise = require 'bluebird'
request = require 'request'
memoize = require 'memoizee'

path = "#{__dirname}/../../_public/scripts"
cacheFileName = 'map.bundle.js'
S3_BUCKET = process.env.S3_BUCKET ? 'rmaps-dropbox'
SCRIPTS_CACHE_SECRET_KEY = process.env.SCRIPTS_CACHE_SECRET_KEY

logger = require('../config/logger').spawn("service:sourcemap")

atob = (str) ->
  new Buffer(str, 'base64').toString('binary')

ajax = (url) ->
  requestPromise = Promise.promisify(request.get, {multiArgs: true})
  requestPromise(url).then ([r, text]) ->
    text

pinpoint = (stack, gpsConfig = {ajax, atob}) ->
  gps = new StackTraceGPS(gpsConfig)
  Promise.map stack, (frame) ->
    if frame.fileName?.indexOf(cacheFileName) != -1
      frame.fileName = cacheFileName
      gps.pinpoint(frame)
    else
      frame

getGitRev = () ->
  exec = Promise.promisify(require('child_process').exec)

  Promise.try ->
    if process.env.IS_HEROKU == '1'
      return [process.env.HEROKU_SLUG_COMMIT]
    else
      return exec('git rev-parse HEAD')
  .then ([rev]) ->
    gitRev = rev.trim()
    if process.env.NODE_ENV != 'production'
      gitRev += '-dev'

    logger.debug -> "git revision: #{gitRev}"
    gitRev

getCachedFile = (gitRev) ->
  "#{SCRIPTS_CACHE_SECRET_KEY}/#{gitRev}/#{cacheFileName}"

getNetworkCachedFile = (gitRev) ->
  "https://s3.amazonaws.com/#{S3_BUCKET}/" + getCachedFile(gitRev)

fromS3Config = (errorLog) ->
  #NOTE: IMPORTANT!! lazy load aws as it messes with gulp somehow, also this speeds things up a lot
  aws = require('../../backend/services/service.aws')

  cacheKey = getCachedFile(errorLog.git_revision)
  sourceMapKey = getCachedFile(errorLog.git_revision) + '.map'
  Promise.props(
    cacheFile: aws.getObject(extAcctName: S3_BUCKET, Key: cacheKey)
    sourceMap: aws.getObject(extAcctName: S3_BUCKET, Key: sourceMapKey)
  )
  .then ({cacheFile, sourceMap}) ->
    cacheFile = cacheFile.Body.toString('utf-8')
    sourceMap = sourceMap.Body.toString('utf-8')
    sourceCache =
      "#{errorLog.file}": cacheFile
      "#{cacheFileName}": cacheFile
      "/_public/scripts/#{cacheFileName}": cacheFile
    sourceMapConsumer = new SourceMap.SourceMapConsumer(sourceMap)
    sourceMapConsumerCache =
      "#{errorLog.file}.map": sourceMapConsumer
      "#{cacheFileName}.map": sourceMapConsumer
      "/_public/scripts/#{cacheFileName}.map": sourceMapConsumer
    {offline: true, sourceCache, sourceMapConsumerCache, atob}

fromNetworkConfig = (errorLog) ->
  cacheUrl = getNetworkCachedFile(errorLog.git_revision)
  sourceMapUrl = getNetworkCachedFile(errorLog.git_revision) + '.map'
  Promise.props(
    cacheFile: ajax(cacheUrl)
    sourceMap: ajax(sourceMapUrl)
  )
  .then ({cacheFile, sourceMap}) ->
    sourceCache =
      "#{cacheUrl}": cacheFile
      "#{errorLog.file}": cacheFile
      "#{cacheFileName}": cacheFile
    sourceMapConsumer = new SourceMap.SourceMapConsumer(sourceMap)
    sourceMapConsumerCache =
      sourceMapUrl: sourceMapConsumer
      "#{errorLog.file}.map": sourceMapConsumer
      "#{cacheFileName}.map": sourceMapConsumer
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
  fromS3Config: memoize(fromS3Config, maxAge: 5*60*1000, normalizer: (errorLog) -> errorLog.git_revision)
  fromNetworkConfig: memoize(fromNetworkConfig, maxAge: 5*60*1000, normalizer: (errorLog) -> errorLog.git_revision)
  fromLocalConfig: memoize(fromLocalConfig, maxAge: 5*60*1000)
  pinpoint
  getGitRev
  getCachedFile
  getNetworkCachedFile
}
