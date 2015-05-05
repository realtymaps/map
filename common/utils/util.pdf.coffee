_ = require 'lodash'


INCH_MULTIPLIER = 72

module.exports =
  renderAddress: (doc, address) ->
    doc.text(address.name)
    .text(address.address_line1)
    if address.address_line2
      doc.text(address.address_line2)
    doc.text("#{address.address_city}, #{address.address_state}  #{address.address_zip}")
  renderSignature: (doc, font, name, restoreFont) ->
    oldFontSize = doc._fontSize
    doc.save()
    skewFactor = Math.tan(-font.angle * Math.PI / 180);
    doc.font(font.data, font.signatureSize)
    .text('', {continuing: true})
    .transform(1, 0, skewFactor, 1, (doc.currentLineHeight(true)-doc.y)*skewFactor-(2*doc.currentLineHeight(false)-doc.currentLineHeight(true))*skewFactor+font.xOffset, 0)
    .text(name)
    .restore()
    .font(restoreFont, oldFontSize)
  buildAddresses: (property) ->
    ownerStreetAddress = "#{(property.owner_street_address_num||'')} #{(property.owner_street_address_name||'')} #{(property.owner_street_address_unit||'')}".trim()
    addresses =
      to:
        name: property.owner_name
        address_line1: property.owner_name2 || ownerStreetAddress
        address_line2: if !property.owner_name2 then null else ownerStreetAddress
        address_city: "#{property.owner_city}"
        address_state: "#{property.owner_state}"
        address_zip: "#{property.owner_zip}"
      ref:
        address_line1: "#{(property.street_address_num||'')} #{(property.street_address_name||'')} #{(property.street_address_unit||'')}".trim()
        address_city: "#{property.city}"
        address_state: "#{property.state}"
        address_zip: "#{property.zip}"
    # LOB can't handle null/undefined properties -- the key needs to be unset
    if !addresses.to.address_line2
      delete addresses.to.address_line2
    return addresses
  inch: INCH_MULTIPLIER
  buildPageOptions: (templateProps, options) ->
    options = _.extend({}, templateProps, options)
    result = {}
    if options.margins?
      result.margins = _.mapValues options.margins, (value) ->
        value*INCH_MULTIPLIER
    if options.width? && options.height?
      result.size = [options.width*INCH_MULTIPLIER, options.height*INCH_MULTIPLIER]
    result
