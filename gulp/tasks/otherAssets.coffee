gulp = require('gulp');
require './vendor'
paths = require '../../common/config/paths'

gulp.task 'otherAssets', gulp.series 'vendor', ->
  # this is partially redundant with webpack, but we go ahead and do it anyway
  # so we don't have to think about it

  gulp.src paths.rmap.assets
  .pipe gulp.dest paths.destFull.assets
