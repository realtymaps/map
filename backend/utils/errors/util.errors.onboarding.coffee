NamedError = require './util.error.named'

class MlsAgentNotVierified extends NamedError
  constructor: (args...) ->
    super('MlsAgentNotVierified', args...)

class UserExists extends NamedError
  constructor: (args...) ->
    super('UserExists', args...)

module.exports = {
  MlsAgentNotVierified
  UserExists
}
