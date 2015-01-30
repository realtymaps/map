moment = require 'moment'
PDFDocument = require 'pdfkit'
pdfUtils = require '../utils/util.pdf.coffee'
fonts = require './signature-fonts/index.coffee'
logo = require './temp.logo.coffee'

templateProps =
  name: 'Letter: Prospecting'
  description: 'A letter to an owner of record inquiring about a property.'
  width: 8.5
  height: 11
  margins:
    top: 0.65
    bottom: 1
    left: 1
    right: 1
  lobTemplateId: 0

render = (data, stream) ->
  try
    doc = new PDFDocument pdfUtils.buildPageOptions(templateProps)
    doc.pipe(stream)
    
    doc.font('Helvetica', 11)
    doc.text(moment().format('MMMM Do, YYYY'), doc.page.margins.left, doc.page.margins.top, align: 'right')
    doc.text('', doc.page.margins.left, doc.page.margins.top, continuing: true)
    pdfUtils.renderAddress(doc, data.from)
    .text(data.from.phone)
    .text(data.from.email)
    .moveDown(2)
    pdfUtils.renderAddress(doc, data.to)
    .moveDown(2)
    .text("Dear #{data.to.name},")
    .moveDown()
    .text("I am currently working with qualified customers who are wishing to purchase a new home and have
          specifically identified properties of interest in your area, including your residence located at
          #{data.ref.address_line1}.", align: 'justify')
    .moveDown()
    .text("Should you wish to explore matters further, I welcome the opportunity to speak with you personally
          and at your convenience.   Please feel free to contact me via email at #{data.from.email}, or direct by
          phone at #{data.from.phone}.  I look forward to hearing from you.", align: 'justify')
    .moveDown()
    .text("Sincerely,")
    pdfUtils.renderSignature(doc, fonts[data.style.signature], "#{data.from.name}", "Helvetica")
    doc.text(data.from.name)
    .moveDown()
    .image(logo, 2.25*pdfUtils.inch, doc.y, width: 4*pdfUtils.inch)
    .moveDown(4)
    .text("If your property is currently listed by a Real Estate Broker, please disregard this message. It is
          not our intention to solicit the listings of other Real Estates Brokers.", align: 'justify')
    ###
    # these rectangles show where the addresses need to be to avoid paying for an extra address page from Lob
    .rect(.5*pdfUtils.inch, .625*pdfUtils.inch, 3.25*pdfUtils.inch, .875*pdfUtils.inch)
    .stroke()
    .rect(.5*pdfUtils.inch, 1.75*pdfUtils.inch, 4*pdfUtils.inch, 1*pdfUtils.inch)
    .stroke()
    ###
  finally
    doc.end()

module.exports = _.extend templateProps, {render: render}
