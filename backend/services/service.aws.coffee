externalAccounts = require './service.externalAccounts'
AWS = require('aws-sdk')
Promise = require 'bluebird'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'

buckets =
  PDF: 'aws-pdf-downloads'
  ListingPhotos: 'aws-listing-photos'

_s3Factory = (s3Info) ->
  AWS.config.update
    accessKeyId: s3Info.api_key
    secretAccessKey: s3Info.other.secret_key
    region: 'us-east-1'

  Promise.promisifyAll new AWS.S3()

getTimedDownloadUrl = (opts) ->
  {bucket, key} = onMissingArgsFail
    args: opts
    required: ['bucket','key']

  externalAccounts.getAccountInfo(bucket)
  .then (s3Info) ->
    _s3Factory(s3Info)
    .getSignedUrlAsync 'getObject',
      Bucket: s3Info.other.bucket
      Key: key
      Expires: (opts.minutes||10)*60


putObject = (opts) ->
  {bucket, key, body} = onMissingArgsFail
    args: opts
    required: ['bucket','key','body']

  externalAccounts.getAccountInfo(bucket)
  .then (s3Info) ->
    console.log s3Info
    _s3Factory(s3Info)
    .putObjectAsync
      Bucket: s3Info.other.bucket
      Key: key
      Body: body

module.exports = {
  getTimedDownloadUrl
  buckets
  putObject
}
