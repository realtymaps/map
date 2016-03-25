tables = require '../config/tables'
awsService = require('./service.aws')
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'

class PdfUploadService extends ServiceCrud
  getSignedUrl: (aws_key) ->
    awsService.getTimedDownloadUrl
      extAcctName: awsService.buckets.PDF
      Key: aws_key
    .then (url) ->
      url

instance = new PdfUploadService tables.mail.pdfUpload,
  debugNS: "pdfUploadService"

module.exports = instance
