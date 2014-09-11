fs = require 'fs'
path = require 'path'
config = require '../config/config'

indexFilePath = path.normalize(__filename)

module.exports = (app) ->
  fs.readdirSync(__dirname).forEach((file) ->
    filePath = path.join __dirname, file
    unless filePath is indexFilePath
      baseFilename = path.basename file, path.extname(file)
      route = path.join __dirname, baseFilename
      require(route)(app)
  )
  app.get "/", (req, res) ->
    res.sendfile "#{config.FRONTEND_ASSETS_PATH}/index.html"
