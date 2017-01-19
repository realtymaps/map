{validateAndTransformRequest} = require '../utils/util.validation'
onboardingTransforms = require('../utils/transforms/transforms.onboarding')
internals = require './route.onboarding.internals'


module.exports =

  createUser:
    method: "post"
    handleQuery: true
    handle: (req, res, next) ->
      validateAndTransformRequest req, onboardingTransforms.createUser
      .then (validReq) ->
        internals.onboard(validReq.body)
