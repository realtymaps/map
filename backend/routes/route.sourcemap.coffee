Promise = require 'bluebird'
auth = require '../utils/util.auth'
logger = require("../config/logger").spawn("route:sourcemap")
config = require("../config/config")
{validateAndTransformRequest} = require '../utils/util.validation'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
transforms = require '../utils/transforms/transforms.sourcemap'
aws = require '../services/service.aws'
sourcemapSvc = require '../services/service.sourcemap'
require '../extensions/emitter'


module.exports =
  # proxy to s3 sourcemaps for production and staging
  get:
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['read_sourcemap']}, logoutOnFail:false)
    ]
    handle: (req, res, next) ->
      validateAndTransformRequest(req, transforms.get)
      .then (validReq) ->
        logger.debug -> validReq
        sourcemapSvc.getGitRev()
        .then (gitRev) ->
          sourcemapSvc.getCachedPrefix(gitRev) + "/" + validReq.params.fileName
        .then (Key) ->
          # res.setHeader 'Content-type', contentType
          res.setHeader 'Cache-Control', "public, max-age=#{config.FRONTEND_ASSETS.MAX_AGE_SEC}"

          logger.debug -> 'aws getObjext'
          options = {extAcctName: 'rmaps-dropbox', Key, nodeStyle: true}
          logger.debug -> options

          aws.getObject(options).then (result) ->
            new Promise (resolve, reject) ->
              result.createReadStream()
              .once('error', reject)# handle errors prior to pipe
              .pipe(res).toPromise().then () ->
                resolve()
      .catch errorHandlingUtils.isUnhandled, (error) ->
        throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to get soucemap')
