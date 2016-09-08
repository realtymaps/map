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

vendorPipe = require '../pipeline/vendor.scripts'
vendorCssPipe = require '../pipeline/vendor.styles'
vendorFontsPipe = require '../pipeline/vendor.fonts'
vendorAssetsPipe = require '../pipeline/vendor.assets'
vendorJsonPipe = require '../pipeline/vendor.json'

rework = require 'gulp-rework'
rework_url = require 'rework-plugin-url'
path = require 'path'

logger = (require '../util/logger').spawn('vendor')

gulp.task 'vendor_css', ->
  gulp.src(vendorCssPipe)
  .pipe plumber()
  .pipe(onlyDirs es)
  .pipe(concat 'vendor.css')
  .pipe rework rework_url  (url) ->
    # logger.debug "URL (#{url})"
    if url.match(/[.](woff|woff2|ttf|eot|otf)([?].*)?(#.*)?$/i) and !url.match(/^\/\//)
      r_url = url.replace '@{font-path}', ''
      r_url = "./#{r_url}".replace path.dirname("./#{r_url}"), '/fonts'
      logger.debug "rework_url #{url} -> #{r_url}"
      r_url
    else if url.match(/[.](jpg|jpeg|gif|png|svg|ico)([?].*)?(#.*)?$/i) and !url.match(/^\/\//)
      r_url = "./#{url}".replace path.dirname("./#{url}"), '/assets'
      logger.debug "rework_url #{url} -> #{r_url}"
      r_url
    else
      url
  .pipe(gulp.dest paths.destFull.styles)

gulp.task 'vendor_fonts', ->
  gulp.src(vendorFontsPipe)
  .pipe plumber()
  .pipe(onlyDirs es)
  .pipe(gulp.dest paths.destFull.fonts)

gulp.task 'vendor_json', (done) ->
  if vendorJsonPipe.length
    return gulp.src(vendorJsonPipe, base: './bower_components')
    .pipe plumber()
    .pipe(onlyDirs es)
    .pipe(gulp.dest paths.destFull.json)
  done()

gulp.task 'vendor_assets', ->
  gulp.src(vendorAssetsPipe)
  .pipe plumber()
  .pipe(onlyDirs es)
  .pipe(gulp.dest paths.destFull.assets)

gulp.task 'vendor_scripts', ->
  gulp.src(vendorPipe)
  .pipe plumber()
  .pipe(sourcemaps.init())
  .pipe(concat('vendor.js'))
  .pipe(sourcemaps.write())
  .pipe(gulp.dest paths.destFull.scripts)

gulp.task 'vendor', gulp.parallel 'vendor_json', 'vendor_scripts', 'vendor_css', 'vendor_fonts', 'vendor_assets'
