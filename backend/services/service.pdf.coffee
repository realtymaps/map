wkhtmltopdf = require 'wkhtmltopdf'
fs = require 'fs'
Buffer = require('buffer').Buffer
Promise = require 'bluebird'
request = require 'request'
logger = require('../config/logger').spawn('service:pdf')
config = require('../config/config')
NamedError = require '../utils/errors/util.error.named'
tables = require('../config/tables')

htmlToPdf = (campaign) ->
  console.log "@@@@@@@ htmlToPdf()"
  console.log "campaign:\n#{JSON.stringify(campaign,null,2)}"

  return new Promise (resolve, reject) ->
    html = campaign.lob_content
    console.log "html:\n#{html}"
    #htmlBuffer = Buffer.from(html, 'utf8')
    wkhtmltopdf html, { pageSize: 'letter' }, (pdfErr, pdfStream) ->
      console.log "@@@@@@@ pdfStream callback"
      if pdfErr
        console.log "pdfStream pdfErr: #{pdfErr}"
        return reject(pdfErr)
      else
        # # formData:
        #     # key: key
                 
        #     policy: config.MAILING_PLATFORM.S3_UPLOAD.host.policy
        #     signature: config.MAILING_PLATFORM.S3_UPLOAD.host.signature
        #     'Content-Type': 'application/pdf'
        #     file: pdfStream

        key = config.MAILING_PLATFORM.S3_UPLOAD.getKey()
        console.log "key: #{key}"
        formData =
          Key: key
          AWSAccessKeyId: config.MAILING_PLATFORM.S3_UPLOAD.host.AWSAccessKeyId
          policy: config.MAILING_PLATFORM.S3_UPLOAD.host.policy
          acl: 'private'
          policy: config.MAILING_PLATFORM.S3_UPLOAD.host.policy
          signature: config.MAILING_PLATFORM.S3_UPLOAD.host.signature
          'Content-Type': 'application/pdf'
          attachments: [pdfStream]
          # custom_file:
          #   options:
          #     filename: key
          #     contentType: 'application/pdf'
        postOptions =
          url: config.MAILING_PLATFORM.S3_UPLOAD.host
          method: 'POST'
          formData: formData

        console.log "postOptions:\n#{JSON.stringify(postOptions,null,2)}"

        request.post postOptions, (postErr, httpResponse, body) ->
          console.log "@@@@@@@ request.post callback"
          if postErr
            console.log "request post postErr!:\n#{postErr}"
            return reject(postErr)
          else
            console.log "body:\n#{JSON.stringify(body,null,2)}"
            console.log "httpResponse.headers:\n#{JSON.stringify(httpResponse.headers,null,2)}"

          resolve(key)


module.exports =
  htmlToPdf: htmlToPdf
