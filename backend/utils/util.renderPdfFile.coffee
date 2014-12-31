Promise = require 'bluebird'
moment = require 'moment'
fs = require 'fs'
config = require '../config/config'
loadSubmodules = (require './util.loaders').loadSubmodules
path = require 'path'

documentTemplates = loadSubmodules(path.join(__dirname, '../../common/documentTemplates'), /^document\.(\w+)\.coffee$/)

module.exports = 
  toFile: (templateId, data, options = {}) -> Promise.try () ->
    template = documentTemplates[templateId]
    if !template?
      return Promise.reject("Bad templateId specified")
    filename = "#{options.location||config.TEMP_DIR}/LOB_"
    if options.partialId
      filename += options.partialId+"_"
    filename += moment().format('YYYYMMDD-HHmmss')
    filename += '_'+Math.floor(0xFFFFFFFF*Math.random()).toString(36)+'.pdf'
    stream = fs.createWriteStream(filename, flags: 'wx')
    template.render(data, stream)
    new Promise (resolve, reject) ->
      stream.on 'finish', () -> resolve(filename)
      stream.on 'error', (err) -> reject(err)
