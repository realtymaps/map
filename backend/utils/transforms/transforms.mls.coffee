{validators, requireAllTransforms} = require '../util.validation'

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

queryPhoto =
  params: requireAllTransforms validators.object subValidateSeparate: requireAllTransforms
    mlsId: validators.string(minLength:2)
    databaseId: validators.string(minLength:2)
  query:
    transform: validators.object subValidateSeparate:
      ids:
        transform: validators.object(json:true)
        required: true
      photoType: validators.string(minLength:2)
    required: true
  body: validators.object isEmptyProtect: true


paramPhoto =
  params: requireAllTransforms validators.object subValidateSeparate: requireAllTransforms
    photoIds: validators.string(minLength:2)
    mlsId: validators.string(minLength:2)
    databaseId: validators.string(minLength:2)
  query: validators.object subValidateSeparate:
    photoType: validators.string(minLength:2)
  body: validators.object isEmptyProtect: true

module.exports = {
  lookup
  lookupAgent
  queryPhoto
  paramPhoto
}
