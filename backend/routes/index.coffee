fs = require 'fs'
path = require 'path'
config = require '../config/config'
routes = require '../config/routes'
logger = require '../config/logger'

indexFilePath = path.normalize(__filename)

module.exports = (app) ->
  fs.readdirSync(__dirname).forEach (file) ->
    logger.debug "index: file: #{file}"
    filePath = path.join __dirname, file
    if !filePath is indexFilePath# and !filePath.contains 'routes'
      logger.debug "index: filePath: #{filePath}, \nfile: #{file}"
      baseFilename = path.basename file, path.extname(file)
      route = path.join __dirname, baseFilename
      require(route)(app)

  app.get routes.index, (req, res) ->
    res.sendfile "#{config.FRONTEND_ASSETS_PATH}/index.html"
