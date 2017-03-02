_ = require 'lodash'
watch = require 'gulp-watch'
gutil = require 'gulp-util'
globby = require 'globby'
browserify = require 'browserify'
watchify = require 'watchify'
prettyHrtime = require 'pretty-hrtime'
fs = require 'fs'

conf = require '../../tasks/conf'
mainConfig = require '../../../backend/config/config'
logger = require('../../util/logger').spawn('browserify')
shutdown = require '../../../backend/config/shutdown'
paths = require '../../../common/config/paths'
coffeelint = require './coffeelint'
verifyNgInject = require '../tansform.ng-strict-di'
exorcist = require 'exorcist'
mkdirp = require 'mkdirp'
ifStream = require 'ternary-stream'
split = require 'split'

through = require 'through2'
sourcemapSvc = require '../../../backend/services/service.sourcemap'

#always return a gulp ready stream
bundle = ({config, entries, inputGlob, bStream, times, outputName, prod, doSourceMaps}) ->
  l = logger.spawn('bundle')
  times.startTime = process.hrtime()
  mkdirp.sync(paths.destFull.scripts)
  stream = bStream.bundle()

  jsFile = "#{paths.destFull.scripts}/#{outputName}"
  mapFile = jsFile + '.map'

  l.debug ->
    str = 'Bundling ' + gutil.colors.bgCyan.black(config.outputName)
    if entries?.length
      str += + ' ' + entries.length + ' files ...'
    str

  l.debug -> "jsFile: #{jsFile}"

  if doSourceMaps
    stream = stream.pipe(
      exorcist(mapFile, null, '../src', './'))

  isProd = () ->
    prod

  writeProdSourcemap = () ->
    transform = (chunk, enc, cb) ->
      chunk = String(chunk)
      if /# sourceMappingURL.*/.test(chunk)
        return sourcemapSvc.getGitRev().then (gitRev) =>
          l.debug -> "gitRev: #{gitRev}"
          s3MapFileLocation = sourcemapSvc.getNetworkCachedFile(gitRev)
          s3Loc = "//# sourceMappingURL=#{s3MapFileLocation}.map"
          l.debug -> "s3 location: #{s3Loc}"
          @push(s3Loc)
          cb()

      @push(chunk + '\n')
      cb()

    return through(transform)

  stream
  .once 'error', (err) ->
    l.error err.toString().slice(0,500)
    if err.stack
      l.error err.stack.slice(0,500)
    conf.errorHandler 'Bundler'
  .once 'end', ->
    timestamp = prettyHrtime process.hrtime times.startTime
    l.debug 'Bundled', gutil.colors.bgCyan.black(outputName), 'in', gutil.colors.magenta.black(timestamp)
  .pipe(ifStream(isProd, split()))
  .pipe(ifStream(isProd, writeProdSourcemap()))
  .pipe(fs.createWriteStream(jsFile, 'utf8'))


createBStream = ({config, lintIgnore, watch, prod, doSourceMaps}) ->
  cssOpts = require('./browserify.css')
  if !doSourceMaps
    cssOpts.debug = false
    cssOpts.minify = true

  b = browserify config
  .transform(coffeelint({lintIgnore, watch, prod}))
  .on 'error', (error) ->
    logger.error "@@@@@@@@@@@ Browserify has just exploded. @@@@@@@@@@@@@"
    logger.error error.stack
    logger.error _.omit(error, 'stream')
    #TODO: do we really want to exit?
    shutdown.exit(error: true)

  #  NOTE this cannot be in the config above as coffeelint will fail so the order is coffeelint first
  #  this is not needed if the transforms are in the package.json . If in JSON the transforms are ran post
  #  coffeelint.
  #matches: /\/map\/scripts\/config\/routes\.coffee/) to test specific file only, or check against our source only
  if doSourceMaps
    b.transform(verifyNgInject, skips: [/\/tmp\/map\.templates\.js/, /\/tmp\/admin\.templates\.js/])

    doCoffeeSourceMap = if mainConfig.COFFEE_SOURCE_MAP
      mainConfig.COFFEE_SOURCE_MAP == 'true' || mainConfig.COFFEE_SOURCE_MAP == true
    else
      false

    logger.debug -> "doCoffeeSourceMap: #{doCoffeeSourceMap}"

  b.transform('coffeeify', sourceMap: doCoffeeSourceMap)
  .transform('browserify-ngannotate', { "ext": ".coffee" })
  .transform('jadeify')
  # note gulp is currently doing most styles and the sourcemapping sucks for browserify-css
  #TODO: switch to cssy, supports sourcemaps https://github.com/nodys/cssy
  .transform('browserify-css', cssOpts)
  .transform('stylusify')
  .transform('brfs')


handleWatch = ({bStream, inputGlob, times, outputName, config, entries, doSourceMaps, prod}) ->
  onUpdate = _.debounce( () ->
    #re-bundle from changes
    bundle({config, inputGlob, bStream, times, outputName, doSourceMaps, prod})
  , 1000)

  #look for new files
  watch inputGlob, conf.chokidarOpts, _.debounce () ->
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
