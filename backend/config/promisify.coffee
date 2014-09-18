Promise = require "bluebird"

# Usually, something like the following will work:
#   Promise.promisifyAll(require 'someLib')
# which makes a promisified version of each exported function, using the
# suffix 'Async' (so someLib.nodeFunc becomes someLib.nodeFuncAsync)


bcrypt = require('bcrypt')
bcrypt.genSaltAsync = Promise.promisify(bcrypt.genSalt)
bcrypt.hashAsync = Promise.promisify(bcrypt.hash)
bcrypt.compareAsync = Promise.promisify(bcrypt.compare)


# we don't have access to promisify the entire session class, so we have to
# export it as middleware and promisify each instance
module.exports = {
  middleware:
    promisifySession: (req, res, next) ->
      Promise.promisifyAll(req.session)
      next()
}
