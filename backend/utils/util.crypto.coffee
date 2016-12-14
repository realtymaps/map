crypto = require("crypto")

md5 = (data) ->
  crypto.createHash('md5')
  .update(data)
  .digest('hex')


module.exports = {
  md5
}
