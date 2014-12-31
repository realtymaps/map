
module.exports =
  renderAddress: (doc, address) ->
    doc.text(address.address_line1)
    if address.address_line2
      doc.text(address.address_line2)
    doc.text("#{address.address_city}, #{address.address_state}  #{address.address_zip}")
