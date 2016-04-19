{validators, requireAllTransforms} = require '../util.validation'

# parameter validation for sensitive payment operators can live here
module.exports =
  replaceDefaultSource:
    query: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true
    params: validators.object subValidateSeparate: requireAllTransforms
      source: validators.string(minLength: 28)

