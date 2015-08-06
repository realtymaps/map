paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()
require './markup'
require './scripts'
require './styles'

gulp.task 'angular', gulp.parallel gulp.series('markup', 'scripts'), 'styles'
