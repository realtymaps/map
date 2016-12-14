require './stream'

libs = [
  require 'knex/lib/raw'
  require 'knex/lib/query/builder'
  require 'knex/lib/schema/builder'
]

# coffeelint: disable=check_scope
for key, lib of libs
# coffeelint: enable=check_scope
  lib::stringify = (errCb) ->
    @stream()
    .on 'error', (err)->
      errCb(err) if errCb
    .stringify()
