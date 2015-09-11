gulp = require 'gulp'
[
  './spec'
  './json'
  './express'
  './minify'
  './gzip'
  './complexity'
  './checkdir'
  './clean'
  './otherAssets'
  './watch'
  './angular'
].forEach (dep) ->
  # console.log 'requiring', dep
  require dep
#help = require('gulp-help')(gulp)

#gulp dependency hell
gulp.task 'spec_watch', gulp.parallel 'spec', 'watch'

gulp.task 'express_assets', gulp.parallel 'express', 'otherAssets'

gulp.task 'develop', gulp.series 'clean', 'express_assets', 'spec_watch'

gulp.task 'mock', gulp.series 'clean', 'jsonMock', 'express', 'watch'

gulp.task 'develop_no_spec', gulp.series 'clean', 'otherAssets', 'angular', 'angularAdmin', 'express', 'watch'

gulp.task 'no_spec', gulp.series 'develop_no_spec'

gulp.task 'prod', gulp.series 'prodAssetCheck', 'clean', 'otherAssets', 'angular', 'angularAdmin', 'minify', 'gzip'

gulp.task 'default', gulp.series 'develop'

gulp.task 'server', gulp.series 'default'

gulp.task 's', gulp.series 'server'
