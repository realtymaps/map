gulp = require 'gulp'
paths = require '../../common/config/paths'
plumber = require 'gulp-plumber'

gulp.task 'jsonMock', ->
  gulp.src paths.json
  .pipe plumber()
  .pipe(gulp.dest(paths.dest.root))
