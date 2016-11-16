Promise =  require 'bluebird'
moment = require 'moment'

DATA_SOURCE_TYPES = [
  'mls'
  'county'
]

isTrump = ({row, existing, trump, isBoth}) ->
  trump ?= DATA_SOURCE_TYPES[0]
  isBoth ?= true
  ret = row.data_source_type == trump && (existing.data_source_type == trump)
  if isBoth
    return ret
  !ret

existingIsNotPreferred = ({row, existing, trump}) ->
  isTrump({row, existing, trump, isBoth: false})

isOutdatedPreferred = ({row, existing, trump}) ->
  isTrump({row, existing, trump}) && moment(existing.up_to_date).isBefore(row.up_to_date)

### TRUMPING Data rows
MLS (default trump) rows trump all other rows if you have perms to them

The reason being is that mls rows should have all promoted information from
county rows related to the same rm_property_id.

However, mls data can be out of date as a listing could be older
than a country or tax record. Therefore there needs to be a switch to allow
details preference of mls vs county.
###
toTrumpHash = ({data, trump}) ->
  result = {}
  Promise.each data, (row) ->
    existing = result[row.rm_property_id]
    if(!existing ||
    existingIsNotPreferred({row, existing, trump}) ||
    isOutdatedPreferred({row, existing, trump}))
      result[row.rm_property_id] = row
  .then () ->
    result

module.exports = {
  DATA_SOURCE_TYPES
  isTrump
  existingIsNotPreferred
  isOutdatedPreferred
  toTrumpHash
}
