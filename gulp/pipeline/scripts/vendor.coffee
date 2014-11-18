path = require '../../paths'

log = require('gulp-util').log
globDebug = require('../../debug/glob')

bowerFilesLoader = require('main-bower-files')

bower = bowerFilesLoader
  filter: /[.]js$/
  checkExistence: true
#  debugging:true


#globDebug bower, 'bower'

pipeline = _.flatten([bower])

#pipe.logToob "Vendor", pipeline
module.exports = pipeline
