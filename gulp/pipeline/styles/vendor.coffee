pipe = require("../pipeInit").create()
path = require '../../paths'
_ = pipe._

log = require('gulp-util').log
globDebug = require('../../debug/glob')

bowerFilesLoader = require('main-bower-files')
bowerPath = "bower_components/"

selfHosted = [].mapPath path.lib.front.styles

bower = bowerFilesLoader
  filter: /[.]css$/
  checkExistence: true
#  debugging:true


#globDebug bower, 'bower'

pipeline = _.flatten([selfHosted, bower]).map (f) -> f.replace('.css','.min.css')

#pipe.logToob "Vendor", pipeline
module.exports = pipeline