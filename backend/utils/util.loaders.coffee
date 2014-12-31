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
  loadSubmodules: (directoryName, regex) ->
    result = {}
    fs.readdirSync(directoryName).forEach (file) ->
      submoduleHandle = null
      if regex
        match = regex.exec(file)
        if (match)
          submoduleHandle = match[1]
      else
        submoduleHandle = file
      if submoduleHandle
        filePath = path.join directoryName, file
        result[submoduleHandle] = require(filePath)
    return result
