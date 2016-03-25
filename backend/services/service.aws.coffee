externalAccounts = require './service.externalAccounts'
#http://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/S3.html
AWS = require('aws-sdk')
Promise = require 'bluebird'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
_ = require 'lodash'
{arrayify} = require '../utils/util.array'
logger = require('../config/logger').spawn('service.aws')

buckets =
  PDF: 'aws-pdf-downloads'
  ListingPhotos: 'aws-listing-photos'

_s3Factory = (s3Info) ->
  AWS.config.update
    accessKeyId: s3Info.api_key
    secretAccessKey: s3Info.other.secret_key
    region: 'us-east-1'

  Promise.promisifyAll new AWS.S3()

_debug = (thing, thingName) ->
  logger.debug "begin #{thingName} !!!!!!!!!"
  logger.debug thing
  logger.debug "end #{thingName} !!!!!!!!!!!"

_handler = (handlerOpts, opts) ->

  _debug handlerOpts, 'handlerOpts'

  {required, s3FnName, binds, omit} = onMissingArgsFail
    args: handlerOpts
    required: s3FnName

  omit ?= arrayify omit

  defaultRequired = _.filter ['extAcctName','Key'], (n) -> !(omit.indexOf(n) > -1)

  if required?
    required = defaultRequired.concat arrayify(required)
  else
    required = defaultRequired

  _debug required, 'required'
  _debug s3FnName, 's3FnName'
  _debug binds, 'binds'

  {extAcctName} = opts
  opts = onMissingArgsFail
    args: opts
    required: required
    omit: 'extAcctName'

  externalAccounts.getAccountInfo(extAcctName)
  .then (s3Info) ->
    s3 = _s3Factory(s3Info)

    handle = s3[s3FnName]

    if binds?
      handle = handle.bind(s3, binds...)

    handle.call s3, _.extend {},
      Bucket: s3Info.other.bucket
    , opts

getTimedDownloadUrl = (opts) ->
  _handler
    binds: ['getObject']
    s3FnName: 'getSignedUrlAsync'
  ,
    _.extend {}, opts, Expires: (opts.minutes||10)*60

putObject = (opts) ->
  _handler {required: 'Body', s3FnName: 'putObjectAsync'}, opts

getObject = (opts) ->
  _handler {s3FnName: 'getObjectAsync'}, opts

listObjects = (opts) ->
  _handler {s3FnName: 'listObjectsAsync', omit: 'Key'}, opts

module.exports = {
  getTimedDownloadUrl
  buckets
  putObject
  getObject
  listObjects
}
