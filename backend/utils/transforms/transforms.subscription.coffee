{validators, requireAllTransforms} = require '../util.validation'

module.exports =
  deactivation:
    body: validators.object subValidateSeparate:
      reason: validators.string()
