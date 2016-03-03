tables = require '../config/tables'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'

class PdfUploadService extends ServiceCrud

instance = new PdfUploadService tables.mail.pdfUpload,
  debugNS: "pdfUploadService"
module.exports = instance
