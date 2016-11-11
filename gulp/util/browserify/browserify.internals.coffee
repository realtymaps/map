_ = require 'lodash'
gulp = require 'gulp'
watch = require 'gulp-watch'
gutil = require 'gulp-util'
globby = require 'globby'
$ = require('gulp-load-plugins')()
browserify = require 'browserify'
watchify = require 'watchify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
prettyHrtime = require 'pretty-hrtime'

conf = require '../../tasks/conf'
mainConfig = require '../../../backend/config/config'
logger = require('../../util/logger').spawn('browserify')
shutdown = require '../../../backend/config/shutdown'
paths = require '../../../common/config/paths'
coffeelint = require './coffeelint'

#for reference see http://gulpjs.org/recipes/fast-browserify-builds-with-watchify.html

_gulpify = ({stream, times, outputName, doSourceMaps}) ->
  l = logger.spawn('gulpify')

  # l.debug -> {times, outputName, doSourceMaps}

  # fileCount = 0
  stream
  .once 'error', (err) ->
    l.error err.toString().slice(0,500)
    if err.stack
      l.error err.stack.slice(0,500)
    conf.errorHandler 'Bundler'
  .once 'end', ->
    timestamp = prettyHrtime process.hrtime times.startTime
    l.debug 'Bundled', gutil.colors.bgCyan.black(outputName), 'in', gutil.colors.magenta.black(timestamp)

  #http://stackoverflow.com/questions/32571362/browserify-fails-to-create-bundle-with-babelify-transform-typeerror-path-must
  .pipe source outputName
  .pipe buffer()
  .pipe($.if( do ->
    if doSourceMaps
      l.debug -> 'doing sourcemaps'
    doSourceMaps
  , $.sourcemaps.init {loadMaps: true, largeFile: true}))
  .pipe($.if(doSourceMaps, $.sourcemaps.write()))
  .pipe gulp.dest paths.destFull.scripts


#always return a gulp ready stream
bundle = ({config, entries, inputGlob, bStream, times, outputName, doSourceMaps}) ->
  l = logger.spawn('bundle')
  times.startTime = process.hrtime()
  stream = bStream.bundle()

  _bundle2Gulp = () ->
    l.debug -> 'Bundling ' + gutil.colors.bgCyan.black(config.outputName) + ' ' + entries.length + ' files ...'
    _gulpify({stream, times, outputName, doSourceMaps, entries})

  if entries?
    l.debug -> 'early entries'
    #return a stream so gulp knows when this is done
    return _bundle2Gulp()

  globby(inputGlob)
  .then (newEntries) ->
    l.debug -> 'late entries'
    entries = newEntries
    _bundle2Gulp()

  return #returning null later is ok as gulp is done


createBStream = ({config, lintIgnore, watch, doSourceMaps}) ->
  cssOpts = require('./browserify.css')
  if !doSourceMaps
    cssOpts.debug = false
    cssOpts.minify = true

  browserify config
    .transform(coffeelint({lintIgnore, watch}))
    .on 'error', (error) ->
      logger.error error.stack
      logger.error error
      shutdown.exit(error: true)

    #  NOTE this cannot be in the config above as coffeelint will fail so the order is coffeelint first
    #  this is not needed if the transforms are in the package.json . If in JSON the transforms are ran post
    #  coffeelint.
    .transform('coffeeify', sourceMap: if doSourceMaps then mainConfig.COFFEE_SOURCE_MAP else false)
    .transform('browserify-ngannotate', { "ext": ".coffee" })
    .transform('jadeify')
    # note gulp is currently doing most styles
    .transform('browserify-css', cssOpts)
    .transform('stylusify')
    .transform('brfs')

    # Todo: uglifyify + uglify can be used for additional optimization https://github.com/hughsk/uglifyify
    # .transform({
    #   global: true
    #   ignore: [ ]
    #   output: {beautify: false}
    #   mangle: true
    # }, 'uglifyify')


handleWatch = ({bStream, inputGlob, times, outputName, config, entries, doSourceMaps}) ->
  onUpdate = _.debounce( () ->
    #re-bundle from changes
    bundle({config, inputGlob, bStream, times, outputName, doSourceMaps})
  , 1000)

  #look for new files
  #TODO: I don't believe this is working currently
  watcher = watch inputGlob, conf.chokidarOpts, _.debounce () ->
    # Re-evaluate input pattern so new files are picked up
    globby(inputGlob)
    .then (newEntries) ->
      diff = _.difference newEntries, entries
      if diff.length > 0
        logger.spawn('gulp-watch').debug -> "New files: #{diff}"
        bStream.add diff
        entries = newEntries
        onUpdate()
  , 1000

  # Useful for debugging file watch issues
  # require('../bundleLogger').logEvents(watcher)

  watchify(bStream)

  bStream.on 'update', () ->
    logger.spawn('watchify:update').debug -> 'updated'
    onUpdate()

  gutil.log "Watching #{entries.length} files matching", gutil.colors.bgCyan.black(inputGlob)

module.exports = {
  bundle
  createBStream
  handleWatch
}
