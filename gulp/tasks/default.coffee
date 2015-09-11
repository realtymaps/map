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

gulp.task 'developNoSpec', gulp.series 'clean', gulp.parallel('angular', 'angularAdmin', 'otherAssets'), gulp.parallel('express', 'watch')

gulp.task 'develop', gulp.series 'developNoSpec', 'spec'

gulp.task 'mock', gulp.series 'clean', 'jsonMock', 'express', 'watch'

gulp.task 'noSpec', gulp.series 'developNoSpec'

gulp.task 'prod', gulp.series 'prodAssetCheck', 'clean', 'otherAssets', 'angular', 'angularAdmin', 'minify', 'gzip'

gulp.task 'default', gulp.series 'develop'

gulp.task 'server', gulp.series 'default'

gulp.task 's', gulp.series 'server'
