moment = require 'moment'
PDFDocument = require 'pdfkit'
pdfUtils = require '../utils/util.pdf.coffee'
fonts = require './signature-fonts/index.coffee'


templateProps =
  name: 'Letter: Preforeclosure Prospecting'
  description: 'A letter to an owner of record about preforeclosure and short sales.'
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
    .text("Dear #{data.to.name},")
    .moveDown()
    .text("As you know, the economic recession has left many home owners in a challenging financial position.
          Navigating the foreclosure process can prove stressful, and identifying alternatives to foreclosure is
          tricky.", align: 'justify')
    .moveDown()
    .text("My name is #{data.from.name} and I am a real estate agent with #{data.from.address_line1}. I specialize
          in working with home sellers who are underwater on their mortgage, or are facing foreclosure. For many home
          sellers, foreclosure is a dark time in life. Through my work, I provide a much needed beacon of hope for my
          clients to lift out of such a crisis.", align: 'justify')
    .moveDown()
    .text("I would be thrilled to take the burden and stress of the home sales process off your shoulders. Please
          consider hiring me as your new listing agent. I have some creative ideas to ensure your property moves
          quickly and garners a sales price commensurate with its market value. I hope to hear from you soon.", align: 'justify')
    .moveDown()
    .text("A short sale is one alternative to foreclosure. In a short sale, the home owner, real estate professional,
          and lender work together to form an agreement to sell a home at current market value; this agreed upon value
          is typically below the existing balance on the home owner’s mortgage. The property is able to transfer hands
          to a new owner, removing the overhead and risk from the lender’s portfolio and relieving the existing home
          owner of the burden of an underwater mortgage. The short sale process can prove challenging, stressful, and
          time consuming; it requires persistence and dedication. As a specialist in short sales and foreclosures, I
          am well-versed in the ins-and-outs of this process, and knowledgeable about the ways to move such
          transactions to completion. My work allows my clients to realize the freedom they desire from the unwanted
          weight of an underwater mortgage.", align: 'justify')
    .moveDown()
    .text("If you or someone you know is facing foreclosure, please do not hesitate to contact me. I would be happy to
          help during this challenging time.", align: 'justify')
    .moveDown()
    .text("Best Wishes,")
    pdfUtils.renderSignature(doc, fonts[data.style.signature], "#{data.from.name}", "Helvetica")
    pdfUtils.renderAddress(doc, data.from)
    .text(data.from.phone)
    .text(data.from.email)
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
