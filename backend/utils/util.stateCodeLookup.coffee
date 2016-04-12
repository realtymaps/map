require '../../common/extensions/strings'
tables = require '../config/tables'


lookupPromise = null


stateCodeLookup = (stateName) ->
  if !lookupPromise  # saving the promise is an effective way to permanently cache the lookup hash
    lookupPromise = tables.lookup.usStates()
    .select('code', 'name')
    .then (rows) ->
      lookup = {}
      for row in rows
        lookup[row.name.toInitCaps()] = row.code
      return lookup

  lookupPromise
  .then (lookup) ->
    return lookup[stateName.toInitCaps()]


module.exports = stateCodeLookup
