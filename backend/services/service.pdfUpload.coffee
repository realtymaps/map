tables = require '../config/tables'
awsService = require './service.aws'
lobService = require './service.lob'
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
    mockLobData.options.aws_key = aws_key
    lobService.sendLetter mockLobData, 'test'
    .then (res) ->
      return {isValid: true}

    .catch (err) ->
      message = err.jse_summary
      if message.indexOf("File length/width is incorrect size.") >= 0
        # parse out the arcane codes for clean message
        message = err.jse_summary.match(/File length\/width is incorrect size.+/)[0]

      # truthy message implies err.jse_summary as expected
      if message
        return {
          isValid: false
          message: message
        }

      # account for whatever could have gone really wrong since we always expect a 'message'
      throw new Error(err, "Error encountered while doing file validation.")

instance = new PdfUploadService tables.mail.pdfUpload,
  idKeys: 'aws_key'
  debugNS: "pdfUploadService"

module.exports = instance
