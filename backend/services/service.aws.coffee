externalAccounts = require './service.externalAccounts'
AWS = require('aws-sdk')
Promise = require 'bluebird'


buckets =
  PDF: 'aws-pdf-downloads'


getTimedDownloadUrl = (bucket, key, opts={}) ->
  externalAccounts.getAccountInfo(bucket)
  .then (s3Info) ->
    AWS.config.update
      accessKeyId: s3Info.api_key
      secretAccessKey: s3Info.other.secret_key
      region: 'us-east-1'
    s3 = new AWS.S3()
    getSignedUrl = Promise.promisify(s3.getSignedUrl, s3)
    getSignedUrl 'getObject',
      Bucket: s3Info.other.bucket
      Key: key
      Expires: (opts.minutes||10)*60


module.exports =
  getTimedDownloadUrl: getTimedDownloadUrl
  buckets: buckets
