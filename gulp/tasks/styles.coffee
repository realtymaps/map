paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()
vinylPaths = require 'vinyl-paths'
del = require 'del'

less = (src) ->
  gulp.src [
    src.less
  ]
  .pipe $.sourcemaps.init()
  .pipe $.less()
  .on   'error', conf.errorHandler 'Less'
  .pipe $.concat 'less.' + src.name + '.css'
  .pipe $.sourcemaps.write()
  .pipe gulp.dest paths.destFull.styles
  .pipe $.size
    title: paths.dest.root
    showFiles: true

css = (src) ->
  gulp.src [
    src.styles
  ]
  .pipe $.sourcemaps.init()
  .pipe $.concat 'css.' + src.name + '.css'
  .pipe $.sourcemaps.write()
  .pipe gulp.dest paths.destFull.styles
  .pipe $.size
    title: paths.dest.root
    showFiles: true

stylus = (src) ->
  gulp.src [
    src.rootStylus
  ]
  .pipe $.sourcemaps.init()
  .pipe $.stylus()
  .on   'error', conf.errorHandler 'Stylus'
  .pipe $.concat 'styl.' + src.name + '.css'
  .pipe $.sourcemaps.write()
  .pipe gulp.dest paths.destFull.styles
  .pipe $.size
    title: paths.dest.root
    showFiles: true

concat = (src) ->
  gulp.src [
    paths.destFull.styles + '/less.' + src.name + '.css'
    paths.destFull.styles + '/css.' + src.name + '.css'
    paths.destFull.styles + '/styl.' + src.name + '.css'
  ]
  .pipe vinylPaths del
  .pipe $.concat src.name + '.css'
  .pipe gulp.dest paths.destFull.styles
  .pipe $.size
    title: paths.dest.root
    showFiles: true

gulp.task 'less', -> less paths.rmap
gulp.task 'css', -> css paths.rmap
gulp.task 'stylus', -> stylus paths.rmap
gulp.task 'styles', gulp.series gulp.parallel('less', 'css', 'stylus'), -> concat paths.rmap

gulp.task 'lessAdmin', -> less paths.admin
gulp.task 'cssAdmin', -> css paths.admin
gulp.task 'stylusAdmin', -> stylus paths.admin
gulp.task 'stylesAdmin', gulp.series gulp.parallel('lessAdmin', 'cssAdmin', 'stylusAdmin'), -> concat paths.admin
