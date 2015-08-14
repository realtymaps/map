paths = require '../../common/config/paths'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()

gulp.task 'minify-css', ->
  gulp.src paths.destFull.styles + '/*.css'
  .pipe $.minifyCss
      advanced: true
      aggressiveMerging: true
      keepBreaks: false
  .on   'error', conf.errorHandler 'Minify CSS'
  .pipe gulp.dest paths.destFull.styles

gulp.task 'minify-js', ->
  gulp.src paths.destFull.scripts + '/*.js'
  .pipe $.uglify
      mangle: false
  .on   'error', conf.errorHandler 'Uglify JS'
  .pipe gulp.dest paths.destFull.scripts

gulp.task 'minify', gulp.parallel 'minify-js', 'minify-css'
