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

gulp.task 'developNoSpec', gulp.series gulp.parallel('angular', 'angularAdmin', 'otherAssets', 'express'), 'watch'

#note specs must come after watch since browserifyWatch also builds scripts
gulp.task 'develop', gulp.series 'developNoSpec', 'spec'

gulp.task 'mock', gulp.series 'jsonMock', 'express', 'watch'

gulp.task 'prod', gulp.series 'prodAssetCheck',  gulp.parallel('otherAssets', 'angular', 'angularAdmin'), 'minify', 'gzip'

gulp.task 'default', gulp.parallel 'develop'

gulp.task 'server', gulp.series 'default'

gulp.task 's', gulp.series 'server'
