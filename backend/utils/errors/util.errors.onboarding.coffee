NamedError = require './util.error.named'

class MlsAgentNotVierified extends NamedError
  constructor: (args...) ->
    super('MlsAgentNotVierified', args...)

module.exports = {
  MlsAgentNotVierified
}
