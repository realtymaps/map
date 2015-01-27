PDFDocument = require 'pdfkit'
pdfUtils = require '../utils/util.pdf.coffee'
bg = require './temp.postcard1.coffee'

templateProps =
  name: 'Postcard: Just Listed'
  description: 'A postcard to advertise a new listing.'
  width: 8.5
  height: 11
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
  finally
    doc.end()

module.exports = _.extend templateProps, {render: render}
