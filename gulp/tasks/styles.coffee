require '../../common/extensions/strings'
paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()
_ = require 'lodash'

_testCb = null

styles = (app) ->
  stylesFn = () ->
    _testCb() if _testCb

    sourcePaths = [
      paths[app].less
      paths[app].styles
      paths[app].rootStylus
    ]

    gulp.src sourcePaths
    .pipe $.sourcemaps.init()

    .pipe lessFilter = $.filter '**/*.less', restore: true
    .pipe $.less()
    .on   'error', conf.errorHandler 'Less'
    .pipe lessFilter.restore

    .pipe stylusFilter = $.filter '**/*.styl', restore: true
    .pipe $.stylus()
    .on   'error', conf.errorHandler 'Stylus'
    .pipe stylusFilter.restore

    .pipe $.order sourcePaths
    .pipe $.concat app + '.css'
    .pipe $.sourcemaps.write()
    .pipe gulp.dest paths.destFull.styles
    .pipe $.size
      title: paths.dest.root
      showFiles: true

  stylesFn.displayName = 'styles'
  stylesFn

stylesWatch = (app) ->

  # Always watch map styles, and possibly app-specific styles
  types = [ 'less', 'styles', 'stylus' ]
  watchPaths = _.union (_.values _.pick paths.map, types), (_.values _.pick paths[app], types)

  # Options passed to gulp's underlying watch lib chokidar
  # See https://github.com/paulmillr/chokidar
  chokidarOpts =
    alwaysStat: true

  # Keeps many files changing at once triggering the task over and over
  stylesFn = _.debounce styles(app), 1000
  # Just for nicer gulp out
  stylesFn.displayName = 'styles'

  console.log watchPaths

  watcher = gulp.watch watchPaths, chokidarOpts, stylesFn

  # Useful for debugging file watch issues
  if verbose = false
    watcher.on 'add', (path) ->
      console.log 'File', path, 'has been added'

    .on 'change', (path) ->
      console.log 'File', path, 'has been changed'

    .on 'unlink', (path) ->
      console.log 'File', path, 'has been removed'

    .on 'addDir', (path) ->
      console.log 'Directory', path, 'has been added'

    .on 'unlinkDir', (path) ->
      console.log 'Directory', path, 'has been removed'

    .on 'error', (error) ->
      console.log 'Error happened', error

    .on 'ready', ->
      console.log 'Initial scan complete. Ready for changes'

    .on 'raw', (event, path, details) ->
      console.log 'Raw event info:', event, path, details

  watcher

###
 TASKS
###
gulp.task 'styles', styles('map')

gulp.task 'stylesWatch', (done) ->
  stylesWatch 'map'
  done()

gulp.task 'stylesAdmin', styles('admin')

gulp.task 'stylesWatchAdmin', (done) ->
  stylesWatch 'admin'
  done()

module.exports =
  ###
  For intent and purposes these exports are for testing only
  ###
  watchImpl: _.partial stylesWatch, 'map'
  watchAdminImpl: _.partial stylesWatch, 'admin'
  setTestCb: (cb) ->
    _testCb = cb
