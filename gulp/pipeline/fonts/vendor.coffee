path = require '../../paths'

log = require('gulp-util').log
globDebug = require('../../debug/glob')

bowerFilesLoader = require('main-bower-files')
bowerPath = "bower_components/"

bower = bowerFilesLoader
  checkExistence: true
#  debugging:true


bower = bower.filter (f) ->
  f.contains('fonts')

#globDebug bower, 'bower'

pipeline = _.flatten([bower])

#pipe.logToob "Vendor", pipeline
module.exports = pipeline