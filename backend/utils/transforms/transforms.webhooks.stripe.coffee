_ = require 'lodash'
{validators} = require '../util.validation'

bodyRequest = () ->
  params: validators.object isEmptyProtect: true
  query:  validators.object isEmptyProtect: true
  body: null

# Note: Don't go too crazy here as we verify validate the event with stripe itself via its api
event = _.extend bodyRequest(),
  body: validators.object subValidateSeparate:
    id: validators.string(minLength: 5, regex: /evt_/)
    object: validators.string(minLength: 5, regex: /^event$/)
    type: validators.string(minLength: 2)
    data: validators.object()
    livemode: validators.boolean()

module.exports =
  event: event
