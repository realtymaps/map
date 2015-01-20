#copied directly from ui-gmap
_isTrue = (val) ->
  val? and val isnt null and val is true or val is '1' or val is 'y' or val is 'true'

_isFalse = (value) ->
  ['false', 'FALSE', 0, 'n', 'N', 'no', 'NO'].indexOf(value) != -1

_booleanify = (obj, skips = []) ->
  _.without(_.keys(obj), skips).forEach (key) ->
    obj[key] = _isTrue obj[key]
  obj

module.exports =
  isBoolean: (val) ->
    _isTrue(val) or _isFalse(val)

  isTrue: _isTrue
  isFalse: _isFalse
  booleanify: _booleanify