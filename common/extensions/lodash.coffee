_ = require 'lodash'

###
  Public: Remove all null and undefined fields from an object.

 - `object` The object to clean

  Returns the cleaned object.
###
_.cleanObject = (object) ->
  _.omit(object, (it) -> _.isUndefined it )
