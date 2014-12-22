path = require '../../paths'

log = require('gulp-util').log
globDebug = require('../../debug/glob')

bowerFilesLoader = require('main-bower-files')
bowerPath = "bower_components/"

bower = bowerFilesLoader
  filter: /[.]css$/
  checkExistence: true
#  debugging:true


#globDebug bower, 'bower'

pipeline = _.flatten([bower])
#minify afterwards as not all libs come minified
#.map (f) -> f.replace('.css','.min.css')

#console.log "!!!!!!!!!!!!!!!!!!!!!!!#{pipeline}"

module.exports = pipeline
