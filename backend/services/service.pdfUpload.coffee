tables = require '../config/tables'
awsService = require './service.aws'
lobService = require './service.lob'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
mockLobData = require '../../spec/fixtures/backend/services/lob/mail.letter.json'

class PdfUploadService extends ServiceCrud
  getSignedUrl: (aws_key) ->
    awsService.getTimedDownloadUrl awsService.buckets.PDF, aws_key
    .then (url) ->
      url

  validatePdf: (aws_key) ->
    mockLobData.options.aws_key = aws_key
    lobService.createLetterTest mockLobData
    .then (res) ->
      return {isValid: true}

    .catch (err) ->
      message = err.jse_summary
      if message.indexOf("File length/width is incorrect size.") >= 0
        message = err.jse_summary.match(/The provided file has dimensions of.+/)[0]

      if Object.keys(err).length > 0
        return {
          isValid: false
          message: message
        }

instance = new PdfUploadService tables.mail.pdfUpload,
  debugNS: "pdfUploadService"

module.exports = instance
