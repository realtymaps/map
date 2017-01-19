gulp = require 'gulp'
paths = require '../../common/config/paths'
$ = require('gulp-load-plugins')()

verbose = !!process.env.VERBOSE_BUILD

gulp.task 'gzip', ->
  gulp.src([paths.dest.root + '**/*', '!' + paths.dest.root + '**/*.gz'])
  .pipe $.gzip
    gzipOptions: level: 9
    threshold: 1024
  .pipe(gulp.dest(paths.dest.root))
  .pipe $.size
    title: paths.dest.root
    showFiles: verbose
