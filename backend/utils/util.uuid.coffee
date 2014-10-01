crypto = require 'crypto'
base64url = require 'base64url'

# function to generate a 64-char session UUID, much larger than the default
# which is 24-char.  We don't make this a config option here because the
# session_security.session_id column is varchar(64); that table would need
# to be migrated if this value is increased
genUUID = () ->
  # increase security by throwing away some random bytes
  crypto.pseudoRandomBytes(8)
  # 48 bytes is 64 characters after base64 encoding
  sessionId = base64url(crypto.pseudoRandomBytes(48))
  return sessionId

# function to generate a 36-char security token
genToken = () ->
  # increase security by throwing away some random bytes
  crypto.pseudoRandomBytes(8)
  # 27 bytes is 36 characters after base64 encoding
  sessionId = base64url(crypto.pseudoRandomBytes(27))
  return sessionId

module.exports =
  genUUID: genUUID
  genToken: genToken
 