_ = require 'lodash'
PDFDocument = require 'pdfkit'
pdfUtils = require '../utils/util.pdf.coffee'
bg = require './temp.postcard3.coffee'

templateProps =
  name: 'Postcard: Featured Property'
  description: 'A postcard to advertise a featured listing.'
  width: 8.5
  height: 5.55
  margins:
    top: 0
    bottom: 0
    left: 0
    right: 0
  lobTemplateId: 0

render = (data, stream) ->
  try
    doc = new PDFDocument pdfUtils.buildPageOptions(templateProps)
    doc.pipe(stream)
    doc.image(bg, 0, 0, width: templateProps.width*pdfUtils.inch, height: templateProps.height*pdfUtils.inch)
    doc.text('', 5.25*pdfUtils.inch, 4*pdfUtils.inch, continuing: true)
    pdfUtils.renderAddress(doc, data.to)
  finally
    doc.end()

module.exports = _.extend templateProps, {render: render}
