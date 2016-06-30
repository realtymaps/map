tables = require '../config/tables'
awsService = require './service.aws'
lobService = require './service.lob'
pdfService = require './service.pdf'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
mockLobData = require '../json/mail.fakeLetter.json'


class PdfUploadService extends ServiceCrud
  getSignedUrl: (aws_key) ->
    awsService.getTimedDownloadUrl
      extAcctName: awsService.buckets.PDF
      Key: aws_key
    .then (url) ->
      url

  validatePdf: (aws_key) ->
    @getSignedUrl(aws_key)
    .then (url) ->
      # validate dimensions.
      # If multiple validations are needed for a letter, a suggestion would be to create separate ones in the `pdfService`
      #   and test each one here, being able to return specific messages per validation.
      pdfService.validateDimensions(url)
      .then (isValid) ->
        message = if !isValid then "Page dimensions exceed 'Letter' size. Please be sure all pages are 8.5in x 11in." else null
        return {
          isValid
          message
        }

instance = new PdfUploadService tables.mail.pdfUpload,
  idKeys: 'aws_key'
  debugNS: "pdfUploadService"

module.exports = instance
