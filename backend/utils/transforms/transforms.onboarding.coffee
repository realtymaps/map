{validators, requireAllTransforms, notRequired} = require '../util.validation'
{VALIDATION}= require '../../config/config'
emailTransforms = require('./transforms.email')

module.exports =
  createUser:
    params: validators.object isEmptyProtect: true
    query: validators.object isEmptyProtect: true
    body: validators.object subValidateSeparate: requireAllTransforms
      password: validators.string(regex: VALIDATION.password)
      email: emailTransforms
      stripe_coupon_id: notRequired validators.string(minLength: 2)
      fips_code: notRequired validators.string(minLength: 5)
      mls_code:  notRequired validators.string(minLength: 2)
      mls_id:  notRequired validators.string(minLength: 2)
      first_name: validators.string(minLength: 2)
      last_name: validators.string(minLength: 2)

      plan: validators.object subValidateSeparate: requireAllTransforms
        name: validators.string(minLength: 3)

      token: notRequired validators.object subValidateSeparate: requireAllTransforms
        id: validators.string(minLength: 28)
        card: validators.object subValidateSeparate: requireAllTransforms
          id: validators.string(minLength: 28)
