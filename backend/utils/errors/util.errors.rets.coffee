NamedError = require('./util.error.named')


class OurRetsError extends NamedError

class UknownMlsConfig extends OurRetsError
  constructor: (args...) ->
    super('UknownMlsConfig', args...)

module.exports = {
  OurRetsError
  UknownMlsConfig
}
