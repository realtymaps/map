gulp = require('gulp')
require './webroot'
require './vendor'
paths = require '../../common/config/paths'

gulp.task 'otherAssets', gulp.parallel 'webroot', 'vendor', ->
  gulp.src [
    paths.map.assets
    paths.admin.assets
  ]
  .pipe gulp.dest paths.destFull.assets
