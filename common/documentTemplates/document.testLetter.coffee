moment = require 'moment'
PDFDocument = require 'pdfkit'
pdfUtils = require '../utils/util.pdf.coffee'


module.exports =
  name: 'Test Inquiry Document'
  description: 'A basic letter of inquiry to an owner of record about a property.'
  render: (data, stream) ->
    doc = new PDFDocument()
    doc.pipe(stream)
    
    doc.font('Times-Roman', 13)
    .moveTo(70, 120)
    pdfUtils.renderAddress(doc, data.from)
    .moveDown()
    .text(moment().format('MMMM Do, YYYY'))
    .moveDown(3)
    .text(data.to.name)
    pdfUtils.renderAddress(doc, data.to)
    .moveDown()
    .text("Dear #{data.to.name},")
    .moveDown()
    .text("Our records indicate you are the current owner of the property located at #{data.ref.address_line1} in
          #{data.ref.address_city}, #{data.ref.address_state}.  We are interested in discussing your property and
          its possible sale.  Please contact us by phone at #{data.from.phone}, or by email at #{data.from.email}.")
    .moveDown()
    .text("Sincerely,")
    .moveDown(0.5)
    # we should be able to fork pdfkit and add our own fonts to it, so we can use a good script font for signatures
    .font("Helvetica-BoldOblique", 20)
    .text("   #{data.from.name}")
    
    doc.end()
 