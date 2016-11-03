{validators} = require '../util.validation'

lookup =
  params: validators.object isEmptyProtect: true
  query: validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate:
    state: validators.string(minLength:2, maxLength:2)
    full_name: validators.string(minLength:2)
    mls: validators.string(minLength:2)
    id: validators.integer()

lookupAgent =
  params: validators.object isEmptyProtect: true
  query: validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate:
    data_source_id:
      input: 'mls_code'
      transform: validators.string(minLength:2)
      required: true
    license_number:
      input: 'mls_id'
      transform: validators.string(minLength:2)
      required: true


module.exports = {
  lookup
  lookupAgent
}
