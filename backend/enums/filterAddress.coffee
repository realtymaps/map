address_parts = ['street_address_num', 'street_address_name', 'city', 'state', 'zip']

thisEnum = {}
address_parts.forEach (v) ->
  thisEnum[v] = v

module.exports =
  enum: thisEnum
  keys: address_parts
