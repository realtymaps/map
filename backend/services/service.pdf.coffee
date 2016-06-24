htmltopdf = require 'html-pdf'
fs = require 'fs'
Buffer = require('buffer').Buffer
Promise = require('bluebird')
request = require('request')
logger = require('../config/logger').spawn('service:pdf')
config = require('../config/config')
NamedError = require('../utils/errors/util.error.named')
tables = require('../config/tables')
awsService = require('./service.aws')

createFromCampaign = (campaign) ->
  return new Promise (resolve, reject) ->
    html = campaign.lob_content

    # draft key and options
    key = config.MAILING_PLATFORM.S3_UPLOAD.getKey()
    opts =
      extAcctName: awsService.buckets.PDFUploads
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

      pdfOptions =
        format: 'Letter'
        orientation: 'portrait'

      # pipe pdf data through the s3 upload
      htmltopdf.create(html, pdfOptions)
      .toStream (htmltopdfErr, stream) ->
        if htmltopdfErr
          logger.error "There is an issue with making a pdf from the html content of campaign #{campaign.id}: #{htmltopdfErr}"
          reject(htmltopdfErr)

        stream.on 'error', (pdfErr) ->
          logger.error "Error while creating pdf from mail campaign #{campaign.id}: #{pdfErr}"
          reject(pdfErr)
        .pipe(upload)

module.exports = {
  createFromCampaign
}
