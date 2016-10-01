_ = require 'lodash'

###
  Public: Remove all null and undefined fields from an object.

 - `object` The object to clean

  Returns the cleaned object.
###
_.cleanObject = (object, opts = {}) ->
  _.omit object, (it) ->
    if opts.null
      return _.isNull(it)
    if opts.undefined
      return _.isUndefined(it)
    else if opts.emptyString
      return it == ""
    _.isEmpty(it) && it != false && it != 0
