module.exports = (array, id = 'rm_property_id') ->
  obj = {}
  array.forEach (val) ->
    obj[val[id]] = val
  obj.length = array.length
  obj