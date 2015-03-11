module.exports = (array, id = 'rm_property_id') ->
  obj = _.indexBy array, id
  obj.length = array.length
  obj