gulp = require('gulp')
require './webroot'
require './vendor'
paths = require '../../common/config/paths'

assetPaths = [
  paths.map.assets
  paths.admin.assets
]

gulp.task 'otherAssets', gulp.parallel 'webroot', 'vendor', ->
  gulp.src(assetPaths)
  .pipe gulp.dest paths.destFull.assets


gulp.task 'watch_otherAssets', (done) ->
  gulp.watch(assetPaths, gulp.series 'otherAssets')
  done()
