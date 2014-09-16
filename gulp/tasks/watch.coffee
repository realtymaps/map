gulp = require 'gulp'
path = require '../paths'

gulp.task 'watch_rest', ->
  gulp.watch [path.scripts,path.styles,path.bower,path.assets,path.common], ['build']
  gulp.watch path.html, ['html']
  gulp.watch path.bower, ['vendor']

gulp.task 'watch', ['watch_rest'], ->
  setTimeout ->
    gulp.watch path.spec, ['spec']
  , 6000
