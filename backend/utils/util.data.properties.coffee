
module.exports =

  joinSavedProperties: (state, data) ->
    return if !state
    # joining saved props to the filter data, this could be done in a stored proc as well (my guess)
    # passing on savedDetails including notes
    data.forEach (row) ->
      maybeProp = state.properties_selected?[row.rm_property_id]
      row.price = parseInt(row.price)
      row.savedDetails = if maybeProp then maybeProp else undefined
