gulp = require 'gulp'
log = require('gulp').log
sass = require 'gulp-sass'
gulpif = require 'gulp-if'
size = require 'gulp-size'
es = require 'event-stream'
paths = require '../paths'

concat = require 'gulp-concat'
onlyDirs = require '../util/onlyDirs'

vendorPipe = require '../pipeline/scripts/vendor'
vendorCssPipe = require '../pipeline/styles/vendor'
vendorFontsPipe = require '../pipeline/fonts/vendor'


gulp.task 'vendor_css', ->
  gulp.src(vendorCssPipe)
  .pipe(gulpif(/[.]scss$/, sass()))
  .pipe(onlyDirs es)
  .pipe(concat 'vendor.css')
  .pipe(size title: 'vendor.css')
  .pipe(gulp.dest "_public/" + paths.dest.styles)

gulp.task 'vendor_fonts', ->
  gulp.src(vendorFontsPipe)
  .pipe(onlyDirs es)
  .pipe(gulp.dest "_public/" + paths.dest.fonts)


gulp.task 'vendor_scripts', ->
  gulp.src(vendorPipe)
  .pipe(concat("vendor.js"))
  .pipe(gulp.dest "_public/" + paths.dest.scripts)


gulp.task 'vendor', ['vendor_scripts', 'vendor_css', 'vendor_fonts']