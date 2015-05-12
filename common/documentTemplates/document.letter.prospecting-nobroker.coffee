_ = require 'lodash'
moment = require 'moment'
PDFDocument = require 'pdfkit'
pdfUtils = require '../utils/util.pdf.coffee'
fonts = require './signature-fonts/index.coffee'
logo = require './temp.logo.coffee'

templateProps =
  name: 'Letter: Prospecting (No Broker)'
  description: 'A letter to an owner of record inquiring about a property, but not from a broker.'
  width: 8.5
  height: 11
  margins:
    top: 1
    bottom: 1
    left: 1
    right: 1
  lobTemplateId: 0
  optionalFields:
    from:
      address_line1: true

render = (data, stream) ->
  try
    doc = new PDFDocument pdfUtils.buildPageOptions(templateProps)
    doc.pipe(stream)
    
    doc.font('Helvetica', 11)
    doc.text(moment().format('MMMM Do, YYYY'), doc.page.margins.left, doc.page.margins.top, align: 'right')
    doc.text('', doc.page.margins.left, doc.page.margins.top, continuing: true)
    pdfUtils.renderAddress(doc, data.to)
    .moveDown(2)
    .text("Dear #{data.to.name},")
    .moveDown()
    .text("I have a prospect who is interested in purchasing your property located at 
          #{data.ref.address_line1}.", align: 'justify')
    .moveDown()
    .text("     -   This would be a cash closing with no financing contingencies", align: 'justify')
    .text("     -   Any brokerage fees incurred will be the sole responsibility of the buyer", align: 'justify')
    .text("     -   Sale of property would be in \"as-is\" condition with no obligation of repairs to Seller", align: 'justify')
    .text("     -   30 day due diligence inspection period", align: 'justify')
    .text("     -   Close 15 days after expiration of due diligence", align: 'justify')
    .moveDown()
    .text("Please contact me at #{data.from.email} or call me at #{data.from.phone} if you would be interested in
          pursuing discussion on this.", align: 'justify')
    .moveDown()
    .text("Sincerely,")
    pdfUtils.renderSignature(doc, fonts[data.style.signature], "#{data.from.name}", "Helvetica")
    doc.text(data.from.name)
  finally
    doc.end()

module.exports = _.extend templateProps, {render: render}
