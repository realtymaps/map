{validators} = require '../util.validation'

module.exports =
  event:
    params: validators.object isEmptyProtect: true
    query:  validators.object isEmptyProtect: true
    body: validators.object subValidateSeparate:
      id: validators.string(minLength: 5, regex: /evt_/)
      object: validators.string(minLength: 5, regex: /^event$/)
      type: validators.string(minLength: 2)
      data: validators.object()
