gulp = require 'gulp'
paths = require '../../common/config/paths'
$ = require('gulp-load-plugins')()

gulp.task 'gzip', ->
  gulp.src(paths.dest.root + "**/*")
  .pipe $.gzip
    gzipOptions: level: 9
    threshold: 1024
  .pipe(gulp.dest(paths.dest.root))
  .pipe $.size
    title: paths.dest.root
    showFiles: true
