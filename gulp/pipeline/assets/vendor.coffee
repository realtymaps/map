path = require '../../../common/config/paths'

log = require('gulp-util').log
globDebug = require('../../debug/glob')

bowerFilesLoader = require('main-bower-files')
bowerPath = "bower_components/"

bower = bowerFilesLoader
  filter: /[.](jpg|jpeg|gif|png)$/
  checkExistence: true
  # debugging:true

#globDebug bower, 'bower'

pipeline = _.flatten([bower])

#pipe.logToob "Vendor", pipeline
module.exports = pipeline
