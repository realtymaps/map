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

  gulp.watch rmapPaths, ['webpack']
  gulp.watch adminPaths, ['webpackAdmin']
  gulp.watch path.bower, ['vendor']

specCommon = "spec/common/**/*.coffee"
gulp.task 'watch', gulp.parallel 'watch_rest', ->
  # setTimeout ->
  gulp.watch ['gulp/**/*.coffee',"spec/gulp/**/*.coffee", specCommon], ['gulpSpec']
  gulp.watch ['backend/**/*.coffee', 'spec/backend/**/*.coffee', specCommon],
    ['backendSpec']
  gulp.watch ['frontend/**/*.coffee', 'spec/app/**/*.coffee', specCommon], ['frontendSpec']
  # , 8000
