logger = require '../config/logger'
pack = require '../../package.json'

# I'm not sure that we'll actually need this route, but it was convenient for testing

module.exports = (app) ->
  app.get '/version/', (req, res) ->
    logger.info "version info"
    res.send("#{pack.name}: #{pack.version}")
