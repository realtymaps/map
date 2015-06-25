_ = require 'lodash'
gulp = require 'gulp'
paths = require '../../common/config/paths'
plumber = require 'gulp-plumber'

getPaths = (app) ->
  return [
    paths[app].scripts, paths[app].styles, paths[app].stylus,
    paths[app].assets,
    paths[app].stylus, paths[app].stylusWatch
    paths[app].jade, paths[app].html
  ]

gulp.task 'watch_rest', ->
  rmapPaths = getPaths('rmap').concat([paths.common])
  adminPaths = getPaths('admin').concat([paths.common])

  gulp.watch rmapPaths, gulp.series 'webpack'
  gulp.watch adminPaths, gulp.series 'webpackAdmin'
  gulp.watch paths.bower, gulp.series 'vendor'

specCommon = "spec/common/**/*.coffee"
gulp.task 'watch', gulp.series 'watch_rest', ->
  gulp.watch ['gulp/**/*.coffee',"spec/gulp/**/*.coffee", specCommon], gulp.series 'gulpSpec'
  gulp.watch ['backend/**/*.coffee', 'spec/backend/**/*.coffee', specCommon], gulp.series 'backendSpec'
  gulp.watch ['frontend/**/*.coffee', 'spec/app/**/*.coffee', specCommon], gulp.series 'frontendSpec'
