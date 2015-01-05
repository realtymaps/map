
module.exports =
  renderAddress: (doc, address) ->
    doc.text(address.name)
    .text(address.address_line1)
    if address.address_line2
      doc.text(address.address_line2)
    doc.text("#{address.address_city}, #{address.address_state}  #{address.address_zip}")
  renderSignature: (doc, font, text, restoreFont) ->
    oldFontSize = doc._fontSize
    doc.save()
    skewFactor = Math.tan(font.angle * Math.PI / 180);
    doc.font(font.data, font.signatureSize)
    .text('', {continuing: true})
    .transform(1, 0, skewFactor, 1, (doc.currentLineHeight(true)-doc.y)*skewFactor-(2*doc.currentLineHeight(false)-doc.currentLineHeight(true))*skewFactor+font.xOffset, 0)
    .text(text)
    .restore()
    .font(restoreFont, oldFontSize)
  inch: 72
 