PopplerDocument = require('poppler-simple').PopplerDocument
Buffer = require('buffer').Buffer
Promise = require 'bluebird'
request = require 'request'
logger = require('../config/logger').spawn('service:pdf')
config = require('../config/config')


NamedError = require '../utils/errors/util.error.named'

class PdfUrlMaxAttemptError extends NamedError
  constructor: (args...) ->
    super('PdfUrlMaxRetries', args...)


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


module.exports =
  getUrlPageCount: getUrlPageCount
  getFilePageCount: getFilePageCount
  PdfUrlMaxAttemptError: PdfUrlMaxAttemptError
