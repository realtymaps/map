Promise =  require 'bluebird'
moment = require 'moment'

DATA_SOURCE_TYPES = [
  'mls'
  'county'
]

isTrump = ({row, existing, trump}) ->
  trump ?= DATA_SOURCE_TYPES[0]
  if !existing  # we don't have an old row
    return true
  if row.data_source_type != trump  # we have an old row, but the new row isn't preferred
    return false
  if existing.data_source_type != trump  # the old row isn't preferred and the new row is
    return  true

  return moment(existing.up_to_date).isBefore(row.up_to_date)

eachTrump = ({collection, trump}, cb) ->
  result = {}
  Promise.each collection, (row) ->
    existing = result[row.rm_property_id]
    if isTrump({row, existing, trump})
      cb({result, row})
  .then () ->
    result

### TRUMPING Data rows
MLS (default trump) rows trump all other rows if you have perms to them

The reason being is that mls rows should have all promoted information from
county rows related to the same rm_property_id.

However, mls data can be out of date as a listing could be older
than a country or tax record. Therefore there needs to be a switch to allow
details preference of mls vs county.
###
toTrumpHash = ({data, trump}) ->
  eachTrump {collection: data, trump}, ({result, row}) ->
    result[row.rm_property_id] = row


module.exports = {
  DATA_SOURCE_TYPES
  isTrump
  eachTrump
  toTrumpHash
}
