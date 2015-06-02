_ = require 'lodash'
gulp = require 'gulp'
path = require '../paths'
plumber = require 'gulp-plumber'

getPaths = (app) ->
  return [
    path[app].scripts, path[app].styles, path[app].stylus,
    path[app].assets,
    path[app].index, path[app].stylus, path[app].stylusWatch
    path[app].jade, path[app].html    
  ]

gulp.task 'watch_rest', ->
  rmapPaths = getPaths('rmap').concat([path.common])
  adminPaths = getPaths('admin').concat([path.common])

  gulp.watch rmapPaths, gulp.series 'webpack'
  gulp.watch adminPaths, gulp.series 'webpackAdmin'
  gulp.watch path.bower, gulp.series 'vendor'

specCommon = "spec/common/**/*.coffee"
gulp.task 'watch', gulp.series 'watch_rest', ->
  # setTimeout ->
  gulp.watch ['gulp/**/*.coffee',"spec/gulp/**/*.coffee", specCommon], gulp.series 'gulpSpec'
  gulp.watch ['backend/**/*.coffee', 'spec/backend/**/*.coffee', specCommon], gulp.series 'backendSpec'
  gulp.watch ['frontend/**/*.coffee', 'spec/app/**/*.coffee', specCommon], gulp.series 'frontendSpec'
  # , 8000
