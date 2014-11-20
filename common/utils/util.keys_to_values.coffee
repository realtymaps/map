###
  Point of this library is to not need to copy past key to values to save typing
  so no need to
  obj =
    val1: 'val1'
    val2: 'val2'

  This function automates that!
###
#note lodash is a global dependency
module.exports = (obj) ->
  # set all keys to the key string name
  _.keys(obj).forEach (k) ->
    obj[k] = k
  obj