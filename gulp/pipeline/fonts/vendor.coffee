pipe = require("../pipeInit").create()
path = require '../../paths'
_ = pipe._

log = require('gulp-util').log
globDebug = require('../../debug/glob')

bowerFilesLoader = require('main-bower-files')
bowerPath = "bower_components/"

selfHosted = [].mapPath path.lib.front.fonts

bower = bowerFilesLoader
  checkExistence: true
#  debugging:true


bower = bower.filter (f) ->
  f.contains('fonts')

#globDebug bower, 'bower'

pipeline = _.flatten([selfHosted, bower])

#pipe.logToob "Vendor", pipeline
module.exports = pipeline