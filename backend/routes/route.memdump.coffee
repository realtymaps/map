auth = require '../utils/util.auth'
logger = require('../config/logger').spawn('memdump')
heapdump = require 'heapdump'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
config = require '../config/config'

module.exports =
  download:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      logger.info('Beginning memdump...')
      timestamp = (new Date).toISOString().slice(0, -5).replace('T', '_')
      heapdump.writeSnapshot "/tmp/#{config.ENV}_#{timestamp}.heapsnapshot", (err, filename) ->
        if err
          return next(new ExpressResponse('Failed to complete memdump.', httpStatus.INTERNAL_SERVER_ERROR))
        logger.info('Memdump finished.')
        response = new ExpressResponse()
        response.download = filename
        next(response)
