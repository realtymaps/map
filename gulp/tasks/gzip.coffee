_ = require 'lodash'
gulp = require 'gulp'
paths = require '../../common/config/paths'
plumber = require 'gulp-plumber'
gzip = require 'gulp-gzip'

gulp.task 'gzip', ->
  gulp.src(paths.dest.root + "**/*")
  .pipe gzip
    gzipOptions: level: 9
    threshold: 1024
  .pipe(gulp.dest(paths.dest.root))
