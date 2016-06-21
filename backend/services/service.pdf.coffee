wkhtmltopdf = require 'wkhtmltopdf'
fs = require 'fs'
Buffer = require('buffer').Buffer
Promise = require('bluebird')
request = require('request')
logger = require('../config/logger').spawn('service:pdf')
config = require('../config/config')
NamedError = require('../utils/errors/util.error.named')
tables = require('../config/tables')
awsService = require('./service.aws')

htmlToPdf = (campaign) ->
  console.log "@@@@@@@ htmlToPdf()"
  console.log "campaign:\n#{JSON.stringify(campaign,null,2)}"

  return new Promise (resolve, reject) ->
    html = campaign.lob_content

    # draft key and options
    key = config.MAILING_PLATFORM.S3_UPLOAD.getKey()
    opts =
      extAcctName: 'aws-pdf-uploads'
      Key: key
      ContentType: 'application/pdf'

    # setup pdf -> s3upload stream
    awsService.upload(opts)
    .then (upload) ->
      upload.once 'uploaded', (details) ->
        # save the key
        tables.mail.campaign()
        .update aws_key: key
        .where id: campaign.id
        .then () ->
          resolve(key)

      upload.once 'error', (uploadErr) ->
        logger.error "error while uploading pdf for mail campaign #{campaign.id}: #{uploadErr}"
        reject(uploadErr)

      # pipe pdf data through the s3 upload
      wkhtmltopdf(html, { pageSize: 'letter' })
      .on 'error', (pdfErr) ->
        logger.error "error while creating pdf from mail campaign #{campaign.id}: #{pdfErr}"
        reject(pdfErr)
      .pipe(upload)


module.exports =
  htmlToPdf: htmlToPdf
