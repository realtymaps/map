statuses = ['for sale', 'pending', 'sold']

thisEnum = {}
# object where space props get replaced with underscore
# thisEnum.not_for_sale = "not for sale"
statuses.forEach (v) ->
  thisEnum[v.replace(' ', '_')] =  v

module.exports =
  enum: thisEnum
  keys: statuses
