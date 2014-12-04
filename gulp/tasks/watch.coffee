gulp = require 'gulp'
path = require '../paths'
plumber = require 'gulp-plumber'

gulp.task 'watch_rest', ->
  gulp.watch [
    path.scripts, path.styles, path.stylus,
    path.assets, path.common
    path.index, path.stylus
    path.jade, path.html
  ], ['build']
  gulp.watch ['app/**.*.coffee'], ['build']
  gulp.watch path.bower, ['vendor']

specCommon = "spec/common/**/*.coffee"
gulp.task 'watch', ['watch_rest'], ->
  # setTimeout ->
  gulp.watch ['gulp/**/*.coffee',"spec/gulp/**/*.coffee", specCommon], ['gulpSpec']
  gulp.watch ['backend/**/*.coffee', 'spec/backend/**/*.coffee', specCommon],
    ['backendSpec']
  gulp.watch ['app/**/*.coffee', 'spec/app/**/*.coffee', specCommon], ['frontendSpec']
  # , 8000
