_ = require 'lodash'
gulp = require 'gulp'
paths = require '../../common/config/paths'
plumber = require 'gulp-plumber'

getPaths = (app) ->
  return [
    paths[app].scripts
    paths[app].styles
    paths[app].stylus
    paths[app].assets
    paths[app].stylus
    paths[app].stylusWatch
    paths[app].jade
    paths[app].html
  ]

rmapPaths = getPaths('rmap').concat([paths.common])
adminPaths = getPaths('admin').concat([paths.common])

gulp.task 'watch_vendor', ->
  gulp.watch paths.bower, gulp.series 'vendor'

gulp.task 'watch_front', ->
  gulp.watch rmapPaths, gulp.series 'angular'

gulp.task 'watch_rest', gulp.series 'watch_front', 'watch_vendor', ->
  gulp.watch adminPaths, gulp.series 'angularAdmin'

gulp.task 'build_watch_front', gulp.series "angular", "watch_front"
gulp.task 'bwatch_front', gulp.series 'build_watch_front'

specCommon = "spec/common/**/*.coffee"
gulp.task 'watch', gulp.series 'watch_rest', ->
  gulp.watch ['gulp/**/*.coffee',"spec/gulp/**/*.coffee", specCommon], gulp.series 'gulpSpec'
  gulp.watch ['backend/**/*.coffee', 'spec/backend/**/*.coffee', specCommon], gulp.series 'backendSpec'
  gulp.watch ['frontend/**/*.coffee', 'spec/app/**/*.coffee', 'spec/admin/**/*.coffee', specCommon], gulp.series 'frontendSpec'
