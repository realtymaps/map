NamedError = require('./util.error.named')
httpStatus = require '../../../common/utils/httpStatus'


class OurRetsError extends NamedError

class UknownMlsConfig extends OurRetsError
  constructor: (args...) ->
    super('UknownMlsConfig', args...)
    @returnStatus = httpStatus.NOT_FOUND

module.exports = {
  OurRetsError
  UknownMlsConfig
}
