ExpressResponse = require '../utils/util.expressResponse'
globby = require 'globby'
logger = require('../config/logger').spawn('flamegraph')
{exec} = require 'child_process'

make = (callback) ->
  exec './scripts/misc/flamegraph', (err, stdout, stderr) ->
    logger.info "creating flamegraph"
    logger.info stdout
    callback stdout if callback

handleGetRoute = (req, res, next) ->
  if !req.query.file
    globby('/tmp/*.flame.svg')
    .then (files) ->
      response = new ExpressResponse(files.sort().join('\n'))
      response.format = 'text'
      next(response)
  else if req.query.file == 'new'
    make (filename) ->
      response = new ExpressResponse()
      response.download = filename
      next(response)
  else if req.query.file == 'last'
    globby('/tmp/*.flame.svg')
    .then (files) ->
      if files.length == 0
        response = new ExpressResponse('No memdump files found.')
        response.format = 'text'
        next(response)
      else
        response = new ExpressResponse()
        response.download = files[files.length-1]
        next(response)
  else
    response = new ExpressResponse()
    response.download = req.query.file
    next(response)

make()

module.exports = {
  make
  handleGetRoute
}
