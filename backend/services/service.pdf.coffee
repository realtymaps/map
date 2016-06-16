PopplerDocument = require('poppler-simple').PopplerDocument


getPdfPrice = (url) ->
  console.log "\n\ngetPdfPrice()"
  console.log "url:\n#{url}"
  console.log "PopplerDocument keys:\n#{JSON.stringify(Object.keys(PopplerDocument))}"

module.exports =
  getPdfPrice: getPdfPrice