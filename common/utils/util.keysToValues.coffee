_ = require 'lodash'

###
  Point of this library is to not need to copy past key to values to save typing
  so no need to
  obj =
    val1: 'val1'
    val2: 'val2'

  This function automates that!

  It can even handle nested objects.  Any key with an object value is recursively traversed,
  and the leaf/endpoint string value is the joined value of the parent keys (default join
  string is '.').

  If you want to automate most of the values but need to override some, you can -- this function
  will ignore any keys that already have a string value.
###
keysToValues = (obj, joinStr='.', stack=[]) ->

  _.mapValues obj, (value, key) ->
    if typeof(value) == 'string'
      # value is a manual override
      return value

    substack = _.clone(stack)
    substack.push(key)
    if typeof(value) == 'object'
      # do recursive traversal
      return keysToValues(value, joinStr, substack)
    else
      # leaf node, set the value
      return substack.join(joinStr)

module.exports = keysToValues
