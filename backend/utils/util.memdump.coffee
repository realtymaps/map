Promise = require 'bluebird'
keystore = require '../services/service.keystore'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
globby = require 'globby'
config = require '../config/config'
cluster = require 'cluster'
heapdump = require 'heapdump'
logger = require('../config/logger').spawn('memdump')


makeDump = (callback) ->
  timestamp = (new Date).toISOString().slice(0, -5).replace('T', '__').replace(':', '-')
  instance = config.DYNO
  if cluster.worker?.id
    instance += '.'+cluster.worker.id
  key = "#{config.ENV}__#{instance}__#{timestamp}"
  name = "/tmp/#{key}.heapsnapshot"
  logger.info('Beginning memdump: '+key)
  heapdump.writeSnapshot name, (err, filename) ->
    if err
      logger.error('Failed to complete memdump: '+key+'\n'+err)
      return
    logger.info('Memdump finished: '+key)
    if callback
      callback(name)


getDump = (req, res, next) ->
  if !req.query.file
    globby('/tmp/*.heapsnapshot')
    .then (files) ->
      response = new ExpressResponse(files.sort().join('\n'))
      response.format = 'text'
      next(response)
  else if req.query.file == 'new'
    makeDump (filename) ->
      response = new ExpressResponse()
      response.download = filename
      next(response)
  else if req.query.file == 'last'
    globby('/tmp/*.heapsnapshot')
    .then (files) ->
      if files.length == 0
        response = new ExpressResponse('No memdump files found.')
        response.format = 'text'
        next(response)
      else
        response = new ExpressResponse()
        response.download = files[files.length-1]
        next(response)
  else
    response = new ExpressResponse()
    response.download = req.query.file
    next(response)


module.exports = {
  makeDump
  getDump
}
