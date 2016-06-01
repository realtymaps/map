_ = require 'lodash'
moment = require 'moment'
PDFDocument = require 'pdfkit'
pdfUtils = require '../utils/util.pdf.coffee'
fonts = require './signature-fonts/index.coffee'
logo = require './temp.logo.coffee'


templateProps =
  name: 'Letter: Expired Listing'
  description: 'A letter to an owner of record about an expired listing.'
  width: 8.5
  height: 11
  margins:
    top: 1
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
    pdfUtils.renderAddress(doc, data.to)
    .moveDown(2)
    .text("Hello #{data.to.name},")
    .moveDown()
    .text("I noticed your home listing expired recently and am sorry to hear that your home has not yet sold.
          The home sales process can certainly be a stressful and exhausting process.", align: 'justify')
    .moveDown()
    .text("Despite the challenges of today’s real estate market, I have seen success with real estate sales in your
          area. My recent sales of homes in your area include:", align: 'justify')
    .moveDown()
    .text("     -   518 Galloway Dr, a 3-bedroom house listed for 3 months and sold for $193,500", align: 'justify')
    .text("     -   109 Yellow Piper Ct, a 3-bedroom house listed for 2.5 months and sold for $175,000", align: 'justify')
    .text("     -   3224 McClellan Ave, a 4-bedroom house listed for 5 months and sold for $241,000", align: 'justify')
    .moveDown()
    .text("I would be thrilled to take the burden and stress of the home sales process off your shoulders. Please
          consider hiring me as your new listing agent. I have some creative ideas to ensure your property moves
          quickly and garners a sales price commensurate with its market value. I hope to hear from you soon.", align: 'justify')
    .moveDown()
    .text("Best Wishes,")
    pdfUtils.renderSignature(doc, fonts[data.style.signature], "#{data.from.name}", "Helvetica")
    pdfUtils.renderAddress(doc, data.from)
    .text(data.from.phone)
    .text(data.from.email)
    .moveDown(2)
    .image(logo, 2.25*pdfUtils.inch, doc.y, width: 4*pdfUtils.inch)
    .moveDown(1)
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
