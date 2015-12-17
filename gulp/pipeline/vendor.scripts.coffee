path = require '../../common/config/paths'

bowerFilesLoader = require('main-bower-files')

bower = bowerFilesLoader
  filter: /[.]js$/
  checkExistence: true
#  debugging:true

pipeline = _.flatten([bower, path.lib.front.scripts + '/vendor/**/*.*'])

module.exports = pipeline
