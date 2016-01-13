generators = require './impl/util.error.impl.generators'

module.exports = generators.named [
  'StripeCard'
  'RateLimit'
  'StripeInvalidRequest'
  'StripeAPI'
  'StripeConnection'
  'StripeAuthentication'
]
