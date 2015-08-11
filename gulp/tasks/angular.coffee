paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
paths = require '../../common/config/paths'
vinylPaths = require 'vinyl-paths'
del = require 'del'
$ = require('gulp-load-plugins')()
require './markup'
require './scripts'
require './styles'

bundle = (app) ->
  gulp.src paths.destFull.scripts + "/#{app}.*.js"
  .pipe vinylPaths del
  .pipe $.concat "#{app}.bundle.js"
  .pipe gulp.dest paths.destFull.scripts


gulp.task 'bundle', gulp.series 'markup', 'scripts', -> bundle 'map'

gulp.task 'bundleAdmin', gulp.series 'markupAdmin', 'scriptsAdmin', -> bundle 'admin'

gulp.task 'angular', gulp.parallel 'styles', 'bundle'

gulp.task 'angularAdmin', gulp.parallel 'stylesAdmin', 'bundleAdmin'

gulp.task 'angularProd', gulp.series 'angular'  ->
  # uglify here
