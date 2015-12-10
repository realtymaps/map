gulp = require 'gulp'
log = require('gulp').log
gulpif = require 'gulp-if'
size = require 'gulp-size'
es = require 'event-stream'
paths = require '../../common/config/paths'
plumber = require 'gulp-plumber'
sourcemaps = require 'gulp-sourcemaps'

concat = require 'gulp-concat'
onlyDirs = require '../util/onlyDirs'

vendorPipe = require '../pipeline/scripts/vendor'
vendorCssPipe = require '../pipeline/styles/vendor'
vendorFontsPipe = require '../pipeline/fonts/vendor'
vendorAssetsPipe = require '../pipeline/assets/vendor'

rework = require 'gulp-rework'
rework_url = require 'rework-plugin-url'
path = require 'path'

gulp.task 'vendor_css', ->
  gulp.src(vendorCssPipe)
  .pipe plumber()
  .pipe(onlyDirs es)
  .pipe(concat 'vendor.css')
  .pipe rework rework_url  (url) ->
    if url.match /[.](woff|woff2|ttf|eot|otf)(#.*)?$/ and !url.match /^\/\//
      "./#{url}".replace path.dirname("./#{url}"), '/fonts'
    else if url.match /[.](jpg|jpeg|gif|png|svg|ico)$/ and !url.match /^\/\//
      "./#{url}".replace path.dirname("./#{url}"), '/assets'
    else
      url
  .pipe(gulp.dest paths.destFull.styles)

gulp.task 'vendor_fonts', ->
  gulp.src(vendorFontsPipe)
  .pipe plumber()
  .pipe(onlyDirs es)
  .pipe(gulp.dest paths.destFull.fonts)

gulp.task 'vendor_assets', ->
  gulp.src(vendorAssetsPipe)
  .pipe plumber()
  .pipe(onlyDirs es)
  .pipe(gulp.dest paths.destFull.assets)

gulp.task 'vendor_scripts', ->
  gulp.src(vendorPipe)
  .pipe plumber()
  .pipe(concat('vendor.js'))
  .pipe(gulp.dest paths.destFull.scripts)

gulp.task 'vendor', gulp.parallel 'vendor_scripts', 'vendor_css', 'vendor_fonts', 'vendor_assets'
