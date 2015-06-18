gulp = require 'gulp'
require './spec'
require './json'
require './express'
require './minify'
require './gzip'

#help = require('gulp-help')(gulp)
del = require 'del'
plumber = require 'gulp-plumber'
util = require 'gulp-util'

gulp.task 'clean', (done) ->
  # done is absolutely needed to let gulp known when this async task is done!!!!!!!
  del ['_public', '*.log'], done

#gulp dependency hell
gulp.task 'express_watch', gulp.series 'express', 'watch'

gulp.task 'develop', gulp.series 'clean', 'spec', 'express_watch'

gulp.task 'mock', gulp.series 'clean', 'specMock', 'jsonMock', 'express', 'watch'

gulp.task 'develop_no_spec', gulp.series 'clean', 'webpack', 'webpackAdmin', 'express', 'watch'

gulp.task 'no_spec', gulp.series 'develop_no_spec'

gulp.task 'prod', gulp.series 'clean', 'webpackProd', 'webpackAdmin', 'minify', 'gzip', 'express'

gulp.task 'default', gulp.series 'develop'

gulp.task "server", gulp.series 'default'

gulp.task 's', gulp.series 'server'
