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
  require dep

#this allows `gulp help` task to work which will display all taks via CLI so yes it is used
# help = require('gulp-help')(gulp) #BROKEN IN GULP 4

gulp.task 'frontendAssets', gulp.series 'angular', 'angularAdmin', 'otherAssets'

gulp.task 'developNoSpec', gulp.series 'clean', gulp.parallel('frontendAssets', 'express'), 'watch'

#note specs must come after watch since browserifyWatch also builds scripts
gulp.task 'develop', gulp.series 'developNoSpec', 'spec'

gulp.task 'mock', gulp.series 'clean', 'jsonMock', 'express', 'watch'

gulp.task 'prod', gulp.series 'prodAssetCheck',  gulp.series('otherAssets', 'angular', 'angularAdmin'), 'minify', 'gzip'

gulp.task 'default', gulp.parallel 'develop'

gulp.task 'server', gulp.series 'default'

gulp.task 's', gulp.series 'server'
