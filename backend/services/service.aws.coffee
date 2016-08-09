externalAccounts = require './service.externalAccounts'
#http://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/S3.html
AWS = require('aws-sdk')
Promise = require 'bluebird'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
_ = require 'lodash'
logger = require('../config/logger').spawn('aws')
loggerFine = logger.spawn('fine')
awsUploadFactory = require('s3-upload-stream')
Spinner = require('cli-spinner').Spinner
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'

buckets =
  PDF: 'aws-pdf-downloads'
  PDFUploads: 'aws-pdf-uploads'
  ListingPhotos: 'aws-listing-photos'
  BlackknightData: 'aws-blackknight-data'


_debug = (thing, thingName) ->
  loggerFine.debug "begin #{thingName} !!!!!!!!!"
  loggerFine.debug thing
  loggerFine.debug "end #{thingName} !!!!!!!!!!!"


_handler = (handlerOpts, opts) -> Promise.try () ->

  _debug handlerOpts, 'handlerOpts'

  {required, s3FnName, extraArgs} = onMissingArgsFail
    args: handlerOpts
    required: 's3FnName'

  extraArgs ?= {}

  _debug required, 'required'
  _debug s3FnName, 's3FnName'
  _debug extraArgs, 'extraArgs'

  {extAcctName, nodeStyle} = opts
  opts = onMissingArgsFail
    args: opts
    required: required
    omit: ['extAcctName', 'nodeStyle']

  _debug opts, 'opts'

  externalAccounts.getAccountInfo(extAcctName)
  .catch (error) ->
    logger.debug "Did you forget to import account into externalAccounts?"
    throw new errorHandlingUtils.PartiallyHandledError(error, "AWS external account lookup failed")
  .then (s3Info) ->
    AWS.config.update
      accessKeyId: s3Info.api_key
      secretAccessKey: s3Info.other.secret_key
      region: 'us-east-1'

    s3 = Promise.promisifyAll new AWS.S3()

    if (s3FnName == 'upload')
      return awsUploadFactory(s3).upload(extraArgs..., _.extend({}, {Bucket: s3Info.other.bucket}, opts))

    s3FullFnName = s3FnName + if nodeStyle then '' else 'Async'
    s3[s3FullFnName](extraArgs..., _.extend({}, {Bucket: s3Info.other.bucket}, opts))
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, "AWS error encountered")


getTimedDownloadUrl = (opts) ->
  _handler
    extraArgs: ['getObject']
    s3FnName: 'getSignedUrl'
    required: ['extAcctName','Key']
  , _.extend({}, opts, Expires: (opts.minutes||10)*60)

###
  If you don't know the size of the stream of the buffer ahead of time. Then it is recommended to use UPLOAD BELOW!

  This is a limitation of s3 itself even if u think you know the size and it is incorrect you can run into problems.
  https://github.com/aws/aws-sdk-js/issues/94 , stream.length must be set for AWS (SUCKY) for putObject
###
putObject = (opts) ->
  _handler
    s3FnName: 'putObject'
    required: ['extAcctName','Key','Body']
  , opts

getObject = (opts) ->
  _handler
    s3FnName: 'getObject'
    required: ['extAcctName','Key']
  , opts

deleteObject = (opts) ->
  _handler
    s3FnName: 'deleteObject'
    required: ['extAcctName','Key']
  , opts

deleteObjects = (opts) ->
  _handler
    s3FnName: 'deleteObjects'
    required: ['extAcctName','Delete']
  , opts


listObjects = (opts) ->
  _handler
    s3FnName: 'listObjects'
    required: ['extAcctName']
  , opts


#handle things as we go through pages
#don't stack up memory
_handleAllObjects = (opts, pageCb = (->)) ->
  {progress} = opts
  opts = _.omit opts, 'progress'

  if progress
    spinner = new Spinner('paging.. %s')
    spinner.setSpinnerString('|/-\\')
    spinner.start()

  new Promise (resolve, reject) ->
    ctr = 0
    pages = 0
    listObjects(_.extend {}, opts, nodeStyle:true)
    .then (listObjects) ->
      #https://github.com/aws/aws-sdk-js/blob/0d19fe976f48860d9e929b027de0b601f55523cb/lib/request.js#L460-L477
      listObjects.eachPage (err, list, continueCb) ->
        handleError = (err) ->
          spinner?.stop()
          continueCb(false)
          reject(err)

        if err
          return handleError(err)

        ctr += list.Contents.length
        Promise.try ->
          pageCb(list, pages)
        .then () =>
          if @hasNextPage()
            pages += 1
            continueCb()
          else
            logger.debug "finished with page #{pages + 1}"
            continueCb(false)
            spinner?.stop()
            resolve(ctr)
        .catch (err) ->
          handleError(err)

deleteAllObjects = (opts) ->
  summary =
    attempted: 0
    deleted: 0
    errors: []
  handlePage = (list, pagesIdx) -> Promise.try () ->
    if !list.Contents.length
      logger.debug "page #{pagesIdx+1} is empty"
      return
    logger.debug "deleting page: #{pagesIdx}"
    summary.attempted += list.Contents.length
    deleteObjects _.extend {}, opts,
      Delete: Objects: list.Contents.map (o) -> Key: o.Key
    .then (result) ->
      summary.deleted += (result.Deleted?.length||0)
      summary.errors.concat(result.Errors)

  _handleAllObjects(opts, handlePage)
  .then () ->
    summary

countObjects = (opts) ->
  _handleAllObjects opts

#for uploading  / putting streams of unknown exact size
#node style only!!
upload = (opts) ->
  _handler
    s3FnName: 'upload'
    required: ['extAcctName']
  , opts

module.exports = {
  getTimedDownloadUrl
  buckets
  putObject
  getObject
  deleteObject
  deleteObjects
  listObjects
  upload
  countObjects
  deleteAllObjects
}
