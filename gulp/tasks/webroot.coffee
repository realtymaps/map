gulp = require 'gulp'
paths = require '../../common/config/paths'

###
  Copy Files directly to the _public directory to be served up at webroot
###
gulp.task 'webroot', gulp.series ->
  gulp.src paths.webroot
  .pipe gulp.dest paths.dest.root
