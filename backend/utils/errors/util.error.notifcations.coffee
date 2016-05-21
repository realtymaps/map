NamedError = require('./util.error.named')

class BasicEmailError extends NamedError
  constructor: (@config_notification_ids, args...) ->
    super('BasicEmailError', args...)

class SmsError extends NamedError
  constructor: (@config_notification_id, args...) ->
    super('SmsError', args...)

module.exports = {
  BasicEmailError
  SmsError
}
