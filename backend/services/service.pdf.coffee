htmltopdf = require('html-pdf')
Promise = require('bluebird')
request = require('request')
Buffer = require('buffer').Buffer
logger = require('../config/logger').spawn('service:pdf')
config = require('../config/config')
tables = require('../config/tables')
awsService = require('./service.aws')
PopplerDocument = require('poppler-simple').PopplerDocument
NamedError = require('../utils/errors/util.error.named')

class PdfUrlMaxAttemptError extends NamedError
  constructor: (args...) ->
    super('PdfUrlMaxRetries', args...)


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


getUrlPageCount = (url) ->
  logger.debug -> "Processing PDF url: #{url}"

  return new Promise (resolve, reject) ->
    maxRetries = config.MAILING_PLATFORM.READ_PDF_URL_RETRIES
    retry = 0

    # re-attempt logic loosely based on
    # http://stackoverflow.com/questions/18581483/how-to-do-repeated-requests-until-one-succeeds-without-blocking-in-node
    _attempt = () ->
      if retry >= maxRetries
        return reject(new PdfUrlMaxAttemptError("Failed to obtain PDF from #{url} after #{retry} attempts."))

      retry += 1
      chunks = []
      contentType = ""

      req = request.get(url)
      # grab the content-type so we can test on it later
      .on('response', (response) ->
        contentType = response.headers['content-type']
      )
      # accumulate our chunks
      .on('data', (chunk) ->
        chunks.push chunk
      )

      .on('end', () ->
        # retry condition - if an aws url is not ready yet when we attempt,
        # the content-type will be "application/xml" as an error message describing the key not available.
        # This allows us to reattempt, just in case, whenever we aren't getting pdf data.
        if contentType != "application/pdf"
          _attempt()
        else
          # throw our pdf chunks into mem
          pdfbuffer = Buffer.concat(chunks)
          try
            httpDoc = new PopplerDocument(pdfbuffer)
          catch err
            logger.error(msg = "Failed to open PDF data from #{url}: #{err}")
            return reject(new Error(err, msg))

          resolve(httpDoc.pageCount)
      )

      req.end()
      req.on('error', reject)

    _attempt()

getFilePageCount = (file) ->
  return new Promise (resolve, reject) ->
    try
      localDoc = new PopplerDocument(mylocalfile)
      resolve(localDoc.pageCount)
    catch err
      reject(err)


module.exports = {
  createFromCampaign
  getUrlPageCount
  getFilePageCount
  PdfUrlMaxAttemptError
}
