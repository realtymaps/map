require '../../common/extensions/strings'
logger = (require '../util/logger').spawn('styles')
paths = require '../../common/config/paths'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()
_ = require 'lodash'
rework = require 'gulp-rework'
rework_url = require 'rework-plugin-url'
gutil = require('gulp-util')

_testCb = null

styles = ({app, doSourceMaps, cdn}) ->
  doSourceMaps ?= true

  stylesFn = () ->
    _testCb() if _testCb

    sourcePaths = [
      paths[app].less
      paths[app].styles
      paths[app].rootStylus
    ]

    logger.debug -> sourcePaths

    stream = gulp.src sourcePaths

    if doSourceMaps
      stream = stream.pipe $.sourcemaps.init(largeFile:true)

    stream = stream.pipe lessFilter = $.filter '**/*.less', restore: true
    .pipe $.less()
    .on   'error', conf.errorHandler 'Less'
    .pipe lessFilter.restore

    .pipe stylusFilter = $.filter '**/*.styl', restore: true
    .pipe $.stylus()
    .on   'error', conf.errorHandler 'Stylus'
    .pipe stylusFilter.restore

    .pipe $.order sourcePaths
    .pipe $.concat app + '.css'

    # Running rework even when cdn = false serves as a sanity check for CSS errors
    stream = stream.pipe rework rework_url  (url) ->
      # We only want use CDN urls for these filetypes, and only for paths like "/assets/blah.jpg" NOT "//example.com/blah.jpg"
      if cdn && url.match(/[.](jpg|jpeg|gif|png|svg|ico)([?].*)?(#.*)?$/i) and url.indexOf('/') == 0 && url[1] != '/'
        shard = (url.charCodeAt(url.lastIndexOf('/') + 1) || 0) % 2 # randomization
        r_url = "//prodpull#{shard+1}.realtymapsterllc.netdna-cdn.com#{url}"
        logger.debug "rework_url #{url} -> #{r_url}"
        r_url
      else
        url

    .on 'error', (err) ->
      # Rework likes to dump the ENTIRE CSS FILE if there is an error
      gutil.log gutil.colors.red('[rework]'), err.toString().slice(0,500)
      @emit 'end'

    if doSourceMaps
      stream = stream.pipe $.sourcemaps.write()

    stream.pipe gulp.dest paths.destFull.styles
    .pipe $.size
      title: paths.dest.root
      showFiles: true

  stylesFn.displayName = 'styles'
  stylesFn

stylesWatch = (app) ->

  # Always watch map styles, and possibly app-specific styles
  types = [ 'less', 'styles', 'stylus']
  watchPaths = _.union (_.values _.pick paths.map, types), (_.values _.pick paths[app], types)

  # Keeps many files changing at once triggering the task over and over
  stylesFn = _.debounce styles(app: app), 1000
  # Just for nicer gulp out
  stylesFn.displayName = 'styles'

  # console.log watchPaths

  watcher = gulp.watch watchPaths, conf.chokidarOpts, stylesFn

  # Useful for debugging file watch issues
  # require('../util/bundleLogger').logEvents(watcher)

  watcher

###
 TASKS
###
gulp.task 'styles', styles(app: 'map')

gulp.task 'stylesProd', styles(app: 'map', doSourceMaps: false, cdn: true)

gulp.task 'stylesWatch', (done) ->
  stylesWatch 'map'
  done()

gulp.task 'stylesAdmin', styles(app: 'admin')

gulp.task 'stylesAdminProd', styles(app: 'admin', doSourceMaps: false)

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
