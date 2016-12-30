gulp = require 'gulp'
require './spec'
require './json'
require './express'
require './minify'
require './gzip'
require './complexity'
require './clean'
require './otherAssets'
require './watch'
require './angular'
require './mocha'


#this allows `gulp help` task to work which will display all taks via CLI so yes it is used
# help = require('gulp-help')(gulp) #BROKEN IN GULP 4
gulp.task 'mapAssets', gulp.series 'angular', 'otherAssets'

gulp.task 'mapAssetsWatch', gulp.series 'angular', 'otherAssets', 'angularWatch'

gulp.task 'adminAssets', gulp.series 'angularAdmin', 'otherAssets'

gulp.task 'adminAssetsWatch', gulp.series 'angularAdmin', 'otherAssets', 'angularWatchAdmin'


gulp.task 'frontendAssets', gulp.series 'mapAssets', 'angularAdmin'

gulp.task 'frontendAssetsWatch', gulp.series 'frontendAssets', 'watch_all_front'

gulp.task 'frontendAssetsWatchSpec', gulp.series 'frontendAssets', gulp.parallel 'watch_all_front', 'frontendSpec'

gulp.task 'developNoSpec', gulp.series 'clean', gulp.parallel('frontendAssets', 'express'), 'watch'

#note specs must come after watch since browserifyWatch also builds scripts
gulp.task 'develop', gulp.series 'developNoSpec', 'spec'

gulp.task 'mock', gulp.series 'clean', 'jsonMock', 'express', 'watch'

gulp.task 'prod', gulp.series('otherAssets',
  'angularProd', 'angularAdminProd', 'minify', 'gzip')

gulp.task 'default', gulp.parallel 'develop'

gulp.task 'server', gulp.series 'default'

gulp.task 's', gulp.series 'server'
