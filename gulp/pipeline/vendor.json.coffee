_ = require 'lodash'

bowerFilesLoader = require('main-bower-files')

bower = bowerFilesLoader
  filter: /[.]json$/
  checkExistence: true
#  debugging:true

module.exports = _.flatten([bower])
