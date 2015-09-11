_ = require 'lodash'
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

developNoSpec = (additionalEndings, additionalAssets) ->
  assetsParallel = ['angular', 'angularAdmin', 'otherAssets']
  endsParallel = ['express', 'watch']

  if additionalAssets? and _.isArray additionalAssets
    assetsParallel = assetsParallel.concat additionalAssets

  if additionalEndings? and _.isArray additionalEndings
    endsParallel = endsParallel.concat additionalEndings

  gulp.series 'clean', gulp.parallel(assetsParallel...), gulp.parallel(endsParallel...)

gulp.task 'developNoSpec', developNoSpec()

# There is a specific reason why we are not just tacking on spec to developNoSpec as a series.. (IT IS SLOWER)
# instead we tack it into the last parallel
gulp.task 'develop', developNoSpec(['spec'])

gulp.task 'mock', gulp.series 'clean', 'jsonMock', 'express', 'watch'

gulp.task 'prod', gulp.series 'prodAssetCheck', 'clean', gulp.parallel('otherAssets', 'angular', 'angularAdmin'), 'minify', 'gzip'

gulp.task 'default', gulp.parallel 'develop'

gulp.task 'server', gulp.series 'default'

gulp.task 's', gulp.series 'server'
