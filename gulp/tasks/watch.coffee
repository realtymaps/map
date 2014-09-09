gulp = require 'gulp'
path = require '../paths'

gulp.task 'watch_rest', ->
  gulp.watch [path.scripts,path.styles,path.bower,path.assets], ['build']
  gulp.watch path.html, ['html']
  gulp.watch path.bower, ['vendor']

gulp.task 'watch', ['watch_rest'], ->
  gulp.watch path.spec, ['spec']
