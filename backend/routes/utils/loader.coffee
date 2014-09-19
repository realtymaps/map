fs = require 'fs'
path = require 'path'
config = require '../../config/config'
logger = require '../../config/logger'
routes = require '../../../common/config/routes'

module.exports =
  loadRoutes: (app, indexFilePath, directoryName)->
    files = fs.readdirSync(directoryName)
    logger.log 'route', "files: %j", files, {}

    files.forEach (file) ->
      filePath = path.join directoryName, file

      if !(filePath == indexFilePath) and
          !filePath.contains('utils') and !filePath.contains('handles')
        logger.route " filePath: #{filePath}, \nfile: #{file}"
        logger.route " handles: #{filePath.contains('handles')}"
        baseFilename = path.basename file, path.extname(file)
        route = path.join directoryName, baseFilename
        require(route)?(app)
