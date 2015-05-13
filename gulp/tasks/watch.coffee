_ = require 'lodash'
gulp = require 'gulp'
path = require '../paths'
plumber = require 'gulp-plumber'

gulp.task 'watch_rest', ->
  # iterate and flatten paths common to both rmap and admin
  apps = ['rmap', 'admin']
  appPaths = _.flatten([
    path[app].scripts, path[app].styles, path[app].stylus,
    path[app].assets,
    path[app].index, path[app].stylus, path[app].stylusWatch
    path[app].jade, path[app].html
  ] for app in apps).concat([path.common])

  gulp.watch appPaths, ['webpack']
  gulp.watch ['app/**.*.coffee'], ['webpack']
  gulp.watch path.bower, ['vendor']

specCommon = "spec/common/**/*.coffee"
gulp.task 'watch', gulp.parallel 'watch_rest', ->
  # setTimeout ->
  gulp.watch ['gulp/**/*.coffee',"spec/gulp/**/*.coffee", specCommon], ['gulpSpec']
  gulp.watch ['backend/**/*.coffee', 'spec/backend/**/*.coffee', specCommon],
    ['backendSpec']
  gulp.watch ['frontend/**/*.coffee', 'spec/app/**/*.coffee', specCommon], ['frontendSpec']
  # , 8000
