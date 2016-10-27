gulp = require 'gulp'
es = require 'event-stream'
paths = require '../../common/config/paths'
plumber = require 'gulp-plumber'
onlyDirs = require '../util/onlyDirs'

vendorFontsPipe = require '../pipeline/vendor.fonts'
vendorAssetsPipe = require '../pipeline/vendor.assets'
# vendorPipe = require '../pipeline/vendor.scripts'
# vendorJsonPipe = require '../pipeline/vendor.json'


logger = (require '../util/logger').spawn('vendor')


gulp.task 'vendor_fonts', ->
  gulp.src(vendorFontsPipe)
  .pipe plumber()
  .pipe(onlyDirs es)
  .pipe(gulp.dest paths.destFull.fonts)

# gulp.task 'vendor_json', (done) ->
#   if vendorJsonPipe.length
#     return gulp.src(vendorJsonPipe, base: './bower_components')
#     .pipe plumber()
#     .pipe(onlyDirs es)
#     .pipe(gulp.dest paths.destFull.json)
#   done()

gulp.task 'vendor_assets', ->
  gulp.src(vendorAssetsPipe)
  .pipe plumber()
  .pipe(onlyDirs es)
  .pipe(gulp.dest paths.destFull.assets)

gulp.task 'vendor', gulp.parallel 'vendor_assets', 'vendor_fonts' #,'vendor_json', 'vendor_scripts', #'vendor_css'
