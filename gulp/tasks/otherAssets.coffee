gulp = require('gulp');
path = require '../paths'

gulp.task 'otherAssets', () ->

  # this is partially redundnat with webpack, but we go ahead and do it anyway
  # so we don't have to think about it
  gulp.src path.assets
  .pipe gulp.dest path.destFull.assets;
