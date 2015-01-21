statuses = ['for sale', 'recently sold', 'pending', 'not for sale', 'saved']

thisEnum = {}
# object where space props get replaced with underscore
# thisEnum.not_for_sale = "not for sale"
statuses.forEach (v) ->
  thisEnum[v.replace(' ', '_')] =  v

module.exports =
  enum: thisEnum
  keys: statuses