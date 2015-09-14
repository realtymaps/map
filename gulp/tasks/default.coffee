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

#gulp spec has been seperated as to not collide with the actual build routine (it invalidates the spec due to races)

gulp.task 'developNoSpec', gulp.series 'clean', 'gulpSpec', 'otherAssets', gulp.parallel('express', 'watch')

#note specs must come after watch since browserifyWatch also builds scripts
gulp.task 'develop', gulp.series 'developNoSpec', 'spec'

gulp.task 'mock', gulp.series 'clean', 'jsonMock', 'express', 'watch'

gulp.task 'prod', gulp.series 'prodAssetCheck', 'clean', gulp.parallel('otherAssets', 'angular', 'angularAdmin'), 'minify', 'gzip'

gulp.task 'default', gulp.parallel 'develop'

gulp.task 'server', gulp.series 'default'

gulp.task 's', gulp.series 'server'
