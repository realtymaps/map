gulp = require('gulp');
require './vendor'
path = require '../paths'

gulp.task 'otherAssets', gulp.series 'vendor', ->
  # this is partially redundant with webpack, but we go ahead and do it anyway
  # so we don't have to think about it
  gulp.src path.rmap.assets
  .pipe gulp.dest path.destFull.assets