fs = require 'fs'
path = require 'path'
config = require '../config/config'
logger = require '../config/logger'

module.exports =
  loadRoutes: (app, indexFilePath, directoryName)->
    files = fs.readdirSync(directoryName)
    logger.log 'route', "files: %j", files, {}

    files.forEach (file) ->
      filePath = path.join directoryName, file

      if filePath != indexFilePath and !filePath.contains('handles')
        logger.route " filePath: #{filePath}, \nfile: #{file}"
        logger.route " handles: #{filePath.contains('handles')}"
        require(filePath)?(app)
  loadValidators: (directoryName) ->
    result = {}
    fs.readdirSync(directoryName).forEach (file) ->
      match = (/^util\.validation\.(\w+)\.coffee$/).exec(file)
      if (match)
        filePath = path.join directoryName, file
        result[match[1]] = require(filePath)
    return result
