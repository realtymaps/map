paths = require '../../common/config/paths'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()

verbose = !!process.env.VERBOSE_BUILD

gulp.task 'minify-css', ->
  gulp.src paths.destFull.styles + '/*.css'
  .pipe $.minifyCss
    advanced: true
    aggressiveMerging: true
    keepBreaks: false
  .on   'error', conf.errorHandler 'Minify CSS'
  .pipe gulp.dest paths.destFull.styles
  .pipe $.size
    title: paths.dest.root
    showFiles: verbose

gulp.task 'minify-js', ->
  gulp.src paths.destFull.scripts + '/*.js'
  .pipe $.sourcemaps.init(loadMaps: true, largeFile: true)
  .pipe $.uglify
    mangle: true
    output:
      beautify: false # true for whitespace/indentation
  .on   'error', conf.errorHandler 'Uglify JS'
  .pipe $.sourcemaps.write('.')
  .pipe gulp.dest paths.destFull.scripts
  .pipe $.size
    title: paths.dest.root
    showFiles: verbose

gulp.task 'minify', gulp.parallel 'minify-js', 'minify-css'
