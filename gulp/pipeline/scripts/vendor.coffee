pipe = require("../pipeInit").create()
path = require '../../paths'
_ = pipe._

log = require('gulp-util').log
globDebug = require('../../debug/glob')

bowerFilesLoader = require('main-bower-files')

selfHosted = ([]).mapPath path.lib.front.scripts

bower = bowerFilesLoader
  filter: /[.]js$/
  checkExistence: true
#  debugging:true


#globDebug bower, 'bower'

pipeline = _.flatten([selfHosted, bower])

#pipe.logToob "Vendor", pipeline
module.exports = pipeline
