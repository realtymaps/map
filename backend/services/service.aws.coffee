externalAccounts = require './service.externalAccounts'
#http://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/S3.html
AWS = require('aws-sdk')
Promise = require 'bluebird'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
_ = require 'lodash'
{arrayify} = require '../utils/util.array'
logger = require('../config/logger').spawn('service.aws')
awsUploadFactory = require('s3-upload-stream')

buckets =
  PDF: 'aws-pdf-downloads'
  ListingPhotos: 'aws-listing-photos'


_debug = (thing, thingName) ->
  logger.debug "begin #{thingName} !!!!!!!!!"
  logger.debug thing
  logger.debug "end #{thingName} !!!!!!!!!!!"


_handler = (handlerOpts, opts) ->

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
  .then (s3Info) ->
    AWS.config.update
      accessKeyId: s3Info.api_key
      secretAccessKey: s3Info.other.secret_key
      region: 'us-east-1'

    s3 = Promise.promisifyAll new AWS.S3()

    if (s3FnName == 'upload')
      s3Stream = awsUploadFactory(s3)
      return s3Stream.upload.call s3Stream, extraArgs..., _.extend({}, {Bucket: s3Info.other.bucket}, opts)

    handle = s3[s3FnName + if nodeStyle then '' else 'Async']
    handle.call s3, extraArgs..., _.extend({}, {Bucket: s3Info.other.bucket}, opts)


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

listObjects = (opts) ->
  _handler
    s3FnName: 'listObjects'
    required: ['extAcctName']
  , opts

#for uploading  / putting streams of unkown exact size
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
  listObjects
  upload
}
