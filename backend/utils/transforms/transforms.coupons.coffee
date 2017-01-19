{validators} = require '../util.validation'
#notRequired

module.exports =
  isValid:
    params: validators.object isEmptyProtect: true
    body: validators.object isEmptyProtect: true
    query: validators.object subValidateSeparate:
      stripe_coupon_id:
        transform: validators.string(minLength: 2)
        required: true
      isSpecial: validators.boolean(truthy: 'true', falsy: 'false')
